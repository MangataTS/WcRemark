package handler

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type WSHandler struct {
	hub *WSHub
}

func NewWSHandler() *WSHandler {
	hub := &WSHub{
		broadcast:  make(chan WSBroadcast),
		register:   make(chan *WSClient),
		unregister: make(chan *WSClient),
		clients:    make(map[int64]*WSClient),
	}
	go hub.Run()
	return &WSHandler{hub: hub}
}

func (h *WSHandler) HandleWebSocket(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade failed: %v", err)
		return
	}

	client := &WSClient{
		hub:  h.hub,
		conn: conn,
		send: make(chan []byte, 256),
	}

	h.hub.register <- client

	go client.writePump()
	go client.readPump()
}
