# GreptimeDB-Lite 裁剪版 Roadmap

## 现状回顾
- 已裁剪：移除分布式角色（MetaSrv、多节点）、Kafka WAL、外置元数据后端、pprof/mem-prof、企业版与向量索引，聚焦单机 `standalone`。
- 资源优化：`standalone-lite.toml` 将写缓冲/缓存从 GB 级降到几十 MB，线程池降到 1~2 级别；`make build-lite`、`Dockerfile.lite`、`docker-compose.lite.yml` 支持低资源构建与运行。
- 兼容性：数据格式与上游保持一致，可在同一二进制上通过 feature 选择 full/lite。

## 目标
- 交付可发布的 Lite 发行物（本地和 Docker），保持与上游存储/协议兼容。
- 将启动内存控制在 <500MB，二进制维持 <90MB，并持续跟踪尺寸。
- 保留核心查询/写入路径的稳定性，提供最小化的自动化回归验证。

## 阶段计划（裁剪路线）
- **P0 基线（当前）**
  - 完成裁剪范围与配置收敛（已具备 `standalone-lite.toml`、构建目标、运行指南）。
  - 建立手工冒烟流程：`make build-lite && ./target/release/greptime standalone start --config-file config/standalone-lite.toml`，确认 HTTP/MySQL/PG 入口可用。
- **P1 稳定化（短期）**
  - 在 CI 中增加 `make build-lite` + 简单读写冒烟（基于本地存储）以防回归。
  - 引入二进制尺寸与内存预算检查（失败即标红），沉淀到发布检查单。
  - 完善 Docker Lite 构建与运行示例，产出首个 Lite 预览包。
- **P2 深化裁剪（中期）**
  - 针对嵌入式/ARM 设备的交叉构建与限压配置预设（128MB/512MB 档）。
  - 优先回移上游针对 Mito/存储引擎的性能与稳定性修复。
  - 补充 Lite 特有文档：配置模板、常见问题、资源评估指引。
- **持续项**
  - 按上游发布节奏同步关键修复，保持协议/存储兼容。
  - 定期评估裁剪收益（尺寸、内存、CPU）并更新基线。

## 上游跟进机制
1. **Release 监听**：Agent 订阅 `GreptimeTeam/greptimedb` 发布（release/tag）与每周一次的 `main` 变更摘要。
2. **变更筛选**：优先关注与 Lite 相关的类别——存储/查询 bugfix、安全修复、协议兼容；忽略分布式、Flow、企业特性等已裁剪模块。
3. **自动 cherry-pick 流程**：
   - Agent 从最新 Lite 分支创建同步分支，对应上游 tag/commit 列表逐个 `cherry-pick`.
   - 可直接合并的提交：在分支上运行 `make build-lite` + 冒烟，生成 PR。
4. **冲突/不可直接合并的提交**：
   - Agent 记录冲突点（通常涉及已移除模块），按 Lite 范围做最小改造后再跑冒烟。
   - 若改造超出 Lite 范围（依赖分布式/外部后端），标注为“跳过/手工评估”并附原因。
5. **可追踪性**：在 PR 描述中列出已合入/跳过的上游提交及验证结果，便于回溯。
