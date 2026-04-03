#!/bin/bash

# Binary Size Tracking Script for GreptimeDB Lite
# Monitors binary size against budget and tracks historical trends

set -e

BINARY_PATH="${1:-target/release/greptime}"
BUDGET_MB="${2:-90}"
METRICS_DIR="${3:-metrics}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================="
echo "Binary Size Check"
echo "========================================="

# Verify binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${RED}Error: Binary not found at $BINARY_PATH${NC}"
    exit 1
fi

# Get binary size
SIZE_BYTES=$(stat -f%z "$BINARY_PATH" 2>/dev/null || stat -c%s "$BINARY_PATH")
SIZE_MB=$((SIZE_BYTES / 1024 / 1024))
SIZE_KB=$((SIZE_BYTES / 1024))

echo "Binary: $BINARY_PATH"
echo "Size: ${SIZE_MB}MB (${SIZE_KB}KB / ${SIZE_BYTES} bytes)"
echo "Budget: ${BUDGET_MB}MB"
echo ""

# Calculate percentage of budget
PERCENTAGE=$((SIZE_MB * 100 / BUDGET_MB))

# Check against budget
if [ $SIZE_MB -le $BUDGET_MB ]; then
    MARGIN=$((BUDGET_MB - SIZE_MB))
    echo -e "${GREEN}✓ PASSED${NC}"
    echo "  Size: ${SIZE_MB}MB"
    echo "  Budget: ${BUDGET_MB}MB"
    echo "  Margin: ${MARGIN}MB (${PERCENTAGE}% of budget)"
    STATUS="PASSED"
else
    OVER=$((SIZE_MB - BUDGET_MB))
    echo -e "${RED}✗ FAILED${NC}"
    echo "  Size: ${SIZE_MB}MB"
    echo "  Budget: ${BUDGET_MB}MB"
    echo "  Over budget by: ${OVER}MB"
    STATUS="FAILED"
fi

# Save metrics if directory provided
if [ -n "$METRICS_DIR" ]; then
    mkdir -p "$METRICS_DIR"
    echo "$SIZE_MB" > "$METRICS_DIR/binary_size_mb.txt"
    echo "$SIZE_KB" > "$METRICS_DIR/binary_size_kb.txt"
    echo "$SIZE_BYTES" > "$METRICS_DIR/binary_size_bytes.txt"
    echo "$BUDGET_MB" > "$METRICS_DIR/binary_budget_mb.txt"
    echo "$STATUS" > "$METRICS_DIR/binary_size_status.txt"
    date -u +"%Y-%m-%d %H:%M:%S UTC" > "$METRICS_DIR/check_timestamp.txt"

    # Create a CSV entry for historical tracking
    TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP,$SIZE_BYTES,$SIZE_MB,$BUDGET_MB,$STATUS" >> "$METRICS_DIR/binary_size_history.csv"

    echo ""
    echo "Metrics saved to: $METRICS_DIR"
fi

# Exit with appropriate code
if [ "$STATUS" = "PASSED" ]; then
    exit 0
else
    exit 1
fi
