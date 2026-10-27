package graphql

import (
	"ancymon/server/internal/storage"
	"ancymon/server/internal/watchdog"
	"crypto/subtle"
	"encoding/json"
	"net/http"
	"strings"
)

// Handler serves HTTP POST/GET requests and upgrades WebSocket connections.
type Handler struct {
	resolver  *Resolver
	wsHandler *WebSocketHandler
	authToken string
}

// NewHandler creates a unified HTTP and WebSocket GraphQL handler.
func NewHandler(reg *watchdog.Registry, querier *storage.Querier, authToken string) *Handler {
	resolver := NewResolver(reg, querier)
	wsHandler := NewWebSocketHandler(reg, resolver, authToken)

	return &Handler{
		resolver:  resolver,
		wsHandler: wsHandler,
		authToken: strings.TrimSpace(authToken),
	}
}

// ServeHTTP handles incoming HTTP requests and WebSocket upgrades.
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Enable CORS for local development and mobile clients
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Sec-WebSocket-Protocol")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	// 1. Detect WebSocket Upgrade
	if strings.ToLower(r.Header.Get("Upgrade")) == "websocket" {
		h.wsHandler.ServeHTTP(w, r)
		return
	}

	// 2. Validate Bearer Token for HTTP Requests
	if !h.authenticate(r) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		_ = json.NewEncoder(w).Encode(Response{
			Data:   nil,
			Errors: []GraphQLError{{Message: "unauthorized: invalid or missing Bearer token"}},
		})
		return
	}

	// 3. Handle GET schema/info
	if r.Method == http.MethodGet {
		q := r.URL.Query().Get("query")
		if q == "" {
			w.Header().Set("Content-Type", "text/plain; charset=utf-8")
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(RawSchemaSDL))
			return
		}
		// Execute query from GET query parameter if provided
		res := h.resolver.Execute(r.Context(), Request{Query: q})
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(res)
		return
	}

	// 4. Handle POST GraphQL requests
	if r.Method == http.MethodPost {
		var req Request
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			_ = json.NewEncoder(w).Encode(Response{
				Data:   nil,
				Errors: []GraphQLError{{Message: "malformed JSON request body"}},
			})
			return
		}

		res := h.resolver.Execute(r.Context(), req)
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(res)
		return
	}

	w.WriteHeader(http.StatusMethodNotAllowed)
}

// authenticate validates the Authorization header against the configured secret PSK.
func (h *Handler) authenticate(r *http.Request) bool {
	if h.authToken == "" {
		return true
	}

	authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
	const prefix = "Bearer "
	if !strings.HasPrefix(authHeader, prefix) {
		return false
	}

	token := strings.TrimSpace(authHeader[len(prefix):])
	return subtle.ConstantTimeCompare([]byte(token), []byte(h.authToken)) == 1
}
