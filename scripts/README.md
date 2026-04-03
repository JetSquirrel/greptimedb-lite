# GreptimeDB Lite Testing and Monitoring Scripts

This directory contains scripts for testing, monitoring, and validating the GreptimeDB Lite build.

## Scripts

### `lite-smoke-test.sh`

Comprehensive smoke test script that validates all major endpoints and protocols.

**Usage:**
```bash
./scripts/lite-smoke-test.sh [binary_path] [config_path]
```

**Default values:**
- Binary: `./target/release/greptime`
- Config: `config/standalone-lite.toml`

**Tests performed:**
1. HTTP health check
2. HTTP version endpoint
3. HTTP SQL queries (CREATE DATABASE, CREATE TABLE, INSERT, SELECT)
4. MySQL protocol connectivity and queries
5. PostgreSQL protocol connectivity and queries
6. Prometheus remote write endpoint validation
7. Memory footprint verification

**Requirements:**
- `curl` - HTTP testing
- `mysql` client - MySQL protocol testing
- `psql` client - PostgreSQL protocol testing
- `jq` - JSON parsing (optional)

**Exit codes:**
- `0` - All tests passed
- `1` - One or more tests failed

**Example:**
```bash
# Run with defaults
./scripts/lite-smoke-test.sh

# Run with custom binary and config
./scripts/lite-smoke-test.sh ./bin/greptime ./my-config.toml
```

### `check-binary-size.sh`

Binary size monitoring script with budget enforcement.

**Usage:**
```bash
./scripts/check-binary-size.sh [binary_path] [budget_mb] [metrics_dir]
```

**Default values:**
- Binary: `target/release/greptime`
- Budget: `90` MB
- Metrics: `metrics/`

**Features:**
- Validates binary size against configurable budget
- Exports metrics to files for tracking
- Maintains historical CSV log
- Color-coded output (pass/fail)

**Metrics exported:**
- `binary_size_mb.txt` - Size in megabytes
- `binary_size_kb.txt` - Size in kilobytes
- `binary_size_bytes.txt` - Size in bytes
- `binary_budget_mb.txt` - Budget threshold
- `binary_size_status.txt` - PASSED or FAILED
- `binary_size_history.csv` - Historical log
- `check_timestamp.txt` - Check timestamp

**Exit codes:**
- `0` - Size within budget
- `1` - Size exceeds budget

**Example:**
```bash
# Check with defaults (90MB budget)
./scripts/check-binary-size.sh

# Check with custom budget
./scripts/check-binary-size.sh target/release/greptime 100 ./my-metrics

# Check in CI
./scripts/check-binary-size.sh $BINARY_PATH $BUDGET_MB $METRICS_DIR
```

## CI Integration

These scripts are integrated into the `.github/workflows/lite-ci.yml` workflow:

1. **Build Step**: Compiles the lite version
2. **Size Check**: Runs `check-binary-size.sh` to validate budget
3. **Smoke Test**: Runs `lite-smoke-test.sh` to validate functionality
4. **Docker Build**: Tests Docker image creation
5. **Metrics Upload**: Archives metrics as CI artifacts

## Local Testing

To test the lite build locally:

```bash
# Build the lite version
make build-lite

# Check binary size
./scripts/check-binary-size.sh

# Run smoke tests
./scripts/lite-smoke-test.sh
```

## Resource Budgets

Current budgets (defined in `lite-ci.yml`):
- **Binary Size**: 90 MB (per spec.md)
- **Startup Memory**: 500 MB (per spec.md and roadmap.md)
- **Docker Image**: ~300 MB (warning threshold)

## Troubleshooting

### Smoke tests fail to connect

If tests fail with connection errors:
1. Check if GreptimeDB started successfully
2. Review logs at `/tmp/greptimedb-test.log`
3. Verify ports 4000-4003 are available
4. Ensure config file exists and is valid

### Binary size exceeds budget

If size check fails:
1. Review recent code changes
2. Check for new dependencies in `Cargo.toml`
3. Verify `--features=lite` is used in build
4. Consider using `strip` or `upx` for release builds

### Memory usage exceeds budget

If memory check fails:
1. Review config settings in `standalone-lite.toml`
2. Check for memory leaks or inefficient allocations
3. Profile with tools like `valgrind` or `heaptrack`
4. Reduce buffer sizes in configuration

## Adding New Tests

To add tests to `lite-smoke-test.sh`:

1. Use the `run_test` function for consistency
2. Provide a clear test name
3. Return appropriate exit codes (0 = pass, non-zero = fail)
4. Update test count expectations in CI

Example:
```bash
run_test "My New Test" \
    "curl -f http://localhost:4000/my-endpoint"
```

## Metrics History

Metrics are tracked over time in CSV format:
- Timestamp
- Binary size (bytes)
- Binary size (MB)
- Budget (MB)
- Status (PASSED/FAILED)

This allows for trend analysis and regression detection.
