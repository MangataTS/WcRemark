package repository

import (
	"context"

	"la-le-me-backend/internal/model"

	"gorm.io/gorm"
)

type ScoreRepository struct {
	db *gorm.DB
}

func NewScoreRepository(db *gorm.DB) *ScoreRepository {
	return &ScoreRepository{db: db}
}

func (r *ScoreRepository) Create(ctx context.Context, log *model.ScoreLog) error {
	return r.db.WithContext(ctx).Create(log).Error
}

func (r *ScoreRepository) FindByRecordUUID(ctx context.Context, recordUUID string) (*model.ScoreLog, error) {
	var log model.ScoreLog
	err := r.db.WithContext(ctx).Where("record_uuid = ?", recordUUID).First(&log).Error
	if err != nil {
		return nil, err
	}
	return &log, nil
}

func (r *ScoreRepository) FindByUserID(ctx context.Context, userID int64, limit, offset int) ([]model.ScoreLog, int64, error) {
	var logs []model.ScoreLog
	var total int64

	db := r.db.WithContext(ctx).Where("user_id = ?", userID)

	if err := db.Model(&model.ScoreLog{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if err := db.Order("created_at DESC").Limit(limit).Offset(offset).Find(&logs).Error; err != nil {
		return nil, 0, err
	}

	return logs, total, nil
}

func (r *ScoreRepository) FindBySeason(ctx context.Context, season string, userID int64) ([]model.ScoreLog, error) {
	var logs []model.ScoreLog
	err := r.db.WithContext(ctx).
		Where("season = ? AND user_id = ?", season, userID).
		Order("created_at DESC").
		Find(&logs).Error
	return logs, err
}

func (r *ScoreRepository) GetSeasonStats(ctx context.Context, userID int64, season string) (float64, int64, error) {
	var result struct {
		Total float64
		Count int64
	}
	err := r.db.WithContext(ctx).Model(&model.ScoreLog{}).
		Select("COALESCE(SUM(final_score), 0) as total, COUNT(*) as count").
		Where("user_id = ? AND season = ? AND cheat_flag = 'OK'", userID, season).
		Scan(&result).Error
	return result.Total, result.Count, err
}
