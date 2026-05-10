package middleware

import (
	"fmt"
	"net/http"
	"time"

	"la-le-me-backend/pkg/errors"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

func RateLimit(rdb *redis.Client, maxRequests int, window time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		uid, exists := c.Get("userID")
		if !exists {
			c.Next()
			return
		}

		key := fmt.Sprintf("rate_limit:%s:%v:%s", c.Request.URL.Path, uid, c.ClientIP())
		ctx := c.Request.Context()

		count, err := rdb.Incr(ctx, key).Result()
		if err != nil {
			c.Next()
			return
		}

		if count == 1 {
			rdb.Expire(ctx, key, window)
		}

		if count > int64(maxRequests) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"code":    errors.ErrRateLimited,
				"message": "请求过于频繁，请稍后再试",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
