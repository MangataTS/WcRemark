package model

import (
	"time"
)

type Backup struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID    int64     `gorm:"not null;index" json:"user_id"`
	FileKey   string    `gorm:"type:varchar(128);not null" json:"file_key"`
	FileSize  int64     `gorm:"type:bigint" json:"file_size"`
	Checksum  string    `gorm:"type:varchar(64);not null" json:"checksum"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	ExpiresAt time.Time `json:"expires_at"`
}

func (Backup) TableName() string {
	return "backups"
}
