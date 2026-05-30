# Model Optimization P0 接入指南

日期：2026-05-31

## 1. 已确认的 Open WebUI v0.9.5 接入点

后端：

```text
backend/open_webui/main.py
backend/open_webui/utils/middleware.py
backend/open_webui/utils/chat.py
backend/open_webui/routers/openai.py
backend/open_webui/models/chats.py
```

前端：

```text
src/lib/components/chat/Chat.svelte
src/lib/components/chat/Messages/ResponseMessage.svelte
src/lib/apis/streaming/index.ts
```

关键链路：

1. `main.py:/api/chat/completions`
   - 创建 user message。
   - 创建空 assistant placeholder。
   - 设置 `metadata.chat_id / metadata.message_id / metadata.assistant_message_id`。

2. `utils/middleware.py:process_chat_payload`
   - 从 DB 加载历史消息。
   - `assistant_message_id` 已用于继续生成，说明 Open WebUI 已有续写基础链路。

3. `utils/middleware.py:streaming_chat_response_handler`
   - 读取 provider SSE。
   - 累积 `content / output / usage`。
   - 最终保存 assistant message。
   - 发出 `chat:completion` done 事件。

4. `utils/middleware.py:non_streaming_chat_response_handler`
   - 处理非流式返回。
   - 保存 assistant message。

5. `Chat.svelte:chatCompletionEventHandler`
   - 前端消费 `chat:completion` 事件。
   - `done` 后将 message 标记完成。

6. `Chat.svelte:continueResponse`
   - 前端已有继续生成入口。
   - 会把 `assistant_message_id` 发给后端。

## 2. 最小接入策略

先复制核心模块：

```text
source-patches/open-webui-v0.9.5/model-optimization-p0/backend/open_webui/model_optimization/
```

到源码仓库：

```text
backend/open_webui/model_optimization/
```

### 2.1 middleware.py 引入模块

在 `backend/open_webui/utils/middleware.py` 顶部增加：

```python
from open_webui.model_optimization.generation_integrity import (
    GenerationTrace,
    apply_dynamic_max_tokens,
    build_message_generation_patch,
    build_stream_completion_event,
    build_truncation_diagnosis,
    build_continuation_instruction,
    observe_openai_stream_event,
)
```

### 2.2 process_chat_payload 动态输出预算

在 `process_chat_payload` 完成 `form_data` 基础处理后，调用：

```python
form_data = apply_dynamic_max_tokens(form_data)
```

验收：

- 用户没有显式设置 `max_tokens` 时，长任务可自动提高输出预算。
- 用户显式设置过 token 参数时不覆盖。

### 2.3 continuation 续写提示增强

Open WebUI v0.9.5 已有：

```python
assistant_message_id = metadata.get('assistant_message_id')
```

在加载 `assistant_message` 后，如果是继续生成，追加一个 user instruction：

```python
tail = assistant_message.get('content', '')[-1000:]
form_data['messages'].append(
    {
        'role': 'user',
        'content': build_continuation_instruction(
            assistant_tail=tail,
            active_task=metadata.get('user_prompt', ''),
        ),
    }
)
```

注意：

- 不新增普通问答。
- 不重复已输出内容。
- 仍然使用原 assistant message id 保存续写结果。

### 2.4 streaming observer

在 `streaming_chat_response_handler` 初始化 `content/output/usage` 之后创建：

```python
generation_trace = GenerationTrace.from_metadata(metadata, model=model)
```

在每个 provider SSE JSON 解析后调用：

```python
observe_openai_stream_event(generation_trace, data)
```

在最终保存前构造：

```python
final_content = serialize_output(output)
generation_patch = build_message_generation_patch(
    generation_trace,
    content=final_content,
    output=output,
    usage=usage,
)
```

保存消息时合并：

```python
{
    'done': True,
    'content': final_content,
    'output': output,
    **({'usage': usage} if usage else {}),
    **generation_patch,
}
```

done event 也合并：

```python
data = {
    'done': True,
    'content': final_content,
    'output': output,
    'title': title,
    **({'usage': usage} if usage else {}),
    **build_stream_completion_event(generation_patch),
}
```

### 2.5 non-streaming observer

在 `non_streaming_chat_response_handler` 保存前：

```python
diagnosis = build_truncation_diagnosis(
    content=content,
    finish_reason=response_data.get('choices', [{}])[0].get('finish_reason'),
    usage=usage,
)
generation_patch = build_message_generation_patch(
    trace=None,
    content=content,
    output=response_output,
    usage=usage,
    diagnosis=diagnosis,
)
```

保存与事件合并 `generation_patch`。

### 2.6 空 assistant 过滤

Open WebUI 目前会先创建空 assistant placeholder。不要阻止 placeholder 创建，否则会破坏前端生成态。

P0 正确策略：

1. placeholder 可以存在，`done=False`。
2. 最终完成时如果 content 仍为空，保存：

```text
generation_status=empty
can_continue=false
done=true
```

3. 前端不展示已完成且 empty 的 assistant 气泡。
4. P1 上下文拼装跳过 empty/failed empty。

### 2.7 前端展示

在 `Chat.svelte:chatCompletionEventHandler` 中消费：

```ts
const {
  generation_status,
  generation_reasons,
  can_continue
} = data;
```

写入 message：

```ts
if (generation_status) message.generation_status = generation_status;
if (generation_reasons) message.generation_reasons = generation_reasons;
if (can_continue !== undefined) message.can_continue = can_continue;
```

在 `ResponseMessage.svelte` 的底部操作区上方展示轻提示：

```svelte
{#if message?.generation_status === 'incomplete' && message?.can_continue}
  <div class="mt-2 text-xs text-gray-500">
    回答可能未完成
    <button on:click={() => continueResponse()}>继续生成</button>
  </div>
{/if}
```

保留原有 `Continue Response` 按钮，但 incomplete 提示要更明确。

## 3. 验收用例

共享案例最终问题：

```text
这个APP的后端技术架构和数据库设计方案能详细说明一下吗？
```

必须满足：

- 识别 APP 是「孕动冒险」。
- 不出现空 assistant 完成态气泡。
- 如果 `finish_reason=length`，消息为 `generation_status=incomplete`。
- 如果最后一句停在 `统一路由、限` 等半句，也标记 incomplete。
- 点击继续生成后，从原回答末尾续写，不重答整篇。
