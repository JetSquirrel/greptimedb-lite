#!/bin/bash

# GreptimeDB Lite Smoke Test Script
# Tests HTTP, MySQL, and PostgreSQL endpoints to ensure basic functionality

set -e

BINARY_PATH="${1:-./target/release/greptime}"
CONFIG_PATH="${2:-config/standalone-lite.toml}"
TEST_DIR="/tmp/greptimedb-smoke-test"
PID_FILE="/tmp/greptimedb-test.pid"
LOG_FILE="/tmp/greptimedb-test.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "GreptimeDB Lite Smoke Test"
echo "========================================="
echo "Binary: $BINARY_PATH"
echo "Config: $CONFIG_PATH"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "Cleaning up..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo "Stopping GreptimeDB (PID: $PID)..."
            kill $PID || true
            sleep 2
            # Force kill if still running
            if ps -p $PID > /dev/null 2>&1; then
                kill -9 $PID || true
            fi
        fi
        rm -f "$PID_FILE"
    fi
    rm -rf "$TEST_DIR"
    echo "Cleanup complete"
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Verify binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${RED}Error: Binary not found at $BINARY_PATH${NC}"
    exit 1
fi

# Verify config exists
if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}Error: Config not found at $CONFIG_PATH${NC}"
    exit 1
fi

# Create test directory
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Start GreptimeDB
echo -e "${YELLOW}Starting GreptimeDB...${NC}"
"$BINARY_PATH" standalone start --config-file "$CONFIG_PATH" > "$LOG_FILE" 2>&1 &
PID=$!
echo $PID > "$PID_FILE"
echo "GreptimeDB started with PID: $PID"

# Wait for startup
echo "Waiting for GreptimeDB to start..."
MAX_WAIT=60
COUNTER=0
while [ $COUNTER -lt $MAX_WAIT ]; do
    if curl -s http://127.0.0.1:4000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ GreptimeDB is ready${NC}"
        break
    fi
    sleep 1
    COUNTER=$((COUNTER + 1))
    if [ $((COUNTER % 10)) -eq 0 ]; then
        echo "Still waiting... ($COUNTER/$MAX_WAIT seconds)"
    fi
done

if [ $COUNTER -ge $MAX_WAIT ]; then
    echo -e "${RED}Error: GreptimeDB failed to start within $MAX_WAIT seconds${NC}"
    echo "Last 50 lines of log:"
    tail -50 "$LOG_FILE"
    exit 1
fi

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test and track results
run_test() {
    local test_name=$1
    local test_command=$2

    echo ""
    echo -e "${YELLOW}Running: $test_name${NC}"

    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: HTTP Health Check
run_test "HTTP Health Check" \
    "curl -f -s http://127.0.0.1:4000/health"

# Test 2: HTTP Version Check
run_test "HTTP Version Check" \
    "curl -f -s http://127.0.0.1:4000/v1/health | grep -q version"

# Test 3: HTTP SQL Query - Create Database
run_test "HTTP SQL - Create Database" \
    "curl -f -s -X POST 'http://127.0.0.1:4000/v1/sql?db=public' \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -d 'sql=CREATE DATABASE IF NOT EXISTS smoke_test'"

# Test 4: HTTP SQL Query - Create Table
run_test "HTTP SQL - Create Table" \
    "curl -f -s -X POST 'http://127.0.0.1:4000/v1/sql?db=smoke_test' \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -d 'sql=CREATE TABLE IF NOT EXISTS test_metrics (ts TIMESTAMP TIME INDEX, value DOUBLE, host STRING, PRIMARY KEY(host))'"

# Test 5: HTTP SQL Query - Insert Data
run_test "HTTP SQL - Insert Data" \
    "curl -f -s -X POST 'http://127.0.0.1:4000/v1/sql?db=smoke_test' \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -d 'sql=INSERT INTO test_metrics VALUES (1672531200000, 42.5, \"host1\"), (1672531260000, 43.2, \"host1\")'"

# Test 6: HTTP SQL Query - Select Data
run_test "HTTP SQL - Select Data" \
    "curl -f -s -X POST 'http://127.0.0.1:4000/v1/sql?db=smoke_test' \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -d 'sql=SELECT * FROM test_metrics' | grep -q '42.5'"

# Test 7: MySQL Protocol - Basic Query
run_test "MySQL Protocol - Connection & Query" \
    "mysql -h 127.0.0.1 -P 4002 -e 'SELECT 1 as test' 2>/dev/null | grep -q test"

# Test 8: MySQL Protocol - Query Table
run_test "MySQL Protocol - Query Table" \
    "mysql -h 127.0.0.1 -P 4002 -D smoke_test -e 'SELECT COUNT(*) FROM test_metrics' 2>/dev/null | grep -q 2"

# Test 9: PostgreSQL Protocol - Basic Query
run_test "PostgreSQL Protocol - Connection & Query" \
    "psql -h 127.0.0.1 -p 4003 -U postgres -d smoke_test -c 'SELECT 1 as test;' 2>/dev/null | grep -q test"

# Test 10: PostgreSQL Protocol - Query Table
run_test "PostgreSQL Protocol - Query Table" \
    "psql -h 127.0.0.1 -p 4003 -U postgres -d smoke_test -c 'SELECT COUNT(*) FROM test_metrics;' 2>/dev/null | grep -q 2"

# Test 11: Prometheus Remote Write Endpoint
run_test "Prometheus Remote Write Endpoint Check" \
    "curl -f -s http://127.0.0.1:4000/v1/prometheus/write -X POST -H 'Content-Type: application/x-protobuf' -d '' | grep -q 'decode'"

# Test 12: Check Memory Footprint
echo ""
echo -e "${YELLOW}Checking Memory Footprint...${NC}"
RSS_KB=$(ps -o rss= -p $PID)
RSS_MB=$((RSS_KB / 1024))
echo "Memory Usage (RSS): ${RSS_MB}MB"

if [ $RSS_MB -le 500 ]; then
    echo -e "${GREEN}✓ Memory usage is within budget (${RSS_MB}MB <= 500MB)${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${YELLOW}⚠ Memory usage is ${RSS_MB}MB (budget: 500MB)${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Print summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All smoke tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Log file: $LOG_FILE"
    echo "Last 100 lines of log:"
    tail -100 "$LOG_FILE"
    exit 1
fi
