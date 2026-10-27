package test

import (
	ancymonproto "ancymon/proto"
	gql "ancymon/server/internal/graphql"
	srvgrpc "ancymon/server/internal/grpc"
	"ancymon/server/internal/storage"
	"ancymon/server/internal/watchdog"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
)

func TestEndToEndPipeline(t *testing.T) {
	authToken := "ancymon-e2e-secret-psk"

	// 1. Setup Mock VictoriaMetrics Backend
	var vmLock sync.Mutex
	var ingestedLines []string

	mockVM := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		vmLock.Lock()
		defer vmLock.Unlock()

		if r.URL.Path == "/write" && r.Method == http.MethodPost {
			body, _ := io.ReadAll(r.Body)
			ingestedLines = append(ingestedLines, string(body))
			w.WriteHeader(http.StatusNoContent)
			return
		}

		if strings.HasPrefix(r.URL.Path, "/api/v1/query_range") {
			resp := storage.VMQueryResponse{
				Status: "success",
				Data: storage.VMDataBody{
					ResultType: "matrix",
					Result: []storage.VMSeries{
						{
							Metric: map[string]string{"machine_id": "machine-e2e-01"},
							Values: [][]interface{}{
								{float64(1710000000), "25.0"},
								{float64(1710000015), "26.5"},
							},
						},
					},
				},
			}
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(resp)
			return
		}

		w.WriteHeader(http.StatusNotFound)
	}))
	defer mockVM.Close()

	// 2. Setup Central Server Components
	registry := watchdog.NewRegistry(nil)
	writer := storage.NewWriter(mockVM.URL, 5, 50*time.Millisecond)
	defer writer.Stop()

	querier := storage.NewQuerier(mockVM.URL)

	// gRPC Server setup
	grpcServer := srvgrpc.NewServer(registry, writer, authToken)
	grpcLis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("failed to listen on gRPC port: %v", err)
	}
	defer grpcLis.Close()

	go func() {
		_ = grpcServer.Serve(grpcLis)
	}()
	defer grpcServer.GracefulStop()

	// GraphQL HTTP & WS Server setup
	gqlHandler := gql.NewHandler(registry, querier, authToken)
	gqlServer := httptest.NewServer(gqlHandler)
	defer gqlServer.Close()

	// 3. Connect Mock Agent via gRPC Client
	grpcConn, err := grpc.NewClient(
		grpcLis.Addr().String(),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("failed to connect gRPC client: %v", err)
	}
	defer grpcConn.Close()

	grpcClient := ancymonproto.NewTelemetryServiceClient(grpcConn)

	// Stream telemetry frames with authentication
	authCtx := metadata.NewOutgoingContext(context.Background(), metadata.Pairs("authorization", "Bearer "+authToken))
	stream, err := grpcClient.StreamTelemetry(authCtx)
	if err != nil {
		t.Fatalf("failed to establish gRPC stream: %v", err)
	}

	cpuTemp := 58.0
	for i := 1; i <= 3; i++ {
		frame := &ancymonproto.TelemetryFrame{
			MachineId:     "machine-e2e-01",
			Hostname:      "e2e-workstation",
			TimestampUnix: int64(1710000000 + i),
			Cpu: &ancymonproto.CpuMetrics{
				TotalUsagePercent: 25.0 + float64(i),
				TemperatureC:      &cpuTemp,
			},
			Memory: &ancymonproto.MemoryMetrics{
				TotalBytes:   16 * 1024 * 1024 * 1024,
				UsedBytes:    8 * 1024 * 1024 * 1024,
				UsagePercent: 50.0,
			},
			Network: &ancymonproto.NetworkMetrics{
				RxBytesPerSec: 1048576,
				TxBytesPerSec: 2097152,
			},
			Disks: []*ancymonproto.DiskPartitionMetrics{
				{
					MountPoint:   "/",
					FsType:       "ext4",
					TotalBytes:   500 * 1024 * 1024 * 1024,
					FreeBytes:    250 * 1024 * 1024 * 1024,
					UsagePercent: 50.0,
				},
			},
		}

		if err := stream.Send(frame); err != nil {
			t.Fatalf("failed to send frame %d: %v", i, err)
		}
	}

	ack, err := stream.CloseAndRecv()
	if err != nil {
		t.Fatalf("stream CloseAndRecv failed: %v", err)
	}
	if !ack.Success || ack.AcknowledgedCount != 3 {
		t.Fatalf("expected 3 acknowledged frames with success=true, got %+v", ack)
	}

	// 4. Verify In-Memory Cache
	fleet := registry.GetFleetSummary()
	if len(fleet) != 1 {
		t.Fatalf("expected 1 machine in fleet, got %d", len(fleet))
	}
	if fleet[0].MachineID != "machine-e2e-01" || fleet[0].Status != watchdog.StatusOnline {
		t.Errorf("fleet summary mismatch: %+v", fleet[0])
	}
	if fleet[0].CpuUsagePercent == nil || *fleet[0].CpuUsagePercent != 28.0 {
		t.Errorf("expected latest CPU 28.0, got %v", fleet[0].CpuUsagePercent)
	}

	detail, ok := registry.GetMachineDetail("machine-e2e-01")
	if !ok || detail.Hostname != "e2e-workstation" {
		t.Fatalf("expected detailed machine info, got %+v", detail)
	}

	// 5. Verify VictoriaMetrics Persistence
	// Allow background writer to flush batch
	time.Sleep(150 * time.Millisecond)

	vmLock.Lock()
	if len(ingestedLines) == 0 {
		t.Fatalf("expected VictoriaMetrics to receive line protocol data")
	}
	combinedLines := strings.Join(ingestedLines, "\n")
	if !strings.Contains(combinedLines, "cpu,machine_id=machine-e2e-01") {
		t.Errorf("expected CPU line for machine-e2e-01 in %s", combinedLines)
	}
	if !strings.Contains(combinedLines, "disk,machine_id=machine-e2e-01") {
		t.Errorf("expected Disk line in %s", combinedLines)
	}
	vmLock.Unlock()

	// 6. Verify GraphQL HTTP Query
	queryBody := `{"query":"query { machineHistory(machineId: \"machine-e2e-01\", metric: CPU_USAGE, range: RANGE_1H) { timestamp value } }"}`
	req, _ := http.NewRequest(http.MethodPost, gqlServer.URL+"/graphql", bytes.NewBufferString(queryBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+authToken)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GraphQL query failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected HTTP 200, got %d", resp.StatusCode)
	}

	var gqlResp gql.Response
	if err := json.NewDecoder(resp.Body).Decode(&gqlResp); err != nil {
		t.Fatalf("failed to decode GraphQL response: %v", err)
	}
	if len(gqlResp.Errors) > 0 {
		t.Fatalf("unexpected GraphQL errors: %v", gqlResp.Errors)
	}

	dataMap := gqlResp.Data.(map[string]interface{})
	historyList := dataMap["machineHistory"].([]interface{})
	if len(historyList) != 2 {
		t.Fatalf("expected 2 historical points, got %d", len(historyList))
	}

	// 7. Verify GraphQL WebSocket Subscription
	wsURL := "ws" + strings.TrimPrefix(gqlServer.URL, "http") + "/graphql"
	wsDialer := websocket.Dialer{
		Subprotocols: []string{gql.ProtocolGraphQLTransportWS},
	}
	wsConn, _, err := wsDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("WebSocket connection failed: %v", err)
	}
	defer wsConn.Close()

	// Connection init with auth token
	if err := wsConn.WriteJSON(gql.InboundWSMessage{
		Type: "connection_init",
		Payload: map[string]interface{}{
			"authToken": authToken,
		},
	}); err != nil {
		t.Fatalf("failed to send connection_init: %v", err)
	}

	var wsAck gql.OutboundWSMessage
	if err := wsConn.ReadJSON(&wsAck); err != nil || wsAck.Type != "connection_ack" {
		t.Fatalf("expected connection_ack, got %+v (err: %v)", wsAck, err)
	}

	// Subscribe to fleetSummary
	if err := wsConn.WriteJSON(gql.InboundWSMessage{
		ID:   "sub-fleet",
		Type: "subscribe",
		Payload: map[string]interface{}{
			"query": "subscription { fleetSummary { machineId hostname status } }",
		},
	}); err != nil {
		t.Fatalf("failed to subscribe to fleetSummary: %v", err)
	}

	// Receive snapshot
	var wsSnapshot gql.OutboundWSMessage
	if err := wsConn.ReadJSON(&wsSnapshot); err != nil || wsSnapshot.Type != "next" {
		t.Fatalf("expected next snapshot, got %+v (err: %v)", wsSnapshot, err)
	}

	// Send live telemetry frame through gRPC to verify live subscription push
	liveStream, err := grpcClient.StreamTelemetry(authCtx)
	if err != nil {
		t.Fatalf("failed to open live stream: %v", err)
	}
	_ = liveStream.Send(&ancymonproto.TelemetryFrame{
		MachineId: "machine-e2e-02",
		Hostname:  "live-new-box",
	})
	_ = liveStream.CloseSend()

	// WebSocket must receive updated fleet summary with both machines
	var wsLiveUpdate gql.OutboundWSMessage
	_ = wsConn.SetReadDeadline(time.Now().Add(2 * time.Second))
	if err := wsConn.ReadJSON(&wsLiveUpdate); err != nil {
		t.Fatalf("failed to receive live WebSocket update: %v", err)
	}

	updatePayload := wsLiveUpdate.Payload.(map[string]interface{})
	liveData := updatePayload["data"].(map[string]interface{})
	liveSummaryList := liveData["fleetSummary"].([]interface{})
	if len(liveSummaryList) != 2 {
		t.Errorf("expected 2 machines in live update, got %d", len(liveSummaryList))
	}

	// 8. Verify Mutation: deleteMachine
	delBody := `{"query":"mutation { deleteMachine(machineId: \"machine-e2e-01\") }"}`
	delReq, _ := http.NewRequest(http.MethodPost, gqlServer.URL+"/graphql", bytes.NewBufferString(delBody))
	delReq.Header.Set("Content-Type", "application/json")
	delReq.Header.Set("Authorization", "Bearer "+authToken)

	delResp, err := http.DefaultClient.Do(delReq)
	if err != nil {
		t.Fatalf("deleteMachine mutation request failed: %v", err)
	}
	defer delResp.Body.Close()

	var delGqlResp gql.Response
	_ = json.NewDecoder(delResp.Body).Decode(&delGqlResp)
	delData := delGqlResp.Data.(map[string]interface{})
	if delData["deleteMachine"] != true {
		t.Errorf("expected deleteMachine: true, got %v", delData["deleteMachine"])
	}

	// Verify fleet now has only 1 machine
	if len(registry.GetFleetSummary()) != 1 {
		t.Errorf("expected 1 machine remaining after deletion")
	}

	// 9. Verify Watchdog offline transition
	// Manually age the remaining machine
	registry.CheckHeartbeats(0) // with 0 timeout, marks active hosts offline
	postOfflineFleet := registry.GetFleetSummary()
	if len(postOfflineFleet) > 0 && postOfflineFleet[0].Status != watchdog.StatusOffline {
		t.Errorf("expected machine to transition to OFFLINE, got %s", postOfflineFleet[0].Status)
	}

	fmt.Println("All End-to-End Pipeline verifications PASSED!")
}
