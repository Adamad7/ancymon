package graphql

import (
	"ancymon/server/internal/watchdog"
	"crypto/subtle"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// Supported GraphQL WebSocket Subprotocols
const (
	ProtocolGraphQLTransportWS = "graphql-transport-ws" // RFC / modern standard
	ProtocolGraphQLWS          = "graphql-ws"           // Apollo legacy
)

// InboundWSMessage models an incoming GraphQL-over-WebSocket framing packet.
type InboundWSMessage struct {
	ID      string                 `json:"id,omitempty"`
	Type    string                 `json:"type"`
	Payload map[string]interface{} `json:"payload,omitempty"`
}

// OutboundWSMessage models an outgoing GraphQL-over-WebSocket framing packet.
type OutboundWSMessage struct {
	ID      string      `json:"id,omitempty"`
	Type    string      `json:"type"`
	Payload interface{} `json:"payload,omitempty"`
}

// WebSocketHandler manages real-time subscriptions over WebSocket.
type WebSocketHandler struct {
	registry  *watchdog.Registry
	resolver  *Resolver
	authToken string
	upgrader  websocket.Upgrader
}

// NewWebSocketHandler creates a new GraphQL WebSocket subscription handler.
func NewWebSocketHandler(reg *watchdog.Registry, res *Resolver, authToken string) *WebSocketHandler {
	return &WebSocketHandler{
		registry:  reg,
		resolver:  res,
		authToken: strings.TrimSpace(authToken),
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all LAN connections
			},
			Subprotocols: []string{ProtocolGraphQLTransportWS, ProtocolGraphQLWS},
		},
	}
}

// ServeHTTP upgrades HTTP requests to WebSockets and coordinates subscription sessions.
func (h *WebSocketHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// If the client sent multiple Sec-WebSocket-Protocol headers, join them with comma
	// so gorilla/websocket's Subprotocols(r) can parse all client requested protocols.
	if protocols := r.Header.Values("Sec-WebSocket-Protocol"); len(protocols) > 1 {
		r.Header.Set("Sec-WebSocket-Protocol", strings.Join(protocols, ", "))
	}

	// Do NOT pass Sec-WebSocket-Protocol in responseHeader; gorilla/websocket handles
	// subprotocol negotiation via upgrader.Subprotocols and writes the header exactly once.
	conn, err := h.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[GraphQL-WS] Upgrade failed: %v", err)
		return
	}
	defer conn.Close()

	subprotocol := conn.Subprotocol()
	if subprotocol == "" {
		subprotocol = h.negotiateSubprotocol(r)
	}

	session := &wsSession{
		conn:          conn,
		subprotocol:   subprotocol,
		handler:       h,
		subscriptions: make(map[string]func()),
	}

	// Pre-validate token if passed in HTTP headers or query param during handshake
	if h.checkAuthHeaders(r) {
		session.authenticated = true
	}

	session.run()
}

func (h *WebSocketHandler) negotiateSubprotocol(r *http.Request) string {
	for _, raw := range r.Header.Values("Sec-WebSocket-Protocol") {
		for _, part := range strings.Split(raw, ",") {
			token := strings.TrimSpace(part)
			if token == ProtocolGraphQLTransportWS {
				return ProtocolGraphQLTransportWS
			}
			if token == ProtocolGraphQLWS {
				return ProtocolGraphQLWS
			}
		}
	}
	return ""
}

func (h *WebSocketHandler) checkAuthHeaders(r *http.Request) bool {
	if h.authToken == "" {
		return true
	}

	// 1. Authorization: Bearer <TOKEN>
	authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
	if strings.HasPrefix(authHeader, "Bearer ") {
		token := strings.TrimSpace(authHeader[7:])
		if subtle.ConstantTimeCompare([]byte(token), []byte(h.authToken)) == 1 {
			return true
		}
	}

	// 2. Query param ?token=<TOKEN>
	queryToken := strings.TrimSpace(r.URL.Query().Get("token"))
	if queryToken != "" && subtle.ConstantTimeCompare([]byte(queryToken), []byte(h.authToken)) == 1 {
		return true
	}

	return false
}

// wsSession encapsulates an active WebSocket connection.
type wsSession struct {
	conn          *websocket.Conn
	subprotocol   string
	handler       *WebSocketHandler
	authenticated bool

	writeMu       sync.Mutex
	subMu         sync.Mutex
	subscriptions map[string]func()
}

func (s *wsSession) safeWriteJSON(v interface{}) error {
	s.writeMu.Lock()
	defer s.writeMu.Unlock()
	_ = s.conn.SetWriteDeadline(time.Now().Add(5 * time.Second))
	return s.conn.WriteJSON(v)
}

func (s *wsSession) run() {
	defer func() {
		s.subMu.Lock()
		for _, unsub := range s.subscriptions {
			unsub()
		}
		s.subscriptions = nil
		s.subMu.Unlock()
	}()

	_ = s.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	s.conn.SetPongHandler(func(string) error {
		_ = s.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		var msg InboundWSMessage
		err := s.conn.ReadJSON(&msg)
		if err != nil {
			break
		}
		_ = s.conn.SetReadDeadline(time.Now().Add(60 * time.Second))

		s.handleMessage(msg)
	}
}

func (s *wsSession) handleMessage(msg InboundWSMessage) {
	switch msg.Type {
	case "connection_init":
		s.handleConnectionInit(msg)

	case "ping":
		_ = s.safeWriteJSON(OutboundWSMessage{Type: "pong"})

	case "subscribe", "start":
		if s.handler.authToken != "" && !s.authenticated {
			_ = s.safeWriteJSON(OutboundWSMessage{
				ID:   msg.ID,
				Type: "error",
				Payload: []GraphQLError{
					{Message: "unauthorized: authentication required"},
				},
			})
			return
		}
		s.handleSubscribe(msg)

	case "complete", "stop":
		s.cancelSubscription(msg.ID)
	}
}

func (s *wsSession) handleConnectionInit(msg InboundWSMessage) {
	if s.handler.authToken != "" && !s.authenticated {
		token := ""
		if msg.Payload != nil {
			if v, ok := msg.Payload["authToken"].(string); ok {
				token = v
			} else if v, ok := msg.Payload["token"].(string); ok {
				token = v
			} else if v, ok := msg.Payload["Authorization"].(string); ok {
				token = strings.TrimPrefix(v, "Bearer ")
			} else if headers, ok := msg.Payload["headers"].(map[string]interface{}); ok {
				if v, ok := headers["Authorization"].(string); ok {
					token = strings.TrimPrefix(v, "Bearer ")
				}
			}
		}

		if subtle.ConstantTimeCompare([]byte(token), []byte(s.handler.authToken)) == 1 {
			s.authenticated = true
		} else {
			_ = s.safeWriteJSON(OutboundWSMessage{
				Type: "connection_error",
				Payload: map[string]string{
					"message": "unauthorized: invalid pre-shared authentication token",
				},
			})
			_ = s.conn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(4401, "Unauthorized"))
			_ = s.conn.Close()
			return
		}
	}

	_ = s.safeWriteJSON(OutboundWSMessage{Type: "connection_ack"})
}

func (s *wsSession) handleSubscribe(msg InboundWSMessage) {
	s.cancelSubscription(msg.ID)

	var query string
	var variables map[string]interface{}

	if msg.Payload != nil {
		if q, ok := msg.Payload["query"].(string); ok {
			query = q
		}
		if vars, ok := msg.Payload["variables"].(map[string]interface{}); ok {
			variables = vars
		}
	}

	subType, machineID, err := ParseSubscription(query, variables)
	if err != nil {
		errType := "error"
		_ = s.safeWriteJSON(OutboundWSMessage{
			ID:   msg.ID,
			Type: errType,
			Payload: []GraphQLError{
				{Message: err.Error()},
			},
		})
		return
	}

	dataMsgType := "next"
	if s.subprotocol == ProtocolGraphQLWS || msg.Type == "start" {
		dataMsgType = "data"
	} else if msg.Type == "subscribe" {
		dataMsgType = "next"
	}

	stopCh := make(chan struct{})
	var unsubBroker func()

	if subType == "fleetSummary" {
		ch, unsub := s.handler.registry.PubSub().SubscribeFleetSummary()
		unsubBroker = unsub

		// Emit initial snapshot immediately
		snapshot := s.handler.registry.GetFleetSummary()
		_ = s.safeWriteJSON(OutboundWSMessage{
			ID:   msg.ID,
			Type: dataMsgType,
			Payload: map[string]interface{}{
				"data": map[string]interface{}{
					"fleetSummary": snapshot,
				},
			},
		})

		go func() {
			defer unsubBroker()
			for {
				select {
				case <-stopCh:
					return
				case update, ok := <-ch:
					if !ok {
						return
					}
					err := s.safeWriteJSON(OutboundWSMessage{
						ID:   msg.ID,
						Type: dataMsgType,
						Payload: map[string]interface{}{
							"data": map[string]interface{}{
								"fleetSummary": update,
							},
						},
					})
					if err != nil {
						return
					}
				}
			}
		}()

	} else if subType == "machineMetrics" {
		ch, unsub := s.handler.registry.PubSub().SubscribeMachineMetrics(machineID)
		unsubBroker = unsub

		// Emit current snapshot immediately if available
		if detail, ok := s.handler.registry.GetMachineDetail(machineID); ok {
			_ = s.safeWriteJSON(OutboundWSMessage{
				ID:   msg.ID,
				Type: dataMsgType,
				Payload: map[string]interface{}{
					"data": map[string]interface{}{
						"machineMetrics": detail,
					},
				},
			})
		}

		go func() {
			defer unsubBroker()
			for {
				select {
				case <-stopCh:
					return
				case detail, ok := <-ch:
					if !ok {
						return
					}
					err := s.safeWriteJSON(OutboundWSMessage{
						ID:   msg.ID,
						Type: dataMsgType,
						Payload: map[string]interface{}{
							"data": map[string]interface{}{
								"machineMetrics": detail,
							},
						},
					})
					if err != nil {
						return
					}
				}
			}
		}()
	}

	s.subMu.Lock()
	if s.subscriptions != nil {
		s.subscriptions[msg.ID] = func() {
			close(stopCh)
		}
	}
	s.subMu.Unlock()
}

func (s *wsSession) cancelSubscription(id string) {
	s.subMu.Lock()
	defer s.subMu.Unlock()
	if s.subscriptions == nil {
		return
	}
	if cancel, exists := s.subscriptions[id]; exists {
		delete(s.subscriptions, id)
		cancel()
	}
}
