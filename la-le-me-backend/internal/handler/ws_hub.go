package handler

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512
)

type WSBroadcast struct {
	UserID  int64
	Message []byte
}

type WSMessage struct {
	Type    string      `json:"type"`
	UserID  int64       `json:"user_id,omitempty"`
	Season  string      `json:"season"`
	Payload interface{} `json:"payload"`
}

type WSClient struct {
	hub    *WSHub
	conn   *websocket.Conn
	userID int64
	send   chan []byte
}

type WSHub struct {
	clients    map[int64]*WSClient
	broadcast  chan WSBroadcast
	register   chan *WSClient
	unregister chan *WSClient
	mu         sync.RWMutex
}

func (h *WSHub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client.userID] = client
			h.mu.Unlock()

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client.userID]; ok {
				delete(h.clients, client.userID)
				close(client.send)
			}
			h.mu.Unlock()

		case broadcast := <-h.broadcast:
			h.mu.RLock()
			if client, ok := h.clients[broadcast.UserID]; ok {
				select {
				case client.send <- broadcast.Message:
				default:
					close(client.send)
					delete(h.clients, broadcast.UserID)
				}
			}
			h.mu.RUnlock()
		}
	}
}

func (h *WSHub) BroadcastRankChange(userID int64, season string, newRank int, scoreDelta float64) {
	msg := WSMessage{
		Type:   "rank_update",
		UserID: userID,
		Season: season,
		Payload: map[string]interface{}{
			"new_rank":    newRank,
			"score_delta": scoreDelta,
			"message":     "排名已更新",
		},
	}

	data, _ := json.Marshal(msg)

	h.mu.RLock()
	if client, ok := h.clients[userID]; ok {
		select {
		case client.send <- data:
		default:
			close(client.send)
			delete(h.clients, userID)
		}
	}
	h.mu.RUnlock()
}

func (c *WSClient) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}

		var msg WSMessage
		if err := json.Unmarshal(message, &msg); err != nil {
			continue
		}

		switch msg.Type {
		case "ping":
			pong := WSMessage{Type: "pong", Season: msg.Season}
			data, _ := json.Marshal(pong)
			c.send <- data
		case "auth":
			c.userID = msg.UserID
		}
	}
}

func (c *WSClient) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			n := len(c.send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.send)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
