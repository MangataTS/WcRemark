package model

import (
	"time"
)

type UserAchievement struct {
	ID            int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID        int64     `gorm:"not null;uniqueIndex:idx_user_achievement" json:"user_id"`
	AchievementID string    `gorm:"type:varchar(32);not null;uniqueIndex:idx_user_achievement" json:"achievement_id"`
	UnlockedAt    time.Time `gorm:"autoCreateTime" json:"unlocked_at"`
}

func (UserAchievement) TableName() string {
	return "user_achievements"
}
