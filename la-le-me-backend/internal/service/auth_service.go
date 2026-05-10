package service

import (
	"context"
	"regexp"
	"time"

	"la-le-me-backend/internal/config"
	"la-le-me-backend/internal/model"
	"la-le-me-backend/internal/repository"
	"la-le-me-backend/internal/util"
	"la-le-me-backend/pkg/errors"

	"github.com/google/uuid"
)

type AuthService struct {
	cfg      *config.Config
	userRepo *repository.UserRepository
}

func NewAuthService(cfg *config.Config, userRepo *repository.UserRepository) *AuthService {
	return &AuthService{cfg: cfg, userRepo: userRepo}
}

type RegisterRequest struct {
	DeviceID   string `json:"device_id" binding:"required"`
	Nickname   string `json:"nickname"`
	Platform   string `json:"platform"`
	AppVersion string `json:"app_version"`
	PushToken  string `json:"push_token"`
}

type RegisterResponse struct {
	Token        string      `json:"token"`
	RefreshToken string      `json:"refresh_token"`
	ExpiresIn    int         `json:"expires_in"`
	User         userProfile `json:"user"`
}

type userProfile struct {
	UUID         string `json:"uuid"`
	Nickname     string `json:"nickname"`
	CurrentRank  string `json:"current_rank"`
	IsNewUser    bool   `json:"is_new_user"`
}

func (s *AuthService) Register(ctx context.Context, req RegisterRequest) (*RegisterResponse, error) {
	if req.DeviceID == "" {
		return nil, errors.NewBusinessError(errors.ErrInvalidParams, "device_id 不能为空")
	}

	existingUser, err := s.userRepo.FindByDeviceID(ctx, req.DeviceID)
	isNewUser := err != nil

	var user *model.User

	if isNewUser {
		nickname := req.Nickname
		if nickname == "" {
			nickname = generateDefaultNickname()
		} else {
			if !isValidNickname(nickname) {
				return nil, errors.NewBusinessError(errors.ErrNicknameInvalid, "昵称不合法")
			}
		}

		user = &model.User{
			DeviceID:    req.DeviceID,
			Nickname:    nickname,
			CurrentRank: "便秘青铜",
			HighestRank: "便秘青铜",
			Status:      1,
		}

		if err := s.userRepo.Create(ctx, user); err != nil {
			return nil, errors.NewBusinessError(errors.ErrDBError, "创建用户失败")
		}
	} else {
		user = existingUser
	}

	token, err := util.GenerateToken(user.ID, user.DeviceID, s.cfg.JWTSecret, 15*time.Minute)
	if err != nil {
		return nil, errors.NewBusinessError(errors.ErrUnknown, "生成Token失败")
	}

	refreshToken, err := util.GenerateRefreshToken(user.ID, user.DeviceID, s.cfg.JWTSecret)
	if err != nil {
		return nil, errors.NewBusinessError(errors.ErrUnknown, "生成RefreshToken失败")
	}

	return &RegisterResponse{
		Token:        token,
		RefreshToken: refreshToken,
		ExpiresIn:    900,
		User: userProfile{
			UUID:        user.UUID,
			Nickname:    user.Nickname,
			CurrentRank: user.CurrentRank,
			IsNewUser:   isNewUser,
		},
	}, nil
}

func (s *AuthService) Login(ctx context.Context, req RegisterRequest) (*RegisterResponse, error) {
	return s.Register(ctx, req)
}

func (s *AuthService) RefreshToken(ctx context.Context, refreshTokenStr string) (string, error) {
	token, err := util.ParseToken(refreshTokenStr, s.cfg.JWTSecret)
	if err != nil {
		return "", errors.NewBusinessError(errors.ErrTokenInvalid, "RefreshToken 无效")
	}

	claims, ok := token.Claims.(*util.Claims)
	if !ok || !token.Valid {
		return "", errors.NewBusinessError(errors.ErrTokenInvalid, "RefreshToken 无效")
	}

	newToken, err := util.GenerateToken(claims.UserID, claims.DeviceID, s.cfg.JWTSecret, 15*time.Minute)
	if err != nil {
		return "", errors.NewBusinessError(errors.ErrUnknown, "生成Token失败")
	}

	return newToken, nil
}

var nicknameRegex = regexp.MustCompile(`^[\w\u4e00-\u9fa5]{1,32}$`)

func isValidNickname(nickname string) bool {
	return nicknameRegex.MatchString(nickname)
}

func generateDefaultNickname() string {
	id := uuid.New().String()
	shortID := id[0:6]
	return "肠友_" + shortID
}
