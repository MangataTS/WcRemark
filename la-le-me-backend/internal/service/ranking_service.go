package service

import (
	"context"
	"fmt"
	"math"
	"strconv"

	"la-le-me-backend/pkg/errors"

	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type RankingService struct {
	rdb *redis.Client
	db  *gorm.DB
}

func NewRankingService(rdb *redis.Client, db *gorm.DB) *RankingService {
	return &RankingService{rdb: rdb, db: db}
}

type RankingItem struct {
	Rank        int     `json:"rank"`
	UserID      int64   `json:"user_id"`
	Nickname    string  `json:"nickname"`
	AvatarURL   string  `json:"avatar_url"`
	Score       float64 `json:"score"`
	RankTitle   string  `json:"rank_title"`
	IsAnonymous bool    `json:"is_anonymous"`
}

type RankingPageResult struct {
	Items      []RankingItem `json:"items"`
	Total      int           `json:"total"`
	Page       int           `json:"page"`
	Limit      int           `json:"limit"`
	TotalPages int           `json:"total_pages"`
	MyRank     *MyRankInfo   `json:"my_rank,omitempty"`
}

type MyRankInfo struct {
	Rank      int     `json:"rank"`
	Score     float64 `json:"score"`
	RankTitle string  `json:"rank_title"`
}

func (s *RankingService) GetGlobalRanking(ctx context.Context, season string, page, limit int, currentUserID int64) (*RankingPageResult, error) {
	key := fmt.Sprintf("global:ranking:%s", season)
	return s.getRankingFromKey(ctx, key, page, limit, currentUserID)
}

func (s *RankingService) GetCityRanking(ctx context.Context, cityCode, season string, page, limit int, currentUserID int64) (*RankingPageResult, error) {
	if cityCode == "" {
		return nil, errors.NewBusinessError(errors.ErrInvalidParams, "city_code 不能为空")
	}
	
	key := fmt.Sprintf("city:ranking:%s:%s", cityCode, season)
	return s.getRankingFromKey(ctx, key, page, limit, currentUserID)
}

func (s *RankingService) GetFriendsRanking(ctx context.Context, userID int64, season string) (*RankingPageResult, error) {
	key := fmt.Sprintf("friends:ranking:%d:%s", userID, season)

	friends, err := s.rdb.ZRevRangeWithScores(ctx, key, 0, -1).Result()
	if err != nil {
		if err == redis.Nil {
			return &RankingPageResult{Items: []RankingItem{}, Total: 0}, nil
		}
		return nil, err
	}

	items := make([]RankingItem, len(friends))
	for i, f := range friends {
		uid, _ := strconv.ParseInt(f.Member.(string), 10, 64)
		items[i] = RankingItem{
			Rank:      i + 1,
			UserID:    uid,
			Nickname:  "",
			Score:     f.Score,
			RankTitle: determineRankTitle(int(f.Score)),
		}
	}

	emailCount := len(friends)
	return &RankingPageResult{
		Items:      items,
		Total:      emailCount,
		Page:       1,
		Limit:      emailCount,
		TotalPages: 1,
	}, nil
}

func (s *RankingService) getRankingFromKey(ctx context.Context, key string, page, limit int, currentUserID int64) (*RankingPageResult, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	start := int64((page - 1) * limit)
	stop := int64(page*limit - 1)

	results, err := s.rdb.ZRevRangeWithScores(ctx, key, start, stop).Result()
	if err != nil {
		return nil, err
	}

	total, _ := s.rdb.ZCard(ctx, key).Result()

	items := make([]RankingItem, len(results))
	for i, r := range results {
		uid, _ := strconv.ParseInt(r.Member.(string), 10, 64)
		items[i] = RankingItem{
			Rank:      (page-1)*limit + i + 1,
			UserID:    uid,
			Score:     r.Score,
			RankTitle: determineRankTitle(int(r.Score)),
		}
	}

	result := &RankingPageResult{
		Items:      items,
		Total:      int(total),
		Page:       page,
		Limit:      limit,
		TotalPages: int(math.Ceil(float64(total) / float64(limit))),
	}

	if currentUserID > 0 {
		rank, err := s.rdb.ZRevRank(ctx, key, fmt.Sprintf("%d", currentUserID)).Result()
		if err == nil {
			score, _ := s.rdb.ZScore(ctx, key, fmt.Sprintf("%d", currentUserID)).Result()
			result.MyRank = &MyRankInfo{
				Rank:      int(rank) + 1,
				Score:     score,
				RankTitle: determineRankTitle(int(score)),
			}
		}
	}

	return result, nil
}
