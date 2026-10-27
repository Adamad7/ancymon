package graphql

import (
	ancymonproto "ancymon/proto"
	"ancymon/server/internal/storage"
	"ancymon/server/internal/watchdog"
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

func setupTestServer(t *testing.T, authToken string) (*httptest.Server, *watchdog.Registry, *storage.Writer) {
	// Mock VictoriaMetrics backend
	vmServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasPrefix(r.URL.Path, "/api/v1/query_range") {
			resp := storage.VMQueryResponse{
				Status: "success",
				Data: storage.VMDataBody{
					ResultType: "matrix",
					Result: []storage.VMSeries{
						{
							Metric: map[string]string{"machine_id": "test-box"},
							Values: [][]interface{}{
								{float64(1710000000), "24.5"},
							},
						},
					},
				},
			}
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(resp)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}))
	t.Cleanup(vmServer.Close)

	reg := watchdog.NewRegistry(nil)
	writer := storage.NewWriter(vmServer.URL, 10, 100*time.Millisecond)
	t.Cleanup(writer.Stop)

	querier := storage.NewQuerier(vmServer.URL)
	handler := NewHandler(reg, querier, authToken)

	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)

	return server, reg, writer
}

func TestGraphQLHTTPAuthAndQuery(t *testing.T) {
	authToken := "test-secret-token"
	server, _, _ := setupTestServer(t, authToken)

	queryPayload := `{"query":"query { machineHistory(machineId: \"test-box\", metric: CPU_USAGE, range: RANGE_1H) { timestamp value } }"}`

	// 1. Unauthenticated -> 401 Unauthorized
	req, _ := http.NewRequest(http.MethodPost, server.URL, bytes.NewBufferString(queryPayload))
	req.Header.Set("Content-Type", "application/json")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Errorf("expected 401 Unauthorized, got %d", resp.StatusCode)
	}

	// 2. Authenticated -> 200 OK with data
	req, _ = http.NewRequest(http.MethodPost, server.URL, bytes.NewBufferString(queryPayload))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+authToken)

	resp, err = http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("authenticated request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d", resp.StatusCode)
	}

	var res Response
	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if len(res.Errors) > 0 {
		t.Fatalf("unexpected GraphQL errors: %v", res.Errors)
	}

	dataMap, ok := res.Data.(map[string]interface{})
	if !ok || dataMap["machineHistory"] == nil {
		t.Fatalf("expected machineHistory in response data, got %v", res.Data)
	}
}

func TestGraphQLMutationDeleteMachine(t *testing.T) {
	authToken := "secret"
	server, reg, _ := setupTestServer(t, authToken)

	// Add machine to registry
	reg.RecordTelemetry(&ancymonproto.TelemetryFrame{
		MachineId: "del-target",
		Hostname:  "workstation-1",
	})

	if len(reg.GetFleetSummary()) != 1 {
		t.Fatalf("expected machine in registry")
	}

	mutationPayload := `{"query":"mutation { deleteMachine(machineId: \"del-target\") }"}`
	req, _ := http.NewRequest(http.MethodPost, server.URL, bytes.NewBufferString(mutationPayload))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+authToken)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("mutation request failed: %v", err)
	}
	defer resp.Body.Close()

	var res Response
	_ = json.NewDecoder(resp.Body).Decode(&res)

	dataMap := res.Data.(map[string]interface{})
	if dataMap["deleteMachine"] != true {
		t.Errorf("expected deleteMachine: true, got %v", dataMap["deleteMachine"])
	}

	if len(reg.GetFleetSummary()) != 0 {
		t.Errorf("expected 0 machines after deletion")
	}
}

func TestGraphQLWebSocketSubscriptions(t *testing.T) {
	authToken := "ws-secret"
	server, reg, _ := setupTestServer(t, authToken)

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http")

	dialer := websocket.Dialer{
		Subprotocols: []string{ProtocolGraphQLTransportWS},
	}

	conn, _, err := dialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("WebSocket dial failed: %v", err)
	}
	defer conn.Close()

	// 1. Connection Init with auth
	initMsg := InboundWSMessage{
		Type: "connection_init",
		Payload: map[string]interface{}{
			"authToken": authToken,
		},
	}
	if err := conn.WriteJSON(initMsg); err != nil {
		t.Fatalf("failed to send connection_init: %v", err)
	}

	var ack OutboundWSMessage
	if err := conn.ReadJSON(&ack); err != nil {
		t.Fatalf("failed to read connection_ack: %v", err)
	}
	if ack.Type != "connection_ack" {
		t.Fatalf("expected connection_ack, got %s", ack.Type)
	}

	// 2. Subscribe to fleetSummary
	subMsg := InboundWSMessage{
		ID:   "sub-1",
		Type: "subscribe",
		Payload: map[string]interface{}{
			"query": "subscription { fleetSummary { machineId hostname status } }",
		},
	}
	if err := conn.WriteJSON(subMsg); err != nil {
		t.Fatalf("failed to send subscribe: %v", err)
	}

	// 3. Receive initial snapshot (empty fleet)
	var snap OutboundWSMessage
	if err := conn.ReadJSON(&snap); err != nil {
		t.Fatalf("failed to read initial snapshot: %v", err)
	}
	if snap.ID != "sub-1" || snap.Type != "next" {
		t.Errorf("unexpected snapshot message: %+v", snap)
	}

	// 4. Trigger new telemetry frame -> receive update via WebSocket
	reg.RecordTelemetry(&ancymonproto.TelemetryFrame{
		MachineId: "live-node-99",
		Hostname:  "live-node",
		Cpu:       &ancymonproto.CpuMetrics{TotalUsagePercent: 55.0},
	})

	var update OutboundWSMessage
	_ = conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	if err := conn.ReadJSON(&update); err != nil {
		t.Fatalf("failed to read live update: %v", err)
	}

	if update.ID != "sub-1" || update.Type != "next" {
		t.Errorf("unexpected update message: %+v", update)
	}

	payloadMap, ok := update.Payload.(map[string]interface{})
	if !ok {
		t.Fatalf("invalid update payload structure")
	}
	dataMap, ok := payloadMap["data"].(map[string]interface{})
	if !ok || dataMap["fleetSummary"] == nil {
		t.Fatalf("missing fleetSummary in update data: %v", payloadMap)
	}

	// 5. Unsubscribe (complete)
	completeMsg := InboundWSMessage{
		ID:   "sub-1",
		Type: "complete",
	}
	if err := conn.WriteJSON(completeMsg); err != nil {
		t.Errorf("failed to send complete: %v", err)
	}
}

func TestGraphQLWebSocket_NegotiateSubprotocol(t *testing.T) {
	h := &WebSocketHandler{}

	tests := []struct {
		name     string
		headers  []string
		expected string
	}{
		{
			name:     "empty header returns empty",
			headers:  nil,
			expected: "",
		},
		{
			name:     "direct graphql-transport-ws",
			headers:  []string{"graphql-transport-ws"},
			expected: ProtocolGraphQLTransportWS,
		},
		{
			name:     "direct graphql-ws",
			headers:  []string{"graphql-ws"},
			expected: ProtocolGraphQLWS,
		},
		{
			name:     "comma separated preferred graphql-ws",
			headers:  []string{"graphql-ws, graphql-transport-ws"},
			expected: ProtocolGraphQLWS,
		},
		{
			name:     "comma separated preferred graphql-transport-ws",
			headers:  []string{"graphql-transport-ws, graphql-ws"},
			expected: ProtocolGraphQLTransportWS,
		},
		{
			name:     "multiple headers",
			headers:  []string{"unsupported-subprotocol", "graphql-ws"},
			expected: ProtocolGraphQLWS,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, _ := http.NewRequest(http.MethodGet, "/graphql", nil)
			for _, val := range tt.headers {
				req.Header.Add("Sec-WebSocket-Protocol", val)
			}
			got := h.negotiateSubprotocol(req)
			if got != tt.expected {
				t.Errorf("negotiateSubprotocol() = %q, expected %q", got, tt.expected)
			}
		})
	}
}

func TestGraphQLWebSocket_LegacyAndOmittedSubprotocol(t *testing.T) {
	authToken := "ws-legacy-secret"
	server, reg, _ := setupTestServer(t, authToken)
	wsURL := "ws" + strings.TrimPrefix(server.URL, "http")

	cases := []struct {
		name         string
		subprotocols []string
		startType    string // "start" (legacy Apollo)
		stopType     string // "stop"
		expectedType string // "data"
	}{
		{
			name:         "Apollo graphql-ws with start",
			subprotocols: []string{ProtocolGraphQLWS},
			startType:    "start",
			stopType:     "stop",
			expectedType: "data",
		},
		{
			name:         "Omitted subprotocol with start",
			subprotocols: nil,
			startType:    "start",
			stopType:     "stop",
			expectedType: "data",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			dialer := websocket.Dialer{
				Subprotocols: tc.subprotocols,
			}
			conn, _, err := dialer.Dial(wsURL, nil)
			if err != nil {
				t.Fatalf("WebSocket dial failed: %v", err)
			}
			defer conn.Close()

			// 1. Connection Init
			if err := conn.WriteJSON(InboundWSMessage{
				Type: "connection_init",
				Payload: map[string]interface{}{
					"authToken": authToken,
				},
			}); err != nil {
				t.Fatalf("failed to send connection_init: %v", err)
			}

			var ack OutboundWSMessage
			if err := conn.ReadJSON(&ack); err != nil || ack.Type != "connection_ack" {
				t.Fatalf("expected connection_ack, got %+v (err: %v)", ack, err)
			}

			// 2. Subscribe using 'start'
			subID := "sub-legacy-1"
			if err := conn.WriteJSON(InboundWSMessage{
				ID:   subID,
				Type: tc.startType,
				Payload: map[string]interface{}{
					"query": "subscription { fleetSummary { machineId hostname status } }",
				},
			}); err != nil {
				t.Fatalf("failed to send %s: %v", tc.startType, err)
			}

			// 3. Receive snapshot with expected 'data' type
			var snap OutboundWSMessage
			if err := conn.ReadJSON(&snap); err != nil {
				t.Fatalf("failed to read snapshot: %v", err)
			}
			if snap.ID != subID || snap.Type != tc.expectedType {
				t.Fatalf("expected message type %q, got %q (message: %+v)", tc.expectedType, snap.Type, snap)
			}

			// 4. Trigger live update and verify 'data' type
			reg.RecordTelemetry(&ancymonproto.TelemetryFrame{
				MachineId: "live-legacy-node",
				Hostname:  "legacy-workstation",
			})

			var liveUpdate OutboundWSMessage
			_ = conn.SetReadDeadline(time.Now().Add(2 * time.Second))
			if err := conn.ReadJSON(&liveUpdate); err != nil {
				t.Fatalf("failed to read live update: %v", err)
			}
			if liveUpdate.ID != subID || liveUpdate.Type != tc.expectedType {
				t.Fatalf("expected live update type %q, got %q (message: %+v)", tc.expectedType, liveUpdate.Type, liveUpdate)
			}

			// 5. Unsubscribe using 'stop'
			if err := conn.WriteJSON(InboundWSMessage{
				ID:   subID,
				Type: tc.stopType,
			}); err != nil {
				t.Fatalf("failed to send %s: %v", tc.stopType, err)
			}
		})
	}
}

