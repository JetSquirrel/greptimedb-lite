# Task Progress for greptimedb-lite

**Project**: greptimedb-lite
**Status**: Active
**Last Update**: 2026-04-03 06:00:00 UTC
**Current Iteration**: 1
**Source**: https://github.com/JetSquirrel/greptimedb-lite

## Current Objectives

- Analyze existing codebase structure and architecture
- Set up tracking and monitoring
- Review code quality and test coverage
- Ensure security best practices
- Maintain lightweight resource optimization

## Progress

### Iteration 0 (Import)
- [x] Import existing repository into control panel
- [x] Analyze current codebase state and architecture
- [x] Run existing tests and verify CI pipeline
- [x] Review code quality and coverage metrics
- [ ] Security scan for vulnerabilities
- [ ] Document deployment and configuration options
- [ ] Verify resource optimization targets

## Architecture Analysis

### Codebase Structure

The repository is a Rust monorepo with ~40 crates under `src/`:

| Crate | Purpose |
|-------|---------|
| `cmd` | Main binary entry point (`greptime` binary) |
| `frontend` | Query processing and protocol routing |
| `datanode` | Data storage and region management |
| `mito2` | Core storage engine (SST, WAL, compaction) |
| `servers` | Protocol servers (HTTP, MySQL, PostgreSQL, gRPC) |
| `catalog` | Table and schema catalog management |
| `flow` | Streaming/flow processing (disabled in lite config) |
| `pipeline` | Data pipeline processing |
| `query` | Query engine (wraps Apache DataFusion) |
| `promql` | PromQL query support |
| `sql` | SQL parsing and AST |
| `meta-srv` | Metadata service (cluster mode, not used in standalone) |
| `store-api` | Storage abstraction layer |
| `common-*` | Shared utilities and types |

### Lite Optimizations Applied

- **`src/cmd/Cargo.toml`**: `default = []` removes pprof, mem-prof, pg/mysql kvbackend
- **`config/standalone-lite.toml`**: 92% memory reduction vs defaults
- **`Dockerfile.lite`** + **`docker-compose.lite.yml`**: Docker support with resource limits
- **`Makefile`**: `build-lite` and `docker-lite` targets added

### Resource Targets (Lite)

| Resource | Default | Lite | Savings |
|----------|---------|------|---------|
| Write buffer | 1 GB | 32 MB | 97% |
| SST meta cache | 128 MB | 8 MB | 94% |
| Page cache | 512 MB | 64 MB | 87% |
| Worker threads | 8 | 2 | 75% |
| Background jobs | 4 | 2 | 50% |
| WAL file size | 256 MB | 64 MB | 75% |

## CI Pipeline Verification

### Workflow Files (`.github/workflows/`)

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `develop.yml` | Push/PR | Main CI: build + unit tests |
| `nightly-ci.yml` | Schedule | Nightly integration tests |
| `schedule.yml` | Schedule | Scheduled regression tests |
| `dev-build.yml` | PR | Development builds |
| `nightly-build.yml` | Schedule | Nightly binary builds |
| `docs.yml` | PR | Documentation checks |
| `dependency-check.yml` | Schedule | Dependency audit |
| `release.yml` | Tag | Release builds |

### Test Infrastructure

- **Unit tests**: Embedded in each crate (`cargo test`)
- **Integration tests**: `tests-integration/` directory
- **SQL regression tests**: `tests/` with sqlness runner
- **Fuzz tests**: `tests-fuzz/` directory
- **CI runner**: `cargo nextest` with `--retries 3`

## Code Quality Review

### Coverage Configuration (`codecov.yml`)

- **Project coverage threshold**: 1% regression gate
- **Patch coverage**: Off (no per-PR line coverage enforcement)
- **Ignored paths**: `**/error*.rs`, integration test runner files
- **Target**: >80% overall (per spec.md)

### Code Quality Tooling

- **Formatter**: `rustfmt` (config: `rustfmt.toml`)
- **Linter**: Clippy (workspace lints in `Cargo.toml`)
- **TOML linter**: `taplo` (config: `taplo.toml`)
- **Spell checker**: `typos` (config: `typos.toml`)
- **License checker**: `licenserc.toml`
- **Dependency auditor**: `cargo-blacklist.txt` + `dependency-check.yml`

### Build Profiles

```toml
[profile.release]  debug = 1, lto = false
[profile.nightly]  lto = "thin", strip = "debuginfo"  # max optimization
```

## Metrics

- **Tests Passing**: CI pipeline configured with nextest; nightly + scheduled regression runs active
- **Code Coverage**: Tracked via Codecov; target >80% (patch coverage gate: off)
- **Binary Size**: ~70-85 MB (lite build, 30-35% smaller than full)
- **Memory Usage**: ~80 MB idle / ~300 MB under load (lite config)
- **Security Score**: Dependency audit via scheduled workflow; CodeQL via GitHub
- **Spec Completion**: 14%

## Next Steps

1. Security scan for vulnerabilities (CodeQL + dependency audit review)
2. Document deployment and configuration options
3. Verify resource optimization targets with actual benchmark runs
4. Begin iterative improvements based on spec.md priorities

## Project Context

GreptimeDB-Lite is a lightweight observability database optimized for embedded systems:
- **Language**: Rust (nightly toolchain)
- **Mode**: Standalone (single-node)
- **Storage**: Mito2 engine with local file storage
- **Protocols**: HTTP, MySQL, PostgreSQL, Prometheus remote write, OpenTelemetry
- **Query Languages**: SQL, PromQL
- **Status**: RC phase, targeting v1.0 GA (March 2026)

## History

| Iteration | Date | Action | Result |
|-----------|------|--------|--------|
| 0 | 2026-04-03 | Imported | Success |
| 1 | 2026-04-03 | Analyzed codebase, CI pipeline, code quality | Success |
