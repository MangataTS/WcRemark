package model

import (
	"time"
)

type Season struct {
	ID         int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	SeasonName string    `gorm:"type:varchar(7);uniqueIndex;not null" json:"season_name"`
	StartAt    time.Time `gorm:"not null" json:"start_at"`
	EndAt      time.Time `gorm:"not null" json:"end_at"`
	IsActive   bool      `gorm:"default:true" json:"is_active"`
	CreatedAt  time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (Season) TableName() string {
	return "seasons"
}
