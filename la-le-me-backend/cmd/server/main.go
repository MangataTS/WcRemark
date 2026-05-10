package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"la-le-me-backend/internal/config"
	"la-le-me-backend/internal/handler"
	"la-le-me-backend/internal/middleware"
	"la-le-me-backend/internal/model"
	"la-le-me-backend/internal/repository"
	"la-le-me-backend/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func main() {
	cfg := config.Load()

	db := initDB(cfg)
	rdb := initRedis(cfg)

	if err := model.AutoMigrate(db); err != nil {
		log.Fatalf("Failed to run auto migration: %v", err)
	}

	userRepo := repository.NewUserRepository(db)
	scoreRepo := repository.NewScoreRepository(db)
	redisRepo := repository.NewRedisRepository(rdb)

	authService := service.NewAuthService(cfg, userRepo)
	antiCheatService := service.NewAntiCheatService(db, rdb)
	scoreService := service.NewScoreService(db, rdb, antiCheatService, scoreRepo, redisRepo)
	rankingService := service.NewRankingService(rdb, db)
	backupService := service.NewBackupService(db)

	authHandler := handler.NewAuthHandler(authService)
	userHandler := handler.NewUserHandler(userRepo)
	recordHandler := handler.NewRecordHandler(scoreService)
	rankingHandler := handler.NewRankingHandler(rankingService)
	backupHandler := handler.NewBackupHandler(backupService)
	wsHandler := handler.NewWSHandler()

	r := gin.New()
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
	r.Use(middleware.CORS())

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})
	r.GET("/ready", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ready"})
	})

	api := r.Group("/api/v1")
	{
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.RefreshToken)
		}

		protected := api.Group("")
		protected.Use(middleware.JWTAuth(cfg.JWTSecret))

		user := protected.Group("/user")
		{
			user.GET("/profile", userHandler.GetProfile)
			user.PUT("/profile", userHandler.UpdateProfile)
			user.DELETE("/account", userHandler.DeleteAccount)
		}

		records := protected.Group("/records")
		{
			records.POST("/sync", recordHandler.SyncRecord)
			records.GET("/history", recordHandler.GetHistory)
		}

		rankings := protected.Group("/rankings")
		rankings.Use(middleware.RateLimit(rdb, 30, time.Minute))
		{
			rankings.GET("/global", rankingHandler.GetGlobalRanking)
			rankings.GET("/city", rankingHandler.GetCityRanking)
			rankings.GET("/friends", rankingHandler.GetFriendsRanking)
			rankings.GET("/fun", rankingHandler.GetFunRanking)
		}

		backup := protected.Group("/backup")
		{
			backup.GET("/list", backupHandler.ListBackups)
			backup.POST("", backupHandler.UploadBackup)
			backup.GET("/:id/download", backupHandler.DownloadBackup)
			backup.DELETE("/:id", backupHandler.DeleteBackup)
		}
	}

	api.GET("/ws/rankings", wsHandler.HandleWebSocket)

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Port),
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Printf("Server starting on port %s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}

func initDB(cfg *config.Config) *gorm.DB {
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable TimeZone=Asia/Shanghai",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("Failed to get database instance: %v", err)
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	return db
}

func initRedis(cfg *config.Config) *redis.Client {
	rdb := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", cfg.RedisHost, cfg.RedisPort),
		Password: cfg.RedisPassword,
		DB:       0,
	})

	_, err := rdb.Ping(context.Background()).Result()
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}

	return rdb
}
