package graphql

import (
	"ancymon/server/internal/storage"
	"ancymon/server/internal/watchdog"
	"context"
	"fmt"
	"regexp"
	"strings"
)

// Request encapsulates a GraphQL HTTP or WebSocket query payload.
type Request struct {
	Query         string                 `json:"query"`
	OperationName string                 `json:"operationName,omitempty"`
	Variables     map[string]interface{} `json:"variables,omitempty"`
}

// Response models the GraphQL JSON response envelope.
type Response struct {
	Data   interface{}    `json:"data"`
	Errors []GraphQLError `json:"errors,omitempty"`
}

// GraphQLError describes an execution or validation failure.
type GraphQLError struct {
	Message string `json:"message"`
}

// Resolver executes GraphQL queries and mutations against storage and watchdog.
type Resolver struct {
	registry *watchdog.Registry
	querier  *storage.Querier
}

// NewResolver creates a new GraphQL request resolver.
func NewResolver(reg *watchdog.Registry, querier *storage.Querier) *Resolver {
	return &Resolver{
		registry: reg,
		querier:  querier,
	}
}

// Execute handles Query and Mutation operations.
func (r *Resolver) Execute(ctx context.Context, req Request) Response {
	q := strings.TrimSpace(req.Query)
	if q == "" {
		return Response{Data: nil, Errors: []GraphQLError{{Message: "query cannot be empty"}}}
	}

	// 1. Introspection query handling
	if strings.Contains(q, "__schema") || strings.Contains(q, "IntrospectionQuery") {
		return Response{
			Data: map[string]interface{}{
				"__schema": map[string]interface{}{
					"types": []interface{}{
						map[string]interface{}{"name": "Query", "kind": "OBJECT"},
						map[string]interface{}{"name": "Mutation", "kind": "OBJECT"},
						map[string]interface{}{"name": "Subscription", "kind": "OBJECT"},
						map[string]interface{}{"name": "MachineSummary", "kind": "OBJECT"},
						map[string]interface{}{"name": "MachineDetail", "kind": "OBJECT"},
						map[string]interface{}{"name": "HistoricalPoint", "kind": "OBJECT"},
					},
				},
			},
		}
	}

	// 2. Query: machineHistory
	if strings.Contains(q, "machineHistory") {
		machID := getStringArg(req.Variables, "machineId", q, `machineId\s*:\s*(?:"([^"]+)"|([A-Za-z0-9_-]+))`)
		metric := getStringArg(req.Variables, "metric", q, `metric\s*:\s*(?:"([^"]+)"|([A-Za-z0-9_]+))`)
		timeRange := getStringArg(req.Variables, "range", q, `range\s*:\s*(?:"([^"]+)"|([A-Za-z0-9_]+))`)
		dateStr := getStringArg(req.Variables, "date", q, `date\s*:\s*(?:"([^"]+)"|([A-Za-z0-9_-]+))`)

		if machID == "" {
			return Response{Data: nil, Errors: []GraphQLError{{Message: "missing required argument: machineId"}}}
		}
		if metric == "" {
			return Response{Data: nil, Errors: []GraphQLError{{Message: "missing required argument: metric"}}}
		}
		if timeRange == "" {
			return Response{Data: nil, Errors: []GraphQLError{{Message: "missing required argument: range"}}}
		}

		if r.querier == nil {
			return Response{Data: nil, Errors: []GraphQLError{{Message: "historical storage querier is unconfigured"}}}
		}

		points, err := r.querier.QueryHistory(ctx, machID, metric, timeRange, dateStr)
		if err != nil {
			return Response{Data: nil, Errors: []GraphQLError{{Message: fmt.Sprintf("historical query failed: %v", err)}}}
		}

		return Response{
			Data: map[string]interface{}{
				"machineHistory": points,
			},
		}
	}

	// 3. Mutation: deleteMachine
	if strings.Contains(q, "deleteMachine") {
		machID := getStringArg(req.Variables, "machineId", q, `machineId\s*:\s*(?:"([^"]+)"|([A-Za-z0-9_-]+))`)
		if machID == "" {
			return Response{Data: nil, Errors: []GraphQLError{{Message: "missing required argument: machineId"}}}
		}

		if r.registry == nil {
			return Response{Data: nil, Errors: []GraphQLError{{Message: "registry is unconfigured"}}}
		}

		success := r.registry.DeleteMachine(machID)
		return Response{
			Data: map[string]interface{}{
				"deleteMachine": success,
			},
		}
	}

	return Response{
		Data:   nil,
		Errors: []GraphQLError{{Message: fmt.Sprintf("unsupported or unrecognized operation in query: %s", q)}},
	}
}

// ParseSubscription determines subscription type ("fleetSummary" or "machineMetrics") and parameters.
func ParseSubscription(query string, vars map[string]interface{}) (subType string, machineID string, err error) {
	if strings.Contains(query, "fleetSummary") {
		return "fleetSummary", "", nil
	}

	if strings.Contains(query, "machineMetrics") {
		machID := getStringArg(vars, "machineId", query, `machineId\s*:\s*(?:"([^"]+)"|([A-Za-z0-9_-]+))`)
		if machID == "" {
			return "", "", fmt.Errorf("missing required argument machineId for machineMetrics subscription")
		}
		return "machineMetrics", machID, nil
	}

	return "", "", fmt.Errorf("unrecognized subscription: query must include fleetSummary or machineMetrics")
}

// getStringArg retrieves string argument from variables map or regex matches inline in the query text.
func getStringArg(vars map[string]interface{}, key, query, pattern string) string {
	if vars != nil {
		if val, exists := vars[key]; exists && val != nil {
			switch v := val.(type) {
			case string:
				return strings.TrimSpace(v)
			default:
				return fmt.Sprintf("%v", v)
			}
		}
	}

	re := regexp.MustCompile(pattern)
	matches := re.FindStringSubmatch(query)
	if len(matches) > 1 {
		if len(matches) > 2 && matches[2] != "" {
			return matches[2]
		}
		return matches[1]
	}

	return ""
}
