"""Generation integrity helpers for Musk WebAI.

This module is designed as a small, source-level hook layer for Open WebUI
v0.9.5. It contains no database or FastAPI dependencies so it can be tested
independently before being wired into the chat pipeline.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
import os
import re
import time
from typing import Any, Optional
from uuid import uuid4


class GenerationStatus(str, Enum):
    COMPLETE = "complete"
    INCOMPLETE = "incomplete"
    FAILED = "failed"
    EMPTY = "empty"


@dataclass
class GenerationDiagnosis:
    status: GenerationStatus
    reasons: list[str] = field(default_factory=list)
    can_continue: bool = False


@dataclass
class GenerationTrace:
    request_trace_id: str
    chat_id: Optional[str] = None
    message_id: Optional[str] = None
    user_id: Optional[str] = None
    model: Optional[str] = None
    provider: Optional[str] = None
    max_tokens: Optional[int] = None
    prompt_tokens: Optional[int] = None
    completion_tokens: Optional[int] = None
    total_tokens: Optional[int] = None
    finish_reason: Optional[str] = None
    stream_started_at: float = field(default_factory=time.time)
    first_chunk_at: Optional[float] = None
    last_chunk_at: Optional[float] = None
    stream_interrupted: bool = False
    stream_text_length: int = 0
    chunk_count: int = 0

    @classmethod
    def from_metadata(
        cls,
        metadata: Optional[dict[str, Any]] = None,
        model: Optional[dict[str, Any]] = None,
        payload: Optional[dict[str, Any]] = None,
    ) -> "GenerationTrace":
        metadata = metadata or {}
        payload = payload or {}
        model = model or {}
        return cls(
            request_trace_id=str(uuid4()),
            chat_id=metadata.get("chat_id"),
            message_id=metadata.get("message_id"),
            user_id=metadata.get("user_id"),
            model=payload.get("model") or model.get("id"),
            provider=model.get("owned_by"),
            max_tokens=_coerce_int(payload.get("max_tokens") or payload.get("max_completion_tokens")),
        )


LONG_TASK_PATTERNS = (
    "详细说明",
    "完整方案",
    "技术架构",
    "数据库设计",
    "PRD",
    "开发步骤",
    "代码实现",
    "完整输出",
    "详细设计",
)

WEAK_INCOMPLETE_ENDINGS = (
    "包括",
    "例如",
    "分为",
    "主要有",
    "统一路由",
    "以及",
    "分别是",
)


def _env_flag(name: str, default: bool = False) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def _coerce_int(value: Any) -> Optional[int]:
    try:
        if value is None or value == "":
            return None
        return int(value)
    except (TypeError, ValueError):
        return None


def _message_text(message: dict[str, Any]) -> str:
    content = message.get("content", "")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, dict):
                parts.append(str(item.get("text") or item.get("content") or ""))
            elif isinstance(item, str):
                parts.append(item)
        return "".join(parts)
    return str(content or "")


def is_empty_assistant_message(message: dict[str, Any]) -> bool:
    if message.get("role") != "assistant":
        return False
    if _message_text(message).strip():
        return False
    if message.get("tool_calls") or message.get("files") or message.get("error"):
        return False
    output = message.get("output")
    if isinstance(output, list):
        for item in output:
            if not isinstance(item, dict):
                continue
            for part in item.get("content", []) or item.get("output", []):
                if isinstance(part, dict) and str(part.get("text", "")).strip():
                    return False
    return True


def observe_openai_stream_event(trace: GenerationTrace, data: dict[str, Any]) -> GenerationTrace:
    now = time.time()
    usage = data.get("usage") or data.get("timings") or {}
    if usage:
        trace.prompt_tokens = _coerce_int(usage.get("prompt_tokens")) or trace.prompt_tokens
        trace.completion_tokens = _coerce_int(usage.get("completion_tokens")) or trace.completion_tokens
        trace.total_tokens = _coerce_int(usage.get("total_tokens")) or trace.total_tokens

    choices = data.get("choices") or []
    if choices:
        choice = choices[0] or {}
        finish_reason = choice.get("finish_reason")
        if finish_reason:
            trace.finish_reason = finish_reason

        delta = choice.get("delta") or {}
        value = delta.get("content") or ""
        if value:
            if trace.first_chunk_at is None:
                trace.first_chunk_at = now
            trace.last_chunk_at = now
            trace.stream_text_length += len(value)
            trace.chunk_count += 1

    if data.get("type") == "response.completed":
        trace.finish_reason = trace.finish_reason or "stop"
        response_usage = (data.get("response") or {}).get("usage") or {}
        if response_usage:
            trace.prompt_tokens = _coerce_int(response_usage.get("prompt_tokens")) or trace.prompt_tokens
            trace.completion_tokens = _coerce_int(response_usage.get("completion_tokens")) or trace.completion_tokens
            trace.total_tokens = _coerce_int(response_usage.get("total_tokens")) or trace.total_tokens

    if data.get("error"):
        trace.stream_interrupted = True

    return trace


def build_truncation_diagnosis(
    *,
    content: str,
    finish_reason: Optional[str] = None,
    usage: Optional[dict[str, Any]] = None,
    stream_interrupted: bool = False,
    stream_text_length: Optional[int] = None,
    saved_message_length: Optional[int] = None,
) -> GenerationDiagnosis:
    text = (content or "").strip()
    reasons: list[str] = []

    if not text:
        return GenerationDiagnosis(GenerationStatus.EMPTY, ["empty_assistant_content"], False)

    normalized_finish_reason = (finish_reason or "").lower()
    if normalized_finish_reason in {"length", "max_tokens", "max_output_tokens"}:
        reasons.append(f"finish_reason:{normalized_finish_reason}")

    if stream_interrupted:
        reasons.append("stream_interrupted")

    if stream_text_length is not None and saved_message_length is not None:
        if stream_text_length > 0 and saved_message_length < max(1, int(stream_text_length * 0.95)):
            reasons.append("saved_message_shorter_than_stream")

    weak_reasons = _weak_truncation_reasons(text)
    reasons.extend(weak_reasons)

    strong_reasons = [
        reason
        for reason in reasons
        if reason.startswith("finish_reason:")
        or reason in {"stream_interrupted", "saved_message_shorter_than_stream"}
    ]
    if strong_reasons or "sentence_boundary_incomplete" in weak_reasons or len(weak_reasons) >= 2:
        return GenerationDiagnosis(GenerationStatus.INCOMPLETE, reasons, True)

    return GenerationDiagnosis(GenerationStatus.COMPLETE, reasons, False)


def _weak_truncation_reasons(text: str) -> list[str]:
    reasons: list[str] = []
    stripped = text.rstrip()

    if stripped.endswith(("，", "、", "：", "；", ",", ":", ";")):
        reasons.append("sentence_boundary_incomplete")

    tail = stripped[-24:]
    if any(tail.endswith(ending) for ending in WEAK_INCOMPLETE_ENDINGS):
        reasons.append("semantic_tail_incomplete")

    if stripped.count("```") % 2 == 1:
        reasons.append("unclosed_code_fence")

    table_lines = [line for line in stripped.splitlines()[-8:] if line.strip().startswith("|")]
    if len(table_lines) == 1:
        reasons.append("possibly_unclosed_markdown_table")

    if re.search(r"(第[一二三四五六七八九十]+|[0-9]+[.)、])\\s*[^\\n]{0,24}$", tail):
        reasons.append("list_item_tail_incomplete")

    return reasons


def build_message_generation_patch(
    trace: Optional[GenerationTrace],
    *,
    content: str,
    output: Optional[list[dict[str, Any]]] = None,
    usage: Optional[dict[str, Any]] = None,
    diagnosis: Optional[GenerationDiagnosis] = None,
) -> dict[str, Any]:
    if diagnosis is None:
        diagnosis = build_truncation_diagnosis(
            content=content,
            finish_reason=trace.finish_reason if trace else None,
            usage=usage,
            stream_interrupted=trace.stream_interrupted if trace else False,
            stream_text_length=trace.stream_text_length if trace else None,
            saved_message_length=len(content or ""),
        )

    patch: dict[str, Any] = {
        "generation_status": diagnosis.status.value,
        "generation_reasons": diagnosis.reasons,
        "can_continue": diagnosis.can_continue,
        "generation": {
            "status": diagnosis.status.value,
            "reasons": diagnosis.reasons,
            "can_continue": diagnosis.can_continue,
        },
    }

    if trace:
        patch["generation"].update(
            {
                "request_trace_id": trace.request_trace_id,
                "finish_reason": trace.finish_reason,
                "stream_text_length": trace.stream_text_length,
                "saved_message_length": len(content or ""),
                "chunk_count": trace.chunk_count,
                "prompt_tokens": trace.prompt_tokens,
                "completion_tokens": trace.completion_tokens,
                "total_tokens": trace.total_tokens,
                "max_tokens": trace.max_tokens,
            }
        )

    if usage:
        patch["generation"]["usage"] = usage

    return patch


def build_stream_completion_event(generation_patch: dict[str, Any]) -> dict[str, Any]:
    return {
        "generation_status": generation_patch.get("generation_status"),
        "generation_reasons": generation_patch.get("generation_reasons", []),
        "can_continue": generation_patch.get("can_continue", False),
        "generation": generation_patch.get("generation", {}),
    }


def _extract_recent_user_text(payload: dict[str, Any]) -> str:
    messages = payload.get("messages") or []
    for message in reversed(messages):
        if message.get("role") == "user":
            return _message_text(message)
    user_message = payload.get("user_message") or {}
    if isinstance(user_message, dict):
        return _message_text(user_message)
    return ""


def is_long_output_task(payload: dict[str, Any]) -> bool:
    text = _extract_recent_user_text(payload)
    return any(pattern in text for pattern in LONG_TASK_PATTERNS)


def apply_dynamic_max_tokens(
    payload: dict[str, Any],
    *,
    context_window: int = 32000,
    long_task_output_tokens: int = 8192,
    super_long_task_output_tokens: int = 12000,
) -> dict[str, Any]:
    if not _env_flag("ENABLE_DYNAMIC_MAX_TOKENS", False):
        return payload

    if payload.get("max_tokens") or payload.get("max_completion_tokens"):
        return payload

    params = payload.get("params") or {}
    if params.get("max_tokens") or params.get("max_completion_tokens"):
        return payload

    if not is_long_output_task(payload):
        return payload

    user_text = _extract_recent_user_text(payload)
    output_budget = long_task_output_tokens
    if "完整方案" in user_text or "完整输出" in user_text:
        output_budget = super_long_task_output_tokens

    safety_margin = max(1024, int(context_window * 0.05))
    max_output = max(1024, min(output_budget, context_window - safety_margin))

    return {
        **payload,
        "max_tokens": max_output,
    }


def build_continuation_instruction(
    *,
    assistant_tail: str,
    active_task: str,
    tail_limit: int = 1000,
) -> str:
    tail = (assistant_tail or "")[-tail_limit:].strip()
    task = (active_task or "").strip()
    return (
        "The previous assistant response was interrupted at this point:\n"
        f"{tail}\n\n"
        "Continue from the interruption point. Do not repeat completed content.\n"
        f"Continue the original task: {task}"
    )
