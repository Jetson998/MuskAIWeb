# Open WebUI 思考过程展示问题归因与方案

日期：2026-05-28

## 现象

在 Open WebUI 中使用 `claude-opus-4-6` 时，即使在对话高级设置里将 `Reasoning Effort` 设置为 `high`，页面仍不显示“思考过程 / Thinking”区块。

## 归因

问题不在 Open WebUI 前端展示，也不是品牌、提示词卡片或页面补丁导致。

Open WebUI 本身支持以下 reasoning / thinking 展示格式：

- `<think>...</think>`
- `<thinking>...</thinking>`
- `<reasoning>...</reasoning>`
- `reasoning_content`
- `thinking`
- `reasoning`

实测当前三方接口 `https://api.muskapis.com/v1`：

- `/chat/completions` 非流式响应只有 `message.content`
- `/chat/completions` 流式响应只有 `delta.content`
- `/v1/messages` Anthropic 原生风格响应只有 `type: text`
- `usage.completion_tokens_details.reasoning_tokens = 0`

虽然接口接受了 `thinking` 参数，并返回模型名 `claude-opus-4-6-thinking`，但没有实际返回 `thinking` / `reasoning_content` / `reasoning` 字段。因此 Open WebUI 没有可展示的数据。

## 方案对比

### 方案 1：让中转接口透传 reasoning 字段

最正规方案。要求三方中转将 Claude thinking summary 映射为 Open WebUI 能识别的字段，例如：

```json
{
  "delta": {
    "reasoning_content": "..."
  }
}
```

或：

```json
{
  "message": {
    "reasoning_content": "..."
  }
}
```

优点是真实 API 级 thinking；缺点是依赖供应商或中转实现。

### 方案 2：Open WebUI Pipe 适配模型

新增独立 Pipe 模型 `claude_opus_4_6_thinking_adapter`，调用原 `claude-opus-4-6`，并要求模型在正式回答前输出：

```xml
<thinking>简短推理摘要</thinking>
```

Open WebUI 会把该标签解析成 Thinking 区块。

优点是影响面小、可控、无需替换原模型；缺点是这是“高层推理摘要”，不是供应商返回的隐藏 thinking。

### 方案 3：全局提示词强制输出 thinking 标签

不推荐。会污染所有模型输出，影响面大。

## 当前执行策略

采用方案 2，新增独立测试模型：

- 模型 ID：`claude_opus_4_6_thinking_adapter`
- 模型名：`claude-opus-4-6 思考摘要适配`
- 行为：先输出中文 `<thinking>...</thinking>` 高层推理摘要，再输出正式回答
- 不覆盖原 `claude-opus-4-6`
