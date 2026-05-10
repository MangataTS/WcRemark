package service

import (
	"context"
	"time"

	"la-le-me-backend/internal/model"
	"la-le-me-backend/pkg/errors"

	"gorm.io/gorm"
)

type BackupService struct {
	db *gorm.DB
}

func NewBackupService(db *gorm.DB) *BackupService {
	return &BackupService{db: db}
}

type BackupInfo struct {
	ID        int64     `json:"id"`
	FileSize  int64     `json:"file_size"`
	Checksum  string    `json:"checksum"`
	CreatedAt time.Time `json:"created_at"`
	ExpiresAt time.Time `json:"expires_at"`
}

func (s *BackupService) List(ctx context.Context, userID int64) ([]BackupInfo, error) {
	var backups []model.Backup
	err := s.db.WithContext(ctx).
		Where("user_id = ? AND expires_at > ?", userID, time.Now()).
		Order("created_at DESC").
		Find(&backups).Error
	if err != nil {
		return nil, errors.NewBusinessError(errors.ErrDBError, "获取备份列表失败")
	}

	info := make([]BackupInfo, len(backups))
	for i, b := range backups {
		info[i] = BackupInfo{
			ID:        b.ID,
			FileSize:  b.FileSize,
			Checksum:  b.Checksum,
			CreatedAt: b.CreatedAt,
			ExpiresAt: b.ExpiresAt,
		}
	}

	return info, nil
}

func (s *BackupService) Create(ctx context.Context, userID int64, fileKey string, fileSize int64, checksum string) (*model.Backup, error) {
	backup := model.Backup{
		UserID:    userID,
		FileKey:   fileKey,
		FileSize:  fileSize,
		Checksum:  checksum,
		ExpiresAt: time.Now().Add(30 * 24 * time.Hour),
	}

	if err := s.db.WithContext(ctx).Create(&backup).Error; err != nil {
		return nil, errors.NewBusinessError(errors.ErrDBError, "创建备份记录失败")
	}

	return &backup, nil
}

func (s *BackupService) GetByID(ctx context.Context, id int64, userID int64) (*model.Backup, error) {
	var backup model.Backup
	err := s.db.WithContext(ctx).Where("id = ? AND user_id = ?", id, userID).First(&backup).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, errors.NewBusinessError(errors.ErrBackupNotFound, "备份不存在")
		}
		return nil, err
	}

	if time.Now().After(backup.ExpiresAt) {
		return nil, errors.NewBusinessError(errors.ErrBackupExpired, "备份已过期")
	}

	return &backup, nil
}

func (s *BackupService) Delete(ctx context.Context, id int64, userID int64) error {
	result := s.db.WithContext(ctx).Where("id = ? AND user_id = ?", id, userID).Delete(&model.Backup{})
	if result.RowsAffected == 0 {
		return errors.NewBusinessError(errors.ErrBackupNotFound, "备份不存在")
	}
	return result.Error
}
