package service

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"time"

	"la-le-me-backend/internal/model"
	"la-le-me-backend/internal/repository"
	"la-le-me-backend/pkg/errors"

	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type ScoreService struct {
	db            *gorm.DB
	rdb           *redis.Client
	antiCheat     *AntiCheatService
	scoreRepo     *repository.ScoreRepository
	redisRepo     *repository.RedisRepository
}

func NewScoreService(db *gorm.DB, rdb *redis.Client, antiCheat *AntiCheatService, scoreRepo *repository.ScoreRepository, redisRepo *repository.RedisRepository) *ScoreService {
	return &ScoreService{
		db:        db,
		rdb:       rdb,
		antiCheat: antiCheat,
		scoreRepo: scoreRepo,
		redisRepo: redisRepo,
	}
}

type SettleResult struct {
	Accepted         bool     `json:"accepted"`
	NewSeasonScore   int64    `json:"new_season_score"`
	NewRank          int      `json:"new_rank"`
	RankChange       int      `json:"rank_change"`
	NewAchievements  []string `json:"new_achievements"`
	CheatFlag        string   `json:"cheat_flag"`
	CurrentRankTitle string   `json:"current_rank_title"`
	ScoreBreakdown   map[string]interface{} `json:"score_breakdown"`
}

func (s *ScoreService) Settle(ctx context.Context, userID int64, req ScoreUploadRequest) (*SettleResult, error) {
	cheatResult := s.antiCheat.Check(ctx, userID, req)
	if cheatResult.Flag == CheatFlagInvalid {
		return nil, errors.NewBusinessError(errors.ErrCheatDetected, "记录被判定为无效")
	}

	serverMultiplier := req.Multipliers.R * req.Multipliers.H * req.Multipliers.T *
		req.Multipliers.P * req.Multipliers.S * req.Multipliers.M

	serverCalculated := req.BaseScore * serverMultiplier
	if math.Abs(serverCalculated-req.FinalScore) > req.FinalScore*0.05 {
		return nil, errors.NewBusinessErrorWithData(errors.ErrScoreMismatch, "积分计算不一致", map[string]interface{}{
			"client_calculated": req.FinalScore,
			"server_calculated": serverCalculated,
			"diff_percent":      math.Abs(serverCalculated-req.FinalScore) / req.FinalScore * 100,
		})
	}

	var finalScore float64
	if cheatResult.Flag == CheatFlagSuspicious && cheatResult.Penalty > 0 {
		finalScore = req.FinalScore * cheatResult.Penalty
	} else {
		finalScore = req.FinalScore
	}

	season := GetCurrentSeason()

	achievementJSON, _ := json.Marshal(req.AchievementIDs)
	scoreLog := model.ScoreLog{
		UserID:         userID,
		RecordUUID:     req.RecordUUID,
		Type:           req.Type,
		BaseScore:      req.BaseScore,
		MultiplierR:    req.Multipliers.R,
		MultiplierH:    req.Multipliers.H,
		MultiplierT:    req.Multipliers.T,
		MultiplierP:    req.Multipliers.P,
		MultiplierS:    req.Multipliers.S,
		MultiplierM:    req.Multipliers.M,
		FinalScore:     finalScore,
		AchievementIDs: achievementJSON,
		CheatFlag:      string(cheatResult.Flag),
		LocationHash:   req.LocationHash,
		Season:         season,
	}

	if err := s.scoreRepo.Create(ctx, &scoreLog); err != nil {
		return nil, errors.NewBusinessError(errors.ErrDBError, "写入积分流水失败")
	}

	var user model.User
	if err := s.db.WithContext(ctx).First(&user, userID).Error; err != nil {
		return nil, errors.NewBusinessError(errors.ErrDBError, "获取用户信息失败")
	}

	newTotalScore := user.TotalScore + int64(finalScore)
	newSeasonScore := user.SeasonScore + int64(finalScore)
	newRankTitle := determineRankTitle(int(newSeasonScore))

	oldRank, _ := s.redisRepo.GetUserRank(ctx, season, userID)

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		updates := map[string]interface{}{
			"total_score":  newTotalScore,
			"season_score": newSeasonScore,
			"current_rank": newRankTitle,
			"updated_at":   time.Now(),
		}

		if rankLevel(newRankTitle) > rankLevel(user.HighestRank) {
			updates["highest_rank"] = newRankTitle
		}

		return tx.Model(&user).Updates(updates).Error
	})

	if err != nil {
		return nil, errors.NewBusinessError(errors.ErrDBError, "更新用户积分失败")
	}

	if err := s.redisRepo.UpdateGlobalRanking(ctx, season, userID, finalScore); err != nil {
		log.Printf("Redis global ranking update failed: %v", err)
	}

	if user.CityCode != "" {
		if err := s.redisRepo.UpdateCityRanking(ctx, user.CityCode, season, userID, finalScore); err != nil {
			log.Printf("Redis city ranking update failed: %v", err)
		}
	}

	if err := s.redisRepo.CacheUserScore(ctx, userID, season, newSeasonScore); err != nil {
		log.Printf("Redis cache user score failed: %v", err)
	}

	newRank, _ := s.redisRepo.GetUserRank(ctx, season, userID)

	rankChange := 0
	if oldRank >= 0 {
		rankChange = int(oldRank) - int(newRank)
	}

	newAchievements := checkNewAchievements(userID, req.AchievementIDs)

	return &SettleResult{
		Accepted:         true,
		NewSeasonScore:   newSeasonScore,
		NewRank:          int(newRank) + 1,
		RankChange:       rankChange,
		NewAchievements:  newAchievements,
		CheatFlag:        string(cheatResult.Flag),
		CurrentRankTitle: newRankTitle,
		ScoreBreakdown: map[string]interface{}{
			"base":             req.BaseScore,
			"regularity_bonus": req.Multipliers.R * req.BaseScore - req.BaseScore,
			"health_bonus":     req.Multipliers.H * req.BaseScore - req.BaseScore,
			"total":            finalScore,
		},
	}, nil
}

func GetCurrentSeason() string {
	now := time.Now()
	return fmt.Sprintf("%d-%02d", now.Year(), now.Month())
}

func determineRankTitle(score int) string {
	switch {
	case score >= 20000:
		return "最强王者"
	case score >= 10000:
		return "星耀肠道长"
	case score >= 5000:
		return "钻石所长"
	case score >= 2000:
		return "铂金肠王"
	case score >= 500:
		return "规律黄金"
	case score >= 100:
		return "通畅白银"
	default:
		return "便秘青铜"
	}
}

func rankLevel(title string) int {
	levels := map[string]int{
		"便秘青铜": 1,
		"通畅白银": 2,
		"规律黄金": 3,
		"铂金肠王": 4,
		"钻石所长": 5,
		"星耀肠道长": 6,
		"最强王者": 7,
	}
	return levels[title]
}

func checkNewAchievements(userID int64, achievementIDs []string) []string {
	return achievementIDs
}
