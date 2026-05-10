package errors

import "net/http"

type BusinessError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Data    any    `json:"data,omitempty"`
}

func (e *BusinessError) Error() string {
	return e.Message
}

func NewBusinessError(code int, message string) *BusinessError {
	return &BusinessError{Code: code, Message: message}
}

func NewBusinessErrorWithData(code int, message string, data any) *BusinessError {
	return &BusinessError{Code: code, Message: message, Data: data}
}

var (
	ErrUnknown       = 1
	ErrInvalidParams = 100
	ErrUnauthorized  = 101
	ErrForbidden     = 102
	ErrNotFound      = 103
	ErrRateLimited   = 104
	ErrTokenExpired  = 200
	ErrTokenInvalid  = 201
	ErrUserNotFound  = 300
	ErrNicknameInvalid = 301
	ErrScoreMismatch   = 400
	ErrCheatDetected   = 401
	ErrSeasonEnded     = 402
	ErrDBError         = 500
	ErrRedisError      = 501
	ErrBackupNotFound  = 600
	ErrBackupExpired   = 601
	ErrWSAuthFailed    = 700
)

var ErrorHTTPStatus = map[int]int{
	ErrUnknown:        http.StatusInternalServerError,
	ErrInvalidParams:  http.StatusBadRequest,
	ErrUnauthorized:   http.StatusUnauthorized,
	ErrForbidden:      http.StatusForbidden,
	ErrNotFound:       http.StatusNotFound,
	ErrRateLimited:    http.StatusTooManyRequests,
	ErrTokenExpired:   http.StatusUnauthorized,
	ErrTokenInvalid:   http.StatusUnauthorized,
	ErrUserNotFound:   http.StatusNotFound,
	ErrNicknameInvalid: http.StatusBadRequest,
	ErrScoreMismatch:  http.StatusBadRequest,
	ErrCheatDetected:  http.StatusBadRequest,
	ErrSeasonEnded:    http.StatusBadRequest,
	ErrDBError:        http.StatusInternalServerError,
	ErrRedisError:     http.StatusInternalServerError,
	ErrBackupNotFound: http.StatusNotFound,
	ErrBackupExpired:  http.StatusBadRequest,
	ErrWSAuthFailed:   http.StatusBadRequest,
}
