# Model Optimization P0 执行步骤

日期：2026-05-31

## 当前执行状态

| 序号 | 状态 | 操作 | 结果 |
| --- | --- | --- | --- |
| 0.1 | done | 确认用户反馈和产品修正意见 | P0 收敛为生成完整性：截断、空消息、续写、长任务输出预算。 |
| 0.2 | done | 检查当前工作区结构 | 当前目录是部署与运行时补丁工作区，不是 Open WebUI 源码仓库。 |
| 0.3 | done | 检查既有文档和部署方式 | 生产 UI 补丁通过容器运行时注入；后端生成链路不适合用同类方式直接热补丁。 |
| 0.4 | done | 输出 source-level 技术方案 | 方案写入 `docs/MODEL_OPTIMIZATION_TECH_SPEC.md`。 |
| 0.5 | done | 读取线上公开版本信息 | `/api/version` 返回 Open WebUI `0.9.5`；前端补丁版本为 `musk-webai-ui-1780157083`。 |
| 0.6 | done | 建立 Open WebUI v0.9.5 源码定位快照 | GitHub API tree 确认 upstream commit `3660bc00fd807deced3400a63bfa6db47811a3bb`，关键源码文件已抓取到临时目录用于定位。 |
| 0.7 | done | 输出可测试 P0 核心补丁包 | 新增 `source-patches/open-webui-v0.9.5/model-optimization-p0/`，包含核心模块、接入指南和单元测试。 |

## 开发执行清单

### 1. 准备源码环境

| 序号 | 状态 | 操作 | 验收 |
| --- | --- | --- | --- |
| 1.1 | done | 获取当前线上 Open WebUI 镜像对应源码版本 | 公开接口确认版本为 `0.9.5`；Open WebUI `v0.9.5` tag 对应 commit `3660bc00fd807deced3400a63bfa6db47811a3bb`。 |
| 1.2 | pending | 建立开发分支 `feature/model-optimization-p0` | 分支只包含模型优化 P0，不混入 UI 改版。 |
| 1.3 | pending | 跑通本地 Open WebUI 后端和前端 | 可以本地发送一条普通聊天并看到 assistant 消息落库。 |
| 1.4 | done | 定位 chat completion 请求入口 | `backend/open_webui/main.py:/api/chat/completions` 创建消息与 metadata；`utils/chat.py` 分发到 OpenAI/Ollama。 |
| 1.5 | done | 定位 stream chunk 消费位置 | `backend/open_webui/utils/middleware.py:streaming_chat_response_handler` 解析 SSE、累积 `content/output/usage`。 |
| 1.6 | done | 定位 assistant message 保存位置 | `Chats.upsert_message_to_chat_by_id_and_message_id` 在 `models/chats.py`，最终保存发生在 `middleware.py`。 |
| 1.7 | done | 定位上下文拼装位置 | `utils/middleware.py:process_chat_payload` 从 DB 加载历史，并已有 `assistant_message_id` 继续生成基础链路。 |

### 2. 新增独立模块骨架

| 序号 | 状态 | 操作 | 验收 |
| --- | --- | --- | --- |
| 2.1 | partial | 新建后端模块 `model_optimization` | 补丁包中已提供 `backend/open_webui/model_optimization/generation_integrity.py`，待复制到完整源码并接 hook。 |
| 2.2 | pending | 新增 feature flag 配置 | 所有开关默认关闭。 |
| 2.3 | done | 定义 `GenerationTrace` 数据结构 | 已在补丁包核心模块实现，可记录 request、stream、usage、persist 状态。 |
| 2.4 | done | 定义 `GenerationResult` 状态枚举 | 已实现为 `GenerationStatus: complete / incomplete / failed / empty`。 |
| 2.5 | pending | 接入 `beforeModelCall` 空实现 | 关闭开关时行为与原系统一致。 |
| 2.6 | pending | 接入 `onStreamChunk` 空实现 | 关闭开关时不影响 stream。 |
| 2.7 | pending | 接入 `beforeMessagePersist` 空实现 | 关闭开关时不影响消息保存。 |

### 3. GenerationObserver

| 序号 | 状态 | 操作 | 验收 |
| --- | --- | --- | --- |
| 3.1 | done | 每次模型调用生成 `request_trace_id` | `GenerationTrace.from_metadata` 已实现。 |
| 3.2 | done | 记录模型、provider、max_tokens | `GenerationTrace` 字段已实现。 |
| 3.3 | done | 记录 stream started / first chunk / last chunk | `observe_openai_stream_event` 已实现。 |
| 3.4 | done | 记录 stream 累计文本长度 | `stream_text_length` 已实现并有测试。 |
| 3.5 | done | 记录 finish_reason 和 usage | `finish_reason / usage` 解析已实现并有测试。 |
| 3.6 | pending | 新增日志持久化 | 优先独立表；短期可落 metadata 或结构化日志。 |
| 3.7 | pending | 加单元测试 | 正常、截断、中断、空响应都有日志。 |

### 4. EmptyMessageGuard

| 序号 | 状态 | 操作 | 验收 |
| --- | --- | --- | --- |
| 4.1 | done | 定义空 assistant 判断函数 | `is_empty_assistant_message` 已实现。 |
| 4.2 | done | 排除 tool call / 文件 / error payload 误伤 | 已覆盖 tool call 测试。 |
| 4.3 | pending | 保存前标记 `generation_status=empty` 或 `failed` | 空消息不成为普通 assistant 正文。 |
| 4.4 | pending | 上下文拼装跳过 empty 消息 | 后续对话不引用空 assistant。 |
| 4.5 | pending | 前端不展示空 assistant 气泡 | 用户看不到只有模型名和时间的空消息。 |
| 4.6 | pending | 加回归测试 | 共享案例中 23:06 空 assistant 不再展示、不入上下文。 |

### 5. TruncationDetector

| 序号 | 状态 | 操作 | 验收 |
| --- | --- | --- | --- |
| 5.1 | done | 实现强信号检测 | `finish_reason=length`、stream 异常、保存短于 stream 已实现。 |
| 5.2 | done | 实现弱信号检测 | 未闭合 code/table、半句结尾、语义尾巴已实现。 |
| 5.3 | done | 合并判断输出 `generation_status` | `build_message_generation_patch` 输出前端字段和 metadata 字段。 |
| 5.4 | pending | 写入 message metadata | 前端可读取 `incomplete` 和 `can_continue`。 |
| 5.5 | pending | 日志记录 `truncation_reasons` | 能解释为什么判定为 incomplete。 |
| 5.6 | pending | 加测试 fixture | 用 `API网关...统一路由、限` 这类半句结尾做回归。 |

### 6. TokenBudgetManager

| 序号 | 状态 | 操作 | 验收 |
| --- | --- | --- | --- |
| 6.1 | done | 实现长任务关键词识别 | `详细说明 / 技术架构 / 数据库设计` 已覆盖测试。 |
| 6.2 | pending | 读取模型上下文窗口 | 有配置用配置，无配置用保守 fallback。 |
| 6.3 | pending | 计算 reserved output tokens | 长任务至少预留 8k 输出预算。 |
| 6.4 | pending | 尊重用户显式高级设置 | 用户手动设置 max_tokens 时不强行覆盖。 |
| 6.5 | pending | 接入 beforeModelCall | 只改模型请求参数，不改业务消息结构。 |
| 6.6 | pending | 加边界测试 | 小窗口模型不会因预算计算导致负数或请求失败。 |

### 7. ContinuationManager

| 序号 | 状态 | 操作 | 验收 |
| --- | --- | --- | --- |
| 7.1 | pending | 新增继续生成后端接口 | `POST /api/chat/messages/{message_id}/continue` 可用。 |
| 7.2 | pending | 校验消息归属和权限 | 用户只能续写自己可访问的 assistant 消息。 |
| 7.3 | pending | 读取原消息 tail 500-1000 字 | 续写有中断点上下文。 |
| 7.4 | done | 生成 continuation prompt | `build_continuation_instruction` 已实现。 |
| 7.5 | pending | 写入 `continuation_parent_id` 和 `continuation_index` | 可追踪多次续写。 |
| 7.6 | pending | 防重复检测 | 续写开头与原尾部高度重复时提示或裁剪。 |
| 7.7 | pending | 加接口测试 | 截断消息可续写，完整消息默认不显示续写入口。 |

### 8. 前端最小改动

| 序号 | 状态 | 操作 | 验收 |
| --- | --- | --- | --- |
| 8.1 | pending | message 渲染读取 `generation_status` | incomplete 状态可展示提示。 |
| 8.2 | pending | 新增轻量 `GenerationStatus` 组件 | 展示「回答可能未完成」和「继续生成」。 |
| 8.3 | pending | 接入继续生成 API client | 点击后触发 continuation 请求。 |
| 8.4 | pending | loading 与普通发送状态分离 | 继续生成中不污染当前输入框发送状态。 |
| 8.5 | pending | 空 assistant 不渲染 | 页面无空气泡。 |
| 8.6 | pending | 移动端检查 | 390px 下提示和按钮不挤压正文。 |

### 9. 回归测试

| 序号 | 状态 | 操作 | 验收 |
| --- | --- | --- | --- |
| 9.1 | pending | 构造共享案例 fixture | 包含法务、燃气灶、孕动冒险、后端架构多个话题。 |
| 9.2 | pending | 跑最终问题回归 | 能识别 APP 是「孕动冒险」。 |
| 9.3 | pending | 检查回答完整性 | 覆盖架构、数据库、权限、通知、调度、部署。 |
| 9.4 | pending | 模拟截断 | 显示 incomplete，不当作 complete。 |
| 9.5 | pending | 点击继续生成 | 从中断点续写，不重复前文。 |
| 9.6 | pending | 检查分享页 | 分享页不展示空消息，能显示续写后的内容。 |

### 10. 灰度上线

| 序号 | 状态 | 操作 | 验收 |
| --- | --- | --- | --- |
| 10.1 | pending | 测试环境开启 Observer | 日志正常，无行为变化。 |
| 10.2 | pending | 小流量开启 EmptyMessageGuard | 空消息率下降，无 tool call 误伤。 |
| 10.3 | pending | 小流量开启 TruncationDetector | incomplete 判定准确，无大量误报。 |
| 10.4 | pending | 小流量开启继续生成 | 点击成功率可观测。 |
| 10.5 | pending | 开启动态 max_tokens | 长任务截断率下降。 |
| 10.6 | pending | 生产回滚演练 | 关闭 feature flags 后恢复原行为。 |

## 当前工作区限制

本工作区只有部署脚手架、运行时 UI 补丁和文档，没有 Open WebUI 后端/前端源码。因此本轮不能安全完成 source-level 代码实现，也不建议直接对生产容器 Python/JS 文件做不可追踪热改。

后续进入代码实现，需要切换到完整 Open WebUI 源码仓库，或先把线上镜像对应版本源码拉取为开发基线。

## 2026-05-31 P0 核心补丁包进展

已新增：

```text
source-patches/open-webui-v0.9.5/model-optimization-p0/
```

包含：

- `generation_integrity.py`：P0 核心逻辑。
- `PATCH_GUIDE.md`：Open WebUI v0.9.5 真实接入点和 wiring 指南。
- `test_generation_integrity.py`：11 条单元测试。

已验证：

```text
python3 -m unittest discover -s source-patches/open-webui-v0.9.5/model-optimization-p0/tests/model_optimization
Ran 11 tests OK

PYTHONPYCACHEPREFIX=/private/tmp/openwebui-pycache python3 -m py_compile source-patches/open-webui-v0.9.5/model-optimization-p0/backend/open_webui/model_optimization/generation_integrity.py
OK
```
