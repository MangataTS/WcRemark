package model

import (
	"time"
)

type FriendRelation struct {
	ID        int64     `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID    int64     `gorm:"not null;uniqueIndex:idx_friend_pair" json:"user_id"`
	FriendID  int64     `gorm:"not null;uniqueIndex:idx_friend_pair" json:"friend_id"`
	Status    string    `gorm:"type:varchar(10);default:'pending';check:status IN ('pending','accepted','blocked')" json:"status"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
}

func (FriendRelation) TableName() string {
	return "friend_relations"
}
