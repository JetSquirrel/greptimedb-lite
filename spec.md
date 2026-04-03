# greptimedb-lite Specification

## Project Overview

GreptimeDB-Lite is a lightweight, optimized version of GreptimeDB designed for embedded systems and resource-constrained environments. It is an open-source observability database that unifies metrics, logs, and traces into a single system, serving as a drop-in replacement for Prometheus, Loki, and Elasticsearch.

**Imported from**: https://github.com/JetSquirrel/greptimedb-lite
**Technology Stack**: Rust
**License**: Apache License 2.0

## Current State Analysis

This project was imported from an existing repository. GreptimeDB-Lite is a production-ready observability database with the following characteristics:

### Key Features
- **Lightweight Design**: 30-40% smaller binary size, 50-60% reduced memory usage compared to full version
- **Single-Machine Optimized**: Standalone mode for embedded systems and local environments
- **Protocol Support**: HTTP, MySQL, PostgreSQL, Prometheus remote write
- **Query Languages**: SQL and PromQL
- **Storage Engine**: Mito2 engine with local file storage
- **Observability 2.0**: Unified approach treating metrics, logs, and traces as wide events

### Optimizations
- **Memory**: Global write buffer reduced from 1GB to 32MB
- **CPU**: Worker threads reduced from 8 to 2
- **Disk**: WAL files reduced from 256MB to 64MB
- **Features**: Disabled distributed cluster, Kafka WAL, vector indexing, profiling tools

### Project Status
- Currently in RC (Release Candidate) phase
- Targeting v1.0 GA in March 2026
- Active development with regular releases
- Comprehensive test coverage and CI/CD pipeline

## Goals

- [ ] Maintain existing lightweight functionality optimized for embedded systems
- [ ] Improve code quality and maintain high test coverage
- [ ] Enhance documentation for deployment and configuration
- [ ] Continue optimization for resource-constrained environments
- [ ] Ensure stability and production-readiness for v1.0 GA

## Requirements

### Functional Requirements

1. **Core Database Features**
   - Single-node standalone mode operation
   - SQL and PromQL query processing
   - Time-series data storage with Mito2 engine
   - Local file-based storage backend

2. **Protocol Support**
   - HTTP API for queries and ingestion
   - MySQL protocol compatibility
   - PostgreSQL protocol compatibility
   - Prometheus remote write protocol
   - OpenTelemetry native support

3. **Resource Optimization**
   - Binary size under 100MB
   - Idle memory usage under 100MB
   - Configurable memory limits for constrained environments
   - Efficient CPU utilization with minimal threads

4. **Data Management**
   - Time-series data ingestion
   - Query optimization for time-range queries
   - Data retention and compaction
   - WAL management and recovery

### Non-Functional Requirements

1. **Performance**
   - Sub-second query response for typical time-series queries
   - Handle thousands of data points per second on modest hardware
   - Efficient memory usage during high write loads

2. **Security**
   - Address any security vulnerabilities identified by CodeQL
   - Secure protocol implementations
   - Safe handling of user input and queries

3. **Maintainability**
   - Follow Rust best practices and idioms
   - Comprehensive inline documentation
   - Clear error messages and logging
   - Modular architecture for easy testing

4. **Reliability**
   - Graceful degradation under resource constraints
   - Robust error handling and recovery
   - Data consistency and durability guarantees

5. **Testing**
   - Maintain >80% code coverage
   - Integration tests for all protocols
   - Performance benchmarks
   - Fuzz testing for critical components

## Technical Stack

**Language**: Rust (nightly toolchain)
**Storage Engine**: Mito2
**Query Engine**: Apache DataFusion
**Storage Format**: Apache Parquet
**Data Access**: Apache OpenDAL
**Memory Model**: Apache Arrow

### Build Requirements
- Rust toolchain (nightly)
- Protobuf compiler (>= 3.15)
- C/C++ build essentials (gcc/g++/autoconf)
- glibc library

### Key Dependencies
- `mito2` - Storage engine
- `datanode` - Data node functionality
- `frontend` - Query processing
- `servers` - Protocol servers
- `tokio` - Async runtime
- `datafusion` - Query execution

## Success Criteria

The project maintenance is successful when:

1. **Stability**: All existing tests pass consistently
2. **Quality**: Code coverage maintained above 80%
3. **Documentation**: Complete deployment and configuration guides
4. **Security**: No critical security vulnerabilities
5. **Performance**: Resource usage stays within lightweight targets
6. **Compatibility**: All protocol implementations remain functional
7. **Build**: Clean builds on target platforms (Linux, embedded ARM)

## Development Priorities

### High Priority
1. Maintain stability and backward compatibility
2. Address security vulnerabilities promptly
3. Keep resource usage within lightweight targets
4. Ensure all tests pass on CI/CD pipeline

### Medium Priority
1. Improve documentation and examples
2. Optimize query performance
3. Enhance error messages and logging
4. Add configuration validation

### Low Priority
1. Code refactoring for maintainability
2. Additional protocol optimizations
3. Performance benchmarking improvements

## Target Environments

### ✅ Suitable For
- Edge devices and IoT gateways
- Embedded Linux systems
- Resource-constrained VMs
- Single-machine monitoring
- Development and testing environments
- Local data analysis

### ❌ Not Suitable For
- High-availability production clusters
- Horizontally-scaled deployments
- Kafka-integrated scenarios
- Distributed coordination requirements

## Configuration Management

The project includes optimized configuration in `config/standalone-lite.toml`:

- **Memory limits**: 32MB write buffer, 8MB SST cache, 64MB page cache
- **Thread pools**: 2 workers, 2 background jobs, 2 gRPC runtime threads
- **Disabled features**: OpenTSDB, InfluxDB protocols, metrics export
- **Storage**: Local file-based WAL and data storage

## Monitoring and Metrics

Key metrics to track:
- Binary size (target: <100MB)
- Idle memory usage (target: <100MB)
- Memory under load (target: <500MB)
- Query latency (target: <1s for typical queries)
- Write throughput (target: >1000 points/sec)
- Test coverage (target: >80%)

---

**Note**: This spec was created based on analysis of the existing repository.
The control panel will maintain the lightweight characteristics while ensuring
stability, security, and production-readiness for the v1.0 GA release.
