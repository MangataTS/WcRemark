package repository

import (
	"context"

	"la-le-me-backend/internal/model"

	"gorm.io/gorm"
)

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) FindByDeviceID(ctx context.Context, deviceID string) (*model.User, error) {
	var user model.User
	err := r.db.WithContext(ctx).Where("device_id = ?", deviceID).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) FindByID(ctx context.Context, id int64) (*model.User, error) {
	var user model.User
	err := r.db.WithContext(ctx).First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) Create(ctx context.Context, user *model.User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

func (r *UserRepository) Update(ctx context.Context, id int64, updates map[string]interface{}) error {
	return r.db.WithContext(ctx).Model(&model.User{}).Where("id = ?", id).Updates(updates).Error
}

func (r *UserRepository) Delete(ctx context.Context, id int64) error {
	return r.db.WithContext(ctx).Delete(&model.User{}, id).Error
}

func (r *UserRepository) FindFriends(ctx context.Context, userID int64) ([]model.FriendRelation, error) {
	var relations []model.FriendRelation
	err := r.db.WithContext(ctx).
		Where("(user_id = ? OR friend_id = ?) AND status = ?", userID, userID, "accepted").
		Find(&relations).Error
	return relations, err
}

func (r *UserRepository) AddFriend(ctx context.Context, userID, friendID int64) error {
	relation := model.FriendRelation{
		UserID:   userID,
		FriendID: friendID,
		Status:   "pending",
	}
	return r.db.WithContext(ctx).Create(&relation).Error
}

func (r *UserRepository) AcceptFriend(ctx context.Context, userID, friendID int64) error {
	return r.db.WithContext(ctx).Model(&model.FriendRelation{}).
		Where("user_id = ? AND friend_id = ?", friendID, userID).
		Update("status", "accepted").Error
}
