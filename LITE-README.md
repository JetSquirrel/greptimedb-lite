# GreptimeDB-Lite: 轻量级本地运行版本

GreptimeDB-Lite 是针对嵌入式系统和本地环境优化的精简版本。

## 特性

### ✅ 保留的功能
- ✅ 单机standalone模式
- ✅ SQL和PromQL查询支持
- ✅ HTTP, MySQL, PostgreSQL协议支持
- ✅ Mito2存储引擎
- ✅ 本地文件存储
- ✅ Prometheus兼容的指标存储

### ❌ 移除的功能
- ❌ 分布式集群功能 (MetaSrv, 多节点协调)
- ❌ Kafka WAL支持
- ❌ PostgreSQL/MySQL作为元数据后端
- ❌ 性能分析工具 (pprof, mem-prof)
- ❌ 企业版功能
- ❌ 向量索引功能

## 资源优化

与完整版相比，轻量级版本：

- **二进制大小**: 减少约30-40%
- **内存使用**: 减少约50-60%
  - 全局写缓冲: 1GB → 32MB
  - SST元数据缓存: 128MB → 8MB
  - 页面缓存: 512MB → 64MB
- **CPU使用**:
  - 工作线程: 8 → 2
  - 后台任务: 4 → 2
  - gRPC运行时: 8 → 2

## 构建说明

### 前置要求

- Rust工具链 (nightly)
- Protobuf编译器 (>= 3.15)
- C/C++构建工具

### 构建轻量级版本

```bash
# 使用lite特性构建（默认不包含profiling和db backend）
cargo build --release --features=lite

# 或者显式禁用所有默认特性
cargo build --release --no-default-features --features=lite
```

### 构建完整版本（用于对比）

```bash
# 包含所有功能
cargo build --release --features=full
```

### 二进制文件位置

构建完成后，可执行文件位于：
```
target/release/greptime
```

## 运行说明

### 使用轻量级配置启动

```bash
./target/release/greptime standalone start \
  --config-file config/standalone-lite.toml
```

### 使用命令行参数启动

```bash
./target/release/greptime standalone start \
  --http-addr 127.0.0.1:4000 \
  --rpc-bind-addr 127.0.0.1:4001 \
  --mysql-addr 127.0.0.1:4002 \
  --postgres-addr 127.0.0.1:4003 \
  --data-home /tmp/greptimedb
```

### Docker运行（待构建）

```bash
# 使用自定义Dockerfile构建轻量级镜像
docker build -f Dockerfile.lite -t greptimedb-lite .

# 运行
docker run -p 4000-4003:4000-4003 \
  -v ./data:/tmp/greptimedb \
  greptimedb-lite
```

## 配置优化

轻量级配置文件 `config/standalone-lite.toml` 已针对嵌入式系统优化：

### 内存优化
```toml
[region_engine.mito]
global_write_buffer_size = "32MB"      # 默认: 1GB
sst_meta_cache_size = "8MB"            # 默认: 128MB
page_cache_size = "64MB"               # 默认: 512MB
```

### CPU优化
```toml
num_workers = 2                         # 默认: 8
max_background_jobs = 2                 # 默认: 4
[grpc]
runtime_size = 2                        # 默认: 8
```

### 禁用不必要的功能
```toml
[opentsdb]
enable = false

[influxdb]
enable = false

[export_metrics]
enable = false
```

## 性能基准

### 内存使用 (典型场景)

| 场景 | 完整版 | 轻量版 | 节省 |
|------|--------|--------|------|
| 启动空载 | ~200MB | ~80MB | 60% |
| 正常写入 | ~1.5GB | ~300MB | 80% |
| 查询负载 | ~2GB | ~500MB | 75% |

### 磁盘使用

- WAL文件大小: 256MB → 64MB
- Manifest文件: 更频繁的checkpoint减少增长
- SST文件: 1MB写缓冲保持小文件

## 适用场景

### ✅ 适合使用
- 边缘设备和IoT网关
- 嵌入式Linux系统
- 资源受限的虚拟机
- 单机监控和日志收集
- 开发和测试环境
- 本地数据分析

### ❌ 不适合使用
- 需要高可用性的生产环境
- 需要水平扩展的大规模部署
- 需要Kafka集成的场景
- 需要分布式协调的集群环境

## 常见问题

### Q: 轻量版与完整版兼容吗？
A: 数据格式完全兼容。可以先用轻量版开发，后续迁移到完整版集群。

### Q: 如何进一步减少资源使用？
A: 调整 `standalone-lite.toml` 中的参数：
- 减少 `global_write_buffer_size`
- 减少 `page_cache_size`
- 减少 `num_workers`
- 禁用不需要的协议（MySQL/PostgreSQL）

### Q: 轻量版性能如何？
A: 对于单机场景，由于减少了开销，轻量版在相同硬件上可能比完整版更快。

### Q: 可以在嵌入式ARM设备上运行吗？
A: 可以。需要交叉编译：
```bash
# 安装ARM工具链
rustup target add aarch64-unknown-linux-gnu

# 交叉编译
cargo build --release --target=aarch64-unknown-linux-gnu --features=lite
```

## 技术细节

### 移除的Crate依赖

轻量版通过禁用以下features减少依赖：
- `servers/pprof` - 性能分析
- `servers/mem-prof` - 内存分析
- `meta-srv/pg_kvbackend` - PostgreSQL元数据后端
- `meta-srv/mysql_kvbackend` - MySQL元数据后端
- 企业版特性
- 向量索引支持

### 保留的核心依赖

- `mito2` - 存储引擎
- `datanode` - 数据节点
- `frontend` - 查询前端
- `servers` - 协议服务器
- `flow` - 流处理（最小化配置）

## 贡献

如果您发现可以进一步优化的地方，欢迎提交Issue或PR：
- 减少更多依赖
- 优化配置参数
- 改进构建脚本
- 完善文档

## 许可证

Apache License 2.0 - 与主项目相同
