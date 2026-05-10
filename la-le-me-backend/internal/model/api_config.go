package model

import (
	"time"
)

type APIConfig struct {
	ID          int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID      int64     `gorm:"uniqueIndex;not null" json:"user_id"`
	Provider    string    `gorm:"type:varchar(32)" json:"provider"`
	BaseURL     string    `gorm:"type:text" json:"base_url"`
	ModelName   string    `gorm:"type:varchar(64)" json:"model_name"`
	Temperature float64   `gorm:"type:decimal(3,2);default:0.3" json:"temperature"`
	IsEnabled   bool      `gorm:"default:false" json:"is_enabled"`
	UpdatedAt   time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

func (APIConfig) TableName() string {
	return "api_configs"
}
