package storage

// HistoricalPoint represents a single downsampled data point for historical chart plotting.
type HistoricalPoint struct {
	Timestamp int64   `json:"timestamp"`
	Value     float64 `json:"value"`
}

// VMQueryResponse mirrors the VictoriaMetrics /api/v1/query_range JSON response schema.
type VMQueryResponse struct {
	Status string     `json:"status"`
	Data   VMDataBody `json:"data"`
	Error  string     `json:"error,omitempty"`
}

// VMDataBody contains the result matrix.
type VMDataBody struct {
	ResultType string     `json:"resultType"`
	Result     []VMSeries `json:"result"`
}

// VMSeries represents an individual time series with label metrics and [time, value] tuples.
type VMSeries struct {
	Metric map[string]string `json:"metric"`
	Values [][]interface{}   `json:"values"`
}
