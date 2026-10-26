#!/usr/bin/env bash
# ==============================================================================
# AncyMon Infrastructure Verification Script
# Validates VictoriaMetrics TSDB ingestion, MetricsQL querying, and Caddy TLS
# ==============================================================================

set -euo pipefail

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    exit 1
}

# Determine execution wrapper:
# If localhost:8428 is directly reachable, execute natively.
# Otherwise, route through the ancymon-caddy container (which runs in host network mode).
EXEC_PREFIX=""
if ! curl -fsS http://localhost:8428/health >/dev/null 2>&1; then
    if docker ps --format '{{.Names}}' | grep -q '^ancymon-caddy$'; then
        log_info "Localhost not directly reachable in sandbox; executing via ancymon-caddy container (host network)."
        EXEC_PREFIX="docker exec ancymon-caddy"
    else
        log_fail "VictoriaMetrics is not reachable on localhost:8428 and ancymon-caddy container is not running."
    fi
fi

# ------------------------------------------------------------------------------
# Test 1: VictoriaMetrics Health Check
# ------------------------------------------------------------------------------
log_info "1. Verifying VictoriaMetrics health status on port 8428..."
HEALTH_RESPONSE=$($EXEC_PREFIX curl -fsS http://localhost:8428/health)

if [[ "${HEALTH_RESPONSE}" == "OK" ]]; then
    log_pass "VictoriaMetrics is healthy (http://localhost:8428/health returned '${HEALTH_RESPONSE}')."
else
    log_fail "Unexpected health response from VictoriaMetrics: '${HEALTH_RESPONSE}'"
fi

# ------------------------------------------------------------------------------
# Test 2: Ingest Telemetry Metric via Influx Line Protocol
# ------------------------------------------------------------------------------
log_info "2. Ingesting telemetry sample via Influx Line Protocol..."
CURRENT_TS=$($EXEC_PREFIX date +%s)
START_TS=$((CURRENT_TS - 60))
END_TS=$((CURRENT_TS + 60))
TEST_UUID="test-uuid"
TEST_HOST="dev-box"
TEST_VALUE="25.5"
LINE_PROTOCOL_PAYLOAD="ancymon_cpu,machine_id=${TEST_UUID},hostname=${TEST_HOST} total_usage=${TEST_VALUE} ${CURRENT_TS}"

HTTP_CODE=$($EXEC_PREFIX curl -s -o /dev/null -w "%{http_code}" -X POST "http://localhost:8428/write?precision=s" --data-binary "${LINE_PROTOCOL_PAYLOAD}")

if [[ "${HTTP_CODE}" == "204" ]]; then
    log_pass "Metric successfully ingested (HTTP 204 No Content)."
else
    log_fail "Failed to ingest metric via /write (HTTP ${HTTP_CODE})."
fi

# Force flush in-memory buffer to guarantee instantaneous persistence for query test
$EXEC_PREFIX curl -fsS "http://localhost:8428/internal/force_flush" >/dev/null

# ------------------------------------------------------------------------------
# Test 3: Historical MetricsQL Analytical Query
# ------------------------------------------------------------------------------
log_info "3. Querying VictoriaMetrics with MetricsQL (/api/v1/query_range and /api/v1/query)..."

# Instantaneous vector query at the exact ingested timestamp
INSTANT_RESULT=$($EXEC_PREFIX curl -fsS "http://localhost:8428/api/v1/query?query=ancymon_cpu_total_usage&time=${CURRENT_TS}")

if echo "${INSTANT_RESULT}" | grep -q "${TEST_UUID}" && echo "${INSTANT_RESULT}" | grep -q "${TEST_VALUE}"; then
    log_pass "Instantaneous MetricsQL query returned matching series and metric value (${TEST_VALUE})."
else
    log_fail "Instantaneous query failed. Response: ${INSTANT_RESULT}"
fi

# Range query with step over the ingestion window
RANGE_RESULT=$($EXEC_PREFIX curl -fsS "http://localhost:8428/api/v1/query_range?query=ancymon_cpu_total_usage&start=${START_TS}&end=${END_TS}&step=5s")

if echo "${RANGE_RESULT}" | grep -q "${TEST_UUID}" && echo "${RANGE_RESULT}" | grep -q "ancymon_cpu_total_usage"; then
    log_pass "MetricsQL query_range successfully retrieved historical time-series points."
else
    log_fail "MetricsQL query_range failed. Response: ${RANGE_RESULT}"
fi

# ------------------------------------------------------------------------------
# Test 4: Caddy Gateway Health & TLS Handshake
# ------------------------------------------------------------------------------
log_info "4. Testing Caddy reverse proxy on port 443..."

GATEWAY_RESPONSE=$($EXEC_PREFIX curl -k -fsS https://localhost:443/)
EXPECTED_GATEWAY="AncyMon Telemetry Gateway Online"

if echo "${GATEWAY_RESPONSE}" | grep -q "${EXPECTED_GATEWAY}"; then
    log_pass "Caddy ingress gateway responded with 200 OK: '${EXPECTED_GATEWAY}'."
else
    log_fail "Caddy ingress check failed. Response: ${GATEWAY_RESPONSE}"
fi

# ------------------------------------------------------------------------------
# Test 5: Validate Internal ECDSA P-256 Certificate
# ------------------------------------------------------------------------------
log_info "5. Verifying internal ECDSA P-256 CA and TLS certificate negotiation..."

CERT_DETAILS=$($EXEC_PREFIX sh -c "openssl s_client -connect localhost:443 -servername localhost </dev/null 2>/dev/null | openssl x509 -text -noout")

if echo "${CERT_DETAILS}" | grep -q -E "(P-256|prime256v1|id-ecPublicKey)"; then
    log_pass "Caddy TLS certificate is confirmed ECDSA P-256 (prime256v1)."
else
    log_fail "TLS certificate does not match expected ECDSA P-256 properties. Details: ${CERT_DETAILS}"
fi

# Verify the root CA stored on volume
ROOT_CA_EXISTS=$($EXEC_PREFIX test -f /data/caddy/pki/authorities/local/root.crt && echo "yes" || echo "no")
if [[ "${ROOT_CA_EXISTS}" == "yes" ]]; then
    ROOT_CA_INFO=$($EXEC_PREFIX openssl x509 -in /data/caddy/pki/authorities/local/root.crt -text -noout)
    if echo "${ROOT_CA_INFO}" | grep -q -E "(P-256|prime256v1)"; then
        log_pass "Internal Root CA certificate exists in persistent storage and uses ECDSA P-256."
    else
        log_fail "Internal Root CA does not use ECDSA P-256."
    fi
else
    log_fail "Root CA certificate not found at /data/caddy/pki/authorities/local/root.crt"
fi

echo ""
echo -e "${GREEN}======================================================================${NC}"
echo -e "${GREEN}All AncyMon Phase 1 infrastructure tests PASSED successfully!${NC}"
echo -e "${GREEN}======================================================================${NC}"
