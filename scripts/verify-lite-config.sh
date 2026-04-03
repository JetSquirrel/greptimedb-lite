#!/usr/bin/env bash
# Copyright 2023 Greptime Team
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# verify-lite-config.sh
# Static verification of GreptimeDB Lite resource optimization targets.
# Checks that config/standalone-lite.toml and src/cmd/Cargo.toml contain
# the expected values for the lite build.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$REPO_ROOT/config/standalone-lite.toml"
CARGO_TOML="$REPO_ROOT/src/cmd/Cargo.toml"
COMPOSE="$REPO_ROOT/docker-compose.lite.yml"

PASS=0
FAIL=0

check() {
    local description="$1"
    local file="$2"
    local pattern="$3"

    if grep -qE "$pattern" "$file"; then
        echo "  [PASS] $description"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $description"
        echo "         Expected pattern: $pattern"
        echo "         File: $file"
        FAIL=$((FAIL + 1))
    fi
}

echo "GreptimeDB Lite — Resource Optimization Target Verification"
echo "============================================================"
echo ""

echo "## Memory Optimization Targets (standalone-lite.toml)"
check "global_write_buffer_size = 32MB (was 1GB)"    "$CONFIG" 'global_write_buffer_size\s*=\s*"32MB"'
check "sst_meta_cache_size = 8MB (was 128MB)"         "$CONFIG" 'sst_meta_cache_size\s*=\s*"8MB"'
check "page_cache_size = 64MB (was 512MB)"            "$CONFIG" 'page_cache_size\s*=\s*"64MB"'
check "sst_write_buffer_size = 1MB (was 8MB)"         "$CONFIG" 'sst_write_buffer_size\s*=\s*"1MB"'
check "vector_cache_size = 32MB (was 512MB)"          "$CONFIG" 'vector_cache_size\s*=\s*"32MB"'
echo ""

echo "## CPU / Thread Optimization Targets (standalone-lite.toml)"
check "num_workers = 2 (was 8)"                       "$CONFIG" 'num_workers\s*=\s*2'
check "max_background_jobs = 2 (was 4)"               "$CONFIG" 'max_background_jobs\s*=\s*2'
check "gRPC runtime_size = 2 (was 8)"                 "$CONFIG" 'runtime_size\s*=\s*2'
echo ""

echo "## WAL / Storage Optimization Targets (standalone-lite.toml)"
check "WAL file_size = 64MB (was 256MB)"              "$CONFIG" 'file_size\s*=\s*"64MB"'
check "WAL provider = raft_engine (no Kafka)"         "$CONFIG" 'provider\s*=\s*"raft_engine"'
check "OpenTSDB disabled"                             "$CONFIG" 'enable\s*=\s*false'
check "Flow engine disabled"                          "$CONFIG" '# Disable flow engine for minimal deployment'
echo ""

echo "## Feature Flag Targets (src/cmd/Cargo.toml)"
check "default features empty (no pprof/mem-prof)"   "$CARGO_TOML" 'default\s*=\s*\[\]'
check "lite feature flag defined"                    "$CARGO_TOML" '^lite\s*='
check "pprof gated behind full feature"              "$CARGO_TOML" '"servers/pprof"'
check "mem-prof gated behind full feature"           "$CARGO_TOML" '"servers/mem-prof"'
check "pg_kvbackend gated behind full feature"       "$CARGO_TOML" '"meta-srv/pg_kvbackend"'
check "mysql_kvbackend gated behind full feature"    "$CARGO_TOML" '"meta-srv/mysql_kvbackend"'
echo ""

echo "## Docker Resource Limits (docker-compose.lite.yml)"
# Use awk to verify memory values in their correct stanza (limits vs reservations)
if awk '/limits:/{found=1} found && /memory:/{if($2=="512M"){exit 0} else{exit 1}}' "$COMPOSE"; then
    echo "  [PASS] Memory limit = 512M"
    PASS=$((PASS + 1))
else
    echo "  [FAIL] Memory limit = 512M"
    FAIL=$((FAIL + 1))
fi
check "CPU limit = 2 cores"                          "$COMPOSE" "cpus:\s*'2'"
if awk '/reservations:/{found=1} found && /memory:/{if($2=="128M"){exit 0} else{exit 1}}' "$COMPOSE"; then
    echo "  [PASS] Memory reservation = 128M"
    PASS=$((PASS + 1))
else
    echo "  [FAIL] Memory reservation = 128M"
    FAIL=$((FAIL + 1))
fi
echo ""

echo "============================================================"
echo "Results: $PASS passed, $FAIL failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "Some checks FAILED. Review the configuration files above."
    exit 1
else
    echo "All checks PASSED. Resource optimization targets are verified."
    exit 0
fi
