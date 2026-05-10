package handler

import (
	"net/http"
	"strconv"

	"la-le-me-backend/internal/repository"
	"la-le-me-backend/internal/service"
	"la-le-me-backend/internal/util"
	"la-le-me-backend/pkg/errors"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService *service.AuthService
}

func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req service.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrInvalidParams, "参数错误: "+err.Error()))
		return
	}

	resp, err := h.authService.Register(c.Request.Context(), req)
	if err != nil {
		if bizErr, ok := err.(*errors.BusinessError); ok {
			util.Error(c, bizErr)
			return
		}
		util.InternalError(c, err.Error())
		return
	}

	util.Created(c, resp)
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req service.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrInvalidParams, "参数错误: "+err.Error()))
		return
	}

	resp, err := h.authService.Login(c.Request.Context(), req)
	if err != nil {
		if bizErr, ok := err.(*errors.BusinessError); ok {
			util.Error(c, bizErr)
			return
		}
		util.InternalError(c, err.Error())
		return
	}

	util.Success(c, resp)
}

func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrInvalidParams, "参数错误"))
		return
	}

	newToken, err := h.authService.RefreshToken(c.Request.Context(), req.RefreshToken)
	if err != nil {
		if bizErr, ok := err.(*errors.BusinessError); ok {
			util.Error(c, bizErr)
			return
		}
		util.InternalError(c, err.Error())
		return
	}

	util.Success(c, gin.H{
		"token":      newToken,
		"expires_in": 900,
	})
}

type UserHandler struct {
	userRepo *repository.UserRepository
}

func NewUserHandler(userRepo *repository.UserRepository) *UserHandler {
	return &UserHandler{userRepo: userRepo}
}

func (h *UserHandler) GetProfile(c *gin.Context) {
	userID, _ := c.Get("userID")

	user, err := h.userRepo.FindByID(c.Request.Context(), userID.(int64))
	if err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrUserNotFound, "用户不存在"))
		return
	}

	util.Success(c, gin.H{
		"uuid":           user.UUID,
		"nickname":       user.Nickname,
		"avatar_url":     user.AvatarURL,
		"gender":         user.Gender,
		"age_range":      user.AgeRange,
		"city_code":      user.CityCode,
		"total_score":    user.TotalScore,
		"season_score":   user.SeasonScore,
		"highest_rank":   user.HighestRank,
		"current_rank":   user.CurrentRank,
		"is_anonymous":   user.IsAnonymous,
		"created_at":     user.CreatedAt,
	})
}

func (h *UserHandler) UpdateProfile(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req struct {
		Nickname    string `json:"nickname"`
		Gender      int8   `json:"gender"`
		AgeRange    string `json:"age_range"`
		CityCode    string `json:"city_code"`
		IsAnonymous *bool  `json:"is_anonymous"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrInvalidParams, "参数错误"))
		return
	}

	updates := map[string]interface{}{}
	if req.Nickname != "" {
		updates["nickname"] = req.Nickname
	}
	if req.Gender != 0 {
		updates["gender"] = req.Gender
	}
	if req.AgeRange != "" {
		updates["age_range"] = req.AgeRange
	}
	if req.CityCode != "" {
		updates["city_code"] = req.CityCode
	}
	if req.IsAnonymous != nil {
		updates["is_anonymous"] = *req.IsAnonymous
	}

	if err := h.userRepo.Update(c.Request.Context(), userID.(int64), updates); err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrDBError, "更新失败"))
		return
	}

	util.Success(c, gin.H{"message": "更新成功"})
}

func (h *UserHandler) DeleteAccount(c *gin.Context) {
	userID, _ := c.Get("userID")

	if err := h.userRepo.Delete(c.Request.Context(), userID.(int64)); err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrDBError, "删除失败"))
		return
	}

	c.JSON(http.StatusOK, gin.H{"code": 0, "data": gin.H{"message": "账号已删除"}})
}

type RecordHandler struct {
	scoreService *service.ScoreService
}

func NewRecordHandler(scoreService *service.ScoreService) *RecordHandler {
	return &RecordHandler{scoreService: scoreService}
}

func (h *RecordHandler) SyncRecord(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req service.ScoreUploadRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrInvalidParams, "参数错误: "+err.Error()))
		return
	}

	result, err := h.scoreService.Settle(c.Request.Context(), userID.(int64), req)
	if err != nil {
		if bizErr, ok := err.(*errors.BusinessError); ok {
			util.Error(c, bizErr)
			return
		}
		util.InternalError(c, err.Error())
		return
	}

	util.Success(c, result)
}

type ScoreHistoryRequest struct {
	Page  int `form:"page"`
	Limit int `form:"limit"`
}

func (h *RecordHandler) GetHistory(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req ScoreHistoryRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		req.Page = 1
		req.Limit = 20
	}

	if req.Page < 1 {
		req.Page = 1
	}
	if req.Limit < 1 || req.Limit > 100 {
		req.Limit = 20
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": gin.H{
			"user_id": userID,
			"page":    req.Page,
			"limit":   req.Limit,
			"items":   []interface{}{},
			"total":   0,
		},
	})
}

type RankingHandler struct {
	rankingService *service.RankingService
}

func NewRankingHandler(rankingService *service.RankingService) *RankingHandler {
	return &RankingHandler{rankingService: rankingService}
}

func (h *RankingHandler) GetGlobalRanking(c *gin.Context) {
	season := c.DefaultQuery("season", service.GetCurrentSeason())
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	userID, _ := c.Get("userID")

	result, err := h.rankingService.GetGlobalRanking(c.Request.Context(), season, page, limit, userID.(int64))
	if err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrRedisError, "获取排行榜失败"))
		return
	}

	util.Success(c, result)
}

func (h *RankingHandler) GetCityRanking(c *gin.Context) {
	cityCode := c.Query("city_code")
	season := c.DefaultQuery("season", service.GetCurrentSeason())
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	userID, _ := c.Get("userID")

	result, err := h.rankingService.GetCityRanking(c.Request.Context(), cityCode, season, page, limit, userID.(int64))
	if err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrInvalidParams, "获取同城排行榜失败"))
		return
	}

	util.Success(c, result)
}

func (h *RankingHandler) GetFriendsRanking(c *gin.Context) {
	season := c.DefaultQuery("season", service.GetCurrentSeason())
	userID, _ := c.Get("userID")

	result, err := h.rankingService.GetFriendsRanking(c.Request.Context(), userID.(int64), season)
	if err != nil {
		util.Error(c, errors.NewBusinessError(errors.ErrRedisError, "获取好友排行榜失败"))
		return
	}

	util.Success(c, result)
}

func (h *RankingHandler) GetFunRanking(c *gin.Context) {
	util.Success(c, gin.H{
		"categories": []gin.H{
			{"id": "efficiency", "name": "⚡ 效率榜", "description": "速战速决"},
			{"id": "paid_pooper", "name": "💼 带薪收益榜", "description": "摸鱼也是生产力"},
			{"id": "morning", "name": "🌅 晨便榜", "description": "早起的人肠道不堵"},
			{"id": "regularity", "name": "📅 规律大师", "description": "生物钟精准如瑞士手表"},
		},
	})
}

type BackupHandler struct {
	backupService *service.BackupService
}

func NewBackupHandler(backupService *service.BackupService) *BackupHandler {
	return &BackupHandler{backupService: backupService}
}

func (h *BackupHandler) ListBackups(c *gin.Context) {
	userID, _ := c.Get("userID")

	backups, err := h.backupService.List(c.Request.Context(), userID.(int64))
	if err != nil {
		util.Error(c, err.(*errors.BusinessError))
		return
	}

	util.Success(c, gin.H{"backups": backups})
}

func (h *BackupHandler) UploadBackup(c *gin.Context) {
	util.Success(c, gin.H{"message": "备份功能开发中"})
}

func (h *BackupHandler) DownloadBackup(c *gin.Context) {
	util.Success(c, gin.H{"message": "下载功能开发中"})
}

func (h *BackupHandler) DeleteBackup(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	userID, _ := c.Get("userID")

	if err := h.backupService.Delete(c.Request.Context(), id, userID.(int64)); err != nil {
		util.Error(c, err.(*errors.BusinessError))
		return
	}

	util.Success(c, gin.H{"message": "删除成功"})
}
