package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

type RedisRepository struct {
	rdb *redis.Client
}

func NewRedisRepository(rdb *redis.Client) *RedisRepository {
	return &RedisRepository{rdb: rdb}
}

func (r *RedisRepository) UpdateGlobalRanking(ctx context.Context, season string, userID int64, score float64) error {
	key := fmt.Sprintf("global:ranking:%s", season)
	return r.rdb.ZIncrBy(ctx, key, score, fmt.Sprintf("%d", userID)).Err()
}

func (r *RedisRepository) UpdateCityRanking(ctx context.Context, cityCode, season string, userID int64, score float64) error {
	key := fmt.Sprintf("city:ranking:%s:%s", cityCode, season)
	return r.rdb.ZIncrBy(ctx, key, score, fmt.Sprintf("%d", userID)).Err()
}

func (r *RedisRepository) UpdateFriendsRanking(ctx context.Context, userID int64, friendIDs []int64, season string) error {
	pipe := r.rdb.Pipeline()
	key := fmt.Sprintf("friends:ranking:%d:%s", userID, season)

	for _, fid := range friendIDs {
		pipe.ZAdd(ctx, key, redis.Z{Score: 0, Member: fmt.Sprintf("%d", fid)})
	}

	_, err := pipe.Exec(ctx)
	return err
}

func (r *RedisRepository) GetGlobalRanking(ctx context.Context, season string, start, stop int64) ([]redis.Z, error) {
	key := fmt.Sprintf("global:ranking:%s", season)
	return r.rdb.ZRevRangeWithScores(ctx, key, start, stop).Result()
}

func (r *RedisRepository) GetCityRanking(ctx context.Context, cityCode, season string, start, stop int64) ([]redis.Z, error) {
	key := fmt.Sprintf("city:ranking:%s:%s", cityCode, season)
	return r.rdb.ZRevRangeWithScores(ctx, key, start, stop).Result()
}

func (r *RedisRepository) GetFriendsRanking(ctx context.Context, userID int64, season string) ([]redis.Z, error) {
	key := fmt.Sprintf("friends:ranking:%d:%s", userID, season)
	return r.rdb.ZRevRangeWithScores(ctx, key, 0, -1).Result()
}

func (r *RedisRepository) GetUserRank(ctx context.Context, season string, userID int64) (int64, error) {
	key := fmt.Sprintf("global:ranking:%s", season)
	return r.rdb.ZRevRank(ctx, key, fmt.Sprintf("%d", userID)).Result()
}

func (r *RedisRepository) GetUserScore(ctx context.Context, season string, userID int64) (float64, error) {
	key := fmt.Sprintf("global:ranking:%s", season)
	return r.rdb.ZScore(ctx, key, fmt.Sprintf("%d", userID)).Result()
}

func (r *RedisRepository) GetTotalPlayers(ctx context.Context, season string) (int64, error) {
	key := fmt.Sprintf("global:ranking:%s", season)
	return r.rdb.ZCard(ctx, key).Result()
}

func (r *RedisRepository) CacheUserScore(ctx context.Context, userID int64, season string, score int64) error {
	key := fmt.Sprintf("user:season_score:%d:%s", userID, season)
	return r.rdb.Set(ctx, key, score, time.Hour).Err()
}

func (r *RedisRepository) GetCachedUserScore(ctx context.Context, userID int64, season string) (int64, error) {
	key := fmt.Sprintf("user:season_score:%d:%s", userID, season)
	return r.rdb.Get(ctx, key).Int64()
}
