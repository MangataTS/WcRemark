package model

import (
	"time"
)

type User struct {
	ID           int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UUID         string    `gorm:"type:uuid;uniqueIndex;default:uuid_generate_v4()" json:"uuid"`
	DeviceID     string    `gorm:"type:varchar(64);uniqueIndex;not null" json:"device_id"`
	Nickname     string    `gorm:"type:varchar(32);not null;default:''" json:"nickname"`
	AvatarURL    string    `gorm:"type:text" json:"avatar_url"`
	Gender       int8      `gorm:"type:smallint;check:gender IN (0,1,2,3)" json:"gender"`
	AgeRange     string    `gorm:"type:varchar(10)" json:"age_range"`
	CityCode     string    `gorm:"type:varchar(10)" json:"city_code"`
	TotalScore   int64     `gorm:"default:0" json:"total_score"`
	SeasonScore  int64     `gorm:"default:0" json:"season_score"`
	HighestRank  string    `gorm:"type:varchar(20);default:'便秘青铜'" json:"highest_rank"`
	CurrentRank  string    `gorm:"type:varchar(20);default:'便秘青铜'" json:"current_rank"`
	IsAnonymous  bool      `gorm:"default:false" json:"is_anonymous"`
	Status       int8      `gorm:"default:1;check:status IN (0,1)" json:"status"`
	CreatedAt    time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt    time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

func (User) TableName() string {
	return "users"
}
