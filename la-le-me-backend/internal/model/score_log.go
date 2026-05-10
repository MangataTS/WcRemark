package model

import (
	"encoding/json"
	"time"

	"gorm.io/gorm"
)

type ScoreLog struct {
	ID             int64          `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID         int64          `gorm:"not null;index" json:"user_id"`
	RecordUUID     string         `gorm:"type:uuid;not null;index" json:"record_uuid"`
	Type           string         `gorm:"type:varchar(10);check:type IN ('small','big')" json:"type"`
	BaseScore      float64        `gorm:"type:decimal(5,2);not null" json:"base_score"`
	MultiplierR    float64        `gorm:"type:decimal(3,2);default:1.0" json:"multiplier_r"`
	MultiplierH    float64        `gorm:"type:decimal(3,2);default:1.0" json:"multiplier_h"`
	MultiplierT    float64        `gorm:"type:decimal(3,2);default:1.0" json:"multiplier_t"`
	MultiplierP    float64        `gorm:"type:decimal(3,2);default:1.0" json:"multiplier_p"`
	MultiplierS    float64        `gorm:"type:decimal(3,2);default:1.0" json:"multiplier_s"`
	MultiplierM    float64        `gorm:"type:decimal(3,2);default:1.0" json:"multiplier_m"`
	FinalScore     float64        `gorm:"type:decimal(5,2);not null" json:"final_score"`
	AchievementIDs json.RawMessage `gorm:"type:jsonb;default:'[]'" json:"achievement_ids"`
	CheatFlag      string         `gorm:"type:varchar(20);default:'OK';check:cheat_flag IN ('OK','SUSPICIOUS','CHEAT','INVALID')" json:"cheat_flag"`
	LocationHash   string         `gorm:"type:varchar(64)" json:"location_hash"`
	CreatedAt      time.Time      `gorm:"autoCreateTime" json:"created_at"`
	Season         string         `gorm:"type:varchar(7);not null;index" json:"season"`
}

func (ScoreLog) TableName() string {
	return "score_logs"
}

func (s *ScoreLog) BeforeCreate(tx *gorm.DB) error {
	if s.Season == "" {
		return nil
	}
	return nil
}
