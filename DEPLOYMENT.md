# GreptimeDB-Lite Deployment Guide

This guide covers deployment and configuration options for GreptimeDB-Lite, optimized for
embedded systems and resource-constrained environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Build Options](#build-options)
- [Running Standalone](#running-standalone)
- [Docker Deployment](#docker-deployment)
- [Configuration Reference](#configuration-reference)
- [Resource Tuning](#resource-tuning)
- [Monitoring](#monitoring)
- [Cross-Compilation](#cross-compilation)

---

## Prerequisites

### Runtime Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU       | 1 core  | 2 cores     |
| RAM       | 128 MB  | 512 MB      |
| Disk      | 512 MB  | 2 GB        |
| OS        | Linux (glibc ≥ 2.17) | Ubuntu 22.04+ |

### Build Requirements

- **Rust toolchain**: nightly-2025-10-01 (see `rust-toolchain.toml`)
- **Protobuf compiler**: version ≥ 3.15
- **C/C++ build tools**: `build-essential` (gcc, g++, autoconf)
- **pkg-config** and **libssl-dev**

Install build dependencies on Debian/Ubuntu:

```bash
apt-get install -y build-essential protobuf-compiler pkg-config libssl-dev
```

---

## Build Options

### Lite Build (recommended for embedded/edge)

```bash
# Install Rust nightly toolchain
rustup toolchain install nightly-2025-10-01

# Build lite version (no profiling tools, no remote DB backends)
make build-lite
# Equivalent: cargo build --release --features=lite
```

Binary output: `target/release/greptime`

### Full Build (development/testing)

```bash
cargo build --release --features=full
```

### Feature Flags

| Feature    | Description                                      | Default |
|------------|--------------------------------------------------|---------|
| `lite`     | Lightweight build marker                         | ❌      |
| `full`     | Enables pprof, mem-prof, pg/mysql backends       | ❌      |
| `enterprise` | Enterprise-only features                       | ❌      |
| `vector_index` | Vector similarity search support             | ❌      |
| `tokio-console` | Async task inspector                        | ❌      |

---

## Running Standalone

### Quick Start

```bash
# Using the lite configuration (recommended)
./target/release/greptime standalone start \
  --config-file config/standalone-lite.toml
```

### Custom Arguments

```bash
./target/release/greptime standalone start \
  --http-addr 127.0.0.1:4000 \
  --rpc-bind-addr 127.0.0.1:4001 \
  --mysql-addr 127.0.0.1:4002 \
  --postgres-addr 127.0.0.1:4003 \
  --data-home /var/lib/greptimedb
```

### Default Ports

| Protocol   | Default Port |
|------------|-------------|
| HTTP       | 4000        |
| gRPC       | 4001        |
| MySQL      | 4002        |
| PostgreSQL | 4003        |

### Verifying the Service

```bash
# Check service health
curl http://localhost:4000/health

# Run a basic SQL query
curl -X POST http://localhost:4000/v1/sql \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'sql=SELECT 1'

# Connect via MySQL client
mysql -h 127.0.0.1 -P 4002 -u greptime

# Connect via PostgreSQL client
psql -h 127.0.0.1 -p 4003 -U greptime
```

---

## Docker Deployment

### Build the Docker Image

```bash
# Using Makefile
make docker-lite

# Equivalent direct command
docker build -f Dockerfile.lite -t greptimedb-lite:latest .
```

### Run with Docker Compose (recommended)

```bash
# Start the service
docker-compose -f docker-compose.lite.yml up -d

# View logs
docker-compose -f docker-compose.lite.yml logs -f

# Stop the service
docker-compose -f docker-compose.lite.yml down
```

The Docker Compose configuration applies resource constraints:
- **CPU limit**: 2 cores
- **Memory limit**: 512 MB
- **Memory reservation**: 128 MB

### Run with Docker Directly

```bash
docker run -d \
  --name greptimedb-lite \
  -p 4000-4003:4000-4003 \
  -v $(pwd)/data:/tmp/greptimedb \
  -v $(pwd)/config/standalone-lite.toml:/etc/greptimedb/config.toml:ro \
  --memory="512m" \
  --cpus="2" \
  greptimedb-lite:latest
```

---

## Configuration Reference

The lite configuration file is at `config/standalone-lite.toml`.

### Network

```toml
[http]
addr = "127.0.0.1:4000"
timeout = "10s"

[grpc]
addr = "127.0.0.1:4001"
runtime_size = 2

[mysql]
addr = "127.0.0.1:4002"
runtime_size = 1

[postgres]
addr = "127.0.0.1:4003"
runtime_size = 1
```

To accept connections from other hosts, change `127.0.0.1` to `0.0.0.0`.

### Storage

```toml
[storage]
data_home = "/tmp/greptimedb"
type = "File"
```

Change `data_home` to a persistent directory in production deployments.

### WAL

```toml
[wal]
provider = "raft_engine"
dir = "/tmp/greptimedb/wal"
file_size = "64MB"
purge_threshold = "1GB"
```

### Memory Engine Settings

```toml
[region_engine.mito]
num_workers = 2
global_write_buffer_size = "32MB"
sst_meta_cache_size = "8MB"
page_cache_size = "64MB"
```

### Disabled Protocols

```toml
[opentsdb]
enable = false

[influxdb]
enable = false
```

### Logging

```toml
[logging]
level = "info"            # trace | debug | info | warn | error
dir = "/tmp/greptimedb/logs"
append_mode = false
```

---

## Resource Tuning

### Configuration Profiles by Available RAM

#### Minimal (128 MB RAM)

```toml
[region_engine.mito]
num_workers = 1
global_write_buffer_size = "16MB"
global_write_buffer_reject_size = "32MB"
sst_meta_cache_size = "4MB"
page_cache_size = "32MB"
sst_write_buffer_size = "512KB"
max_background_jobs = 1

[grpc]
runtime_size = 1

[mysql]
runtime_size = 1

[postgres]
runtime_size = 1
```

#### Standard (512 MB RAM) — default lite config

```toml
[region_engine.mito]
num_workers = 2
global_write_buffer_size = "32MB"
page_cache_size = "64MB"
```

#### Enhanced (1 GB+ RAM)

```toml
[region_engine.mito]
num_workers = 4
global_write_buffer_size = "64MB"
sst_meta_cache_size = "16MB"
page_cache_size = "128MB"

[grpc]
runtime_size = 4
```

### Disabling Optional Features

To further reduce overhead, set in `standalone-lite.toml`:

```toml
[mysql]
enable = false          # Disable MySQL protocol entirely

[postgres]
enable = false          # Disable PostgreSQL protocol entirely

[mode_config.standalone.flow]
enable = false          # Disable stream processing

[export_metrics]
enable = false          # Disable metrics exporter
```

---

## Monitoring

### Key Health Endpoint

```bash
curl http://localhost:4000/health
```

Expected response: `{"status":"UP"}`

### Metrics Endpoint (if enabled)

```bash
# Enable in config:
# [export_metrics]
# enable = true
# write_interval = "30s"

curl http://localhost:4000/metrics
```

### Key Metrics to Track

| Metric            | Target         |
|-------------------|----------------|
| Idle memory usage | < 100 MB       |
| Load memory usage | < 500 MB       |
| Write throughput  | > 1000 pts/sec |
| Query latency     | < 1 second     |
| Binary size       | < 100 MB       |

### Process Monitoring

```bash
# Monitor memory and CPU usage
watch -n 1 'ps -o pid,rss,pcpu,comm -p $(pgrep greptime)'

# Monitor open file descriptors
ls -la /proc/$(pgrep greptime)/fd | wc -l
```

---

## Cross-Compilation

### ARM64 (aarch64) for IoT/Edge Devices

```bash
# Install target
rustup target add aarch64-unknown-linux-gnu

# Install cross-compilation linker
apt-get install -y gcc-aarch64-linux-gnu

# Build
CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc \
cargo build --release \
  --target=aarch64-unknown-linux-gnu \
  --features=lite
```

Binary output: `target/aarch64-unknown-linux-gnu/release/greptime`

### Using `cross` Tool

```bash
# Install cross
cargo install cross

# Build for ARM64
cross build --release --target=aarch64-unknown-linux-gnu --features=lite

# Build for ARMv7 (32-bit)
cross build --release --target=armv7-unknown-linux-gnueabihf --features=lite
```

See `Cross.toml` for pre-configured targets.

---

## Troubleshooting

### Service Fails to Start

1. Check log output: `cat /tmp/greptimedb/logs/*.log`
2. Verify port availability: `ss -tlnp | grep -E '400[0-3]'`
3. Confirm data directory permissions: `ls -la /tmp/greptimedb`

### High Memory Usage

- Reduce `global_write_buffer_size` and `page_cache_size` in the config
- Reduce `num_workers` to 1
- Disable unused protocols (MySQL, PostgreSQL)

### Write Errors

- Check WAL directory has sufficient disk space
- Review `purge_threshold` if WAL directory grows large
- Lower `file_size` under `[wal]` for smaller footprint

---

## Security Considerations

- Bind HTTP/gRPC/MySQL/PostgreSQL to `127.0.0.1` for local-only access
- Use a firewall to restrict access to database ports in networked deployments
- Keep the binary up-to-date to receive security patches
- Report vulnerabilities to info@greptime.com (see `SECURITY.md`)
