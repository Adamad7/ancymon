package storage

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

// MetricType enum values matching schema.graphql
const (
	MetricCPUUsage    = "CPU_USAGE"
	MetricCPUTemp     = "CPU_TEMP"
	MetricMemoryUsage = "MEMORY_USAGE"
	MetricNetworkRx   = "NETWORK_RX"
	MetricNetworkTx   = "NETWORK_TX"
	MetricDiskUsage   = "DISK_USAGE"
)

// TimeRange enum values matching schema.graphql
const (
	Range1H        = "RANGE_1H"
	Range6H        = "RANGE_6H"
	Range12H       = "RANGE_12H"
	Range24H       = "RANGE_24H"
	Range3D        = "RANGE_3D"
	Range7D        = "RANGE_7D"
	RangeCustomDate = "CUSTOM_DATE"
)

// Querier handles analytical MetricsQL queries against VictoriaMetrics.
type Querier struct {
	vmURL      string
	httpClient *http.Client
}

// NewQuerier creates a new VictoriaMetrics query runner.
func NewQuerier(vmURL string) *Querier {
	return &Querier{
		vmURL: strings.TrimRight(vmURL, "/"),
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// QueryHistory retrieves downsampled historical metric points for a workstation.
func (q *Querier) QueryHistory(ctx context.Context, machineID, metric, timeRange, dateStr string) ([]HistoricalPoint, error) {
	if machineID == "" {
		return nil, fmt.Errorf("machineId cannot be empty")
	}

	start, end, step, err := CalculateTimeWindow(timeRange, dateStr, time.Now())
	if err != nil {
		return nil, fmt.Errorf("failed to calculate time window: %w", err)
	}

	expr, err := BuildMetricsQLExpr(machineID, metric)
	if err != nil {
		return nil, fmt.Errorf("failed to build query expression: %w", err)
	}

	queryURL := fmt.Sprintf("%s/api/v1/query_range?query=%s&start=%d&end=%d&step=%s",
		q.vmURL,
		url.QueryEscape(expr),
		start,
		end,
		step,
	)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, queryURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to build query request: %w", err)
	}

	resp, err := q.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("HTTP request to VictoriaMetrics failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("VictoriaMetrics returned HTTP %d: %s", resp.StatusCode, string(body))
	}

	var vmResp VMQueryResponse
	if err := json.NewDecoder(resp.Body).Decode(&vmResp); err != nil {
		return nil, fmt.Errorf("failed to parse VictoriaMetrics JSON response: %w", err)
	}

	if vmResp.Status != "success" {
		return nil, fmt.Errorf("VictoriaMetrics query error: %s", vmResp.Error)
	}

	return ParseVMPoints(vmResp), nil
}

// BuildMetricsQLExpr maps a GraphQL MetricType and machine_id into a MetricsQL expression.
func BuildMetricsQLExpr(machineID, metric string) (string, error) {
	safeMachID := strings.ReplaceAll(machineID, `"`, `\"`)

	switch metric {
	case MetricCPUUsage:
		return fmt.Sprintf(`cpu_total_usage_percent{machine_id="%s"}`, safeMachID), nil
	case MetricCPUTemp:
		return fmt.Sprintf(`cpu_temperature_c{machine_id="%s"}`, safeMachID), nil
	case MetricMemoryUsage:
		return fmt.Sprintf(`memory_usage_percent{machine_id="%s"}`, safeMachID), nil
	case MetricNetworkRx:
		return fmt.Sprintf(`network_rx_bytes_per_sec{machine_id="%s"}`, safeMachID), nil
	case MetricNetworkTx:
		return fmt.Sprintf(`network_tx_bytes_per_sec{machine_id="%s"}`, safeMachID), nil
	case MetricDiskUsage:
		// Aggregated across partitions to guarantee a single cohesive series
		return fmt.Sprintf(`max(disk_usage_percent{machine_id="%s"})`, safeMachID), nil
	default:
		return "", fmt.Errorf("unsupported metric type: %s", metric)
	}
}

// CalculateTimeWindow computes start unix, end unix, and downsample step targeting ~100-360 points.
func CalculateTimeWindow(timeRange, customDateStr string, now time.Time) (int64, int64, string, error) {
	nowUnix := now.Unix()

	switch timeRange {
	case Range1H:
		return nowUnix - 3600, nowUnix, "15s", nil
	case Range6H:
		return nowUnix - 21600, nowUnix, "1m", nil
	case Range12H:
		return nowUnix - 43200, nowUnix, "2m", nil
	case Range24H:
		return nowUnix - 86400, nowUnix, "5m", nil
	case Range3D:
		return nowUnix - 259200, nowUnix, "15m", nil
	case Range7D:
		return nowUnix - 604800, nowUnix, "30m", nil
	case RangeCustomDate:
		if customDateStr == "" {
			return 0, 0, "", fmt.Errorf("date parameter is required for CUSTOM_DATE range")
		}
		t, err := time.Parse("2006-01-02", customDateStr)
		if err != nil {
			return 0, 0, "", fmt.Errorf("invalid date format %q (expected YYYY-MM-DD): %w", customDateStr, err)
		}
		start := t.Unix()
		end := start + 86400 - 1
		return start, end, "5m", nil
	default:
		return 0, 0, "", fmt.Errorf("unsupported time range: %s", timeRange)
	}
}

// ParseVMPoints extracts chronological HistoricalPoint data from VictoriaMetrics JSON payload.
func ParseVMPoints(resp VMQueryResponse) []HistoricalPoint {
	points := make([]HistoricalPoint, 0)
	if len(resp.Data.Result) == 0 {
		return points
	}

	// Use first matching series
	series := resp.Data.Result[0]
	for _, rawTuple := range series.Values {
		if len(rawTuple) < 2 {
			continue
		}

		var ts int64
		switch t := rawTuple[0].(type) {
		case float64:
			ts = int64(t)
		case int64:
			ts = t
		case string:
			if parsed, err := strconv.ParseInt(t, 10, 64); err == nil {
				ts = parsed
			}
		}

		var val float64
		switch v := rawTuple[1].(type) {
		case string:
			if parsed, err := strconv.ParseFloat(v, 64); err == nil {
				val = parsed
			}
		case float64:
			val = v
		}

		points = append(points, HistoricalPoint{
			Timestamp: ts,
			Value:     val,
		})
	}

	return points
}
