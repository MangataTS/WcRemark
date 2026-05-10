package util

import (
	"net/http"

	"la-le-me-backend/pkg/errors"

	"github.com/gin-gonic/gin"
)

func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": data,
	})
}

func Created(c *gin.Context, data interface{}) {
	c.JSON(http.StatusCreated, gin.H{
		"code": 0,
		"data": data,
	})
}

func Error(c *gin.Context, bizErr *errors.BusinessError) {
	statusCode := errors.ErrorHTTPStatus[bizErr.Code]
	if statusCode == 0 {
		statusCode = http.StatusInternalServerError
	}

	c.JSON(statusCode, gin.H{
		"code":    bizErr.Code,
		"message": bizErr.Message,
		"data":    bizErr.Data,
	})
}

func InternalError(c *gin.Context, message string) {
	c.JSON(http.StatusInternalServerError, gin.H{
		"code":    errors.ErrUnknown,
		"message": message,
	})
}
