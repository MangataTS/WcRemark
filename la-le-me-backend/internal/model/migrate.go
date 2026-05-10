package model

import "gorm.io/gorm"

func AutoMigrate(db *gorm.DB) error {
	db.Exec("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")

	return db.AutoMigrate(
		&User{},
		&ScoreLog{},
		&Season{},
		&FriendRelation{},
		&UserAchievement{},
		&Backup{},
		&APIConfig{},
	)
}
