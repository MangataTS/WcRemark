package service

import (
	"context"
	"fmt"
	"log"
	"math"
	"time"

	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type CheatFlag string

const (
	CheatFlagOK         CheatFlag = "OK"
	CheatFlagSuspicious CheatFlag = "SUSPICIOUS"
	CheatFlagCheat      CheatFlag = "CHEAT"
	CheatFlagInvalid    CheatFlag = "INVALID"
)

type CheatCheckResult struct {
	Flag    CheatFlag
	Action  string
	Reason  string
	Penalty float64
}

type AntiCheatService struct {
	db  *gorm.DB
	rdb *redis.Client
}

func NewAntiCheatService(db *gorm.DB, rdb *redis.Client) *AntiCheatService {
	return &AntiCheatService{db: db, rdb: rdb}
}

type ScoreUploadRequest struct {
	RecordUUID     string      `json:"record_uuid"`
	Type           string      `json:"type"`
	Timestamp      int64       `json:"timestamp"`
	Duration       int         `json:"duration"`
	IsWorkHours    bool        `json:"is_work_hours"`
	IsPaidPoop     bool        `json:"is_paid_poop"`
	BristolType    *int        `json:"bristol_type"`
	BaseScore      float64     `json:"base_score"`
	Multipliers    Multipliers `json:"multipliers"`
	FinalScore     float64     `json:"final_score"`
	AchievementIDs []string    `json:"achievement_ids"`
	LocationHash   string      `json:"location_hash"`
}

type Multipliers struct {
	R float64 `json:"r"`
	H float64 `json:"h"`
	T float64 `json:"t"`
	P float64 `json:"p"`
	S float64 `json:"s"`
	M float64 `json:"m"`
}

func (s *AntiCheatService) Check(ctx context.Context, userID int64, req ScoreUploadRequest) *CheatCheckResult {
	if result := s.checkMultiplierBounds(req); result != nil {
		return result
	}

	if result := s.checkScoreAgreement(req); result != nil {
		return result
	}

	if result := s.checkTimeRange(req); result != nil {
		return result
	}

	if result := s.checkUploadRate(ctx, userID); result != nil {
		return result
	}

	if result := s.checkHourlyGrowth(ctx, userID, req.FinalScore); result != nil {
		return result
	}

	return &CheatCheckResult{Flag: CheatFlagOK}
}

func (s *AntiCheatService) checkMultiplierBounds(req ScoreUploadRequest) *CheatCheckResult {
	if req.Multipliers.R < 0.8 || req.Multipliers.R > 1.5 {
		return &CheatCheckResult{Flag: CheatFlagCheat, Reason: "R乘数超出范围"}
	}
	if req.Multipliers.H < 0.5 || req.Multipliers.H > 1.2 {
		return &CheatCheckResult{Flag: CheatFlagCheat, Reason: "H乘数超出范围"}
	}
	if req.Multipliers.T < 0.7 || req.Multipliers.T > 1.1 {
		return &CheatCheckResult{Flag: CheatFlagCheat, Reason: "T乘数超出范围"}
	}
	if req.Multipliers.P < 1.0 || req.Multipliers.P > 1.2 {
		return &CheatCheckResult{Flag: CheatFlagCheat, Reason: "P乘数超出范围"}
	}
	if req.Multipliers.S < 1.0 || req.Multipliers.S > 2.0 {
		return &CheatCheckResult{Flag: CheatFlagCheat, Reason: "S乘数超出范围"}
	}
	if req.Multipliers.M < 1.0 || req.Multipliers.M > 1.15 {
		return &CheatCheckResult{Flag: CheatFlagCheat, Reason: "M乘数超出范围"}
	}

	maxReasonable := 1.5 * 1.2 * 1.1 * 1.2 * 2.0 * 1.15
	totalMultiplier := req.Multipliers.R * req.Multipliers.H * req.Multipliers.T *
		req.Multipliers.P * req.Multipliers.S * req.Multipliers.M

	if totalMultiplier > maxReasonable*1.1 {
		return &CheatCheckResult{
			Flag:    CheatFlagCheat,
			Reason:  fmt.Sprintf("乘数异常（%.2f > 理论最大值%.2f）", totalMultiplier, maxReasonable),
		}
	}

	return nil
}

func (s *AntiCheatService) checkScoreAgreement(req ScoreUploadRequest) *CheatCheckResult {
	totalMultiplier := req.Multipliers.R * req.Multipliers.H * req.Multipliers.T *
		req.Multipliers.P * req.Multipliers.S * req.Multipliers.M

	serverCalculated := req.BaseScore * totalMultiplier

	if math.Abs(serverCalculated-req.FinalScore) > req.FinalScore*0.05 {
		return &CheatCheckResult{
			Flag:   CheatFlagSuspicious,
			Reason: fmt.Sprintf("积分计算不一致（客户端:%.2f 服务端:%.2f）", req.FinalScore, serverCalculated),
		}
	}

	return nil
}

func (s *AntiCheatService) checkTimeRange(req ScoreUploadRequest) *CheatCheckResult {
	if req.Duration > 3600 {
		return &CheatCheckResult{
			Flag:   CheatFlagInvalid,
			Reason: "单次时长超过1小时",
		}
	}

	if req.Type == "big" && req.Duration < 10 {
		return &CheatCheckResult{
			Flag:    CheatFlagSuspicious,
			Reason:  "大号时长过短",
			Penalty: 0.5,
		}
	}

	return nil
}

func (s *AntiCheatService) checkUploadRate(ctx context.Context, userID int64) *CheatCheckResult {
	key := fmt.Sprintf("rate_limit:score_upload:%d", userID)

	count, err := s.rdb.Incr(ctx, key).Result()
	if err != nil {
		log.Printf("Redis rate limit check failed: %v", err)
		return nil
	}

	if count == 1 {
		s.rdb.Expire(ctx, key, 5*time.Minute)
	}

	if count > 15 {
		return &CheatCheckResult{
			Flag:   CheatFlagSuspicious,
			Reason: fmt.Sprintf("5分钟内上报次数异常（%d次）", count),
		}
	}

	return nil
}

func (s *AntiCheatService) checkHourlyGrowth(ctx context.Context, userID int64, newScore float64) *CheatCheckResult {
	key := fmt.Sprintf("score:growth:%d:%d", userID, time.Now().Hour())
	
	pipe := s.rdb.Pipeline()
	incrCmd := pipe.IncrByFloat(ctx, key, newScore)
	pipe.Expire(ctx, key, time.Hour)
	_, err := pipe.Exec(ctx)
	if err != nil {
		log.Printf("Redis growth check failed: %v", err)
		return nil
	}

	hourlyGrowth, _ := incrCmd.Result()
	if hourlyGrowth > 50 {
		return &CheatCheckResult{
			Flag:   CheatFlagSuspicious,
			Reason: fmt.Sprintf("积分增长过快（1小时+%.2f分）", hourlyGrowth),
		}
	}

	return nil
}
