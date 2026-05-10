package middleware

import (
	"net/http"
	"strings"

	"la-le-me-backend/internal/util"
	"la-le-me-backend/pkg/errors"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

func JWTAuth(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    errors.ErrUnauthorized,
				"message": "未认证，请先登录",
			})
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    errors.ErrTokenInvalid,
				"message": "Token 格式无效",
			})
			c.Abort()
			return
		}

		tokenString := parts[1]
		claims := &util.Claims{}

		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(secret), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    errors.ErrTokenExpired,
				"message": "Token 已过期或无效",
			})
			c.Abort()
			return
		}

		c.Set("userID", claims.UserID)
		c.Set("deviceID", claims.DeviceID)
		c.Next()
	}
}
