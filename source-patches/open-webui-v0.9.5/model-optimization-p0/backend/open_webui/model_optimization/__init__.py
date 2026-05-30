"""Model optimization hooks for Musk WebAI."""

from .generation_integrity import (
    GenerationDiagnosis,
    GenerationStatus,
    GenerationTrace,
    apply_dynamic_max_tokens,
    build_continuation_instruction,
    build_message_generation_patch,
    build_stream_completion_event,
    build_truncation_diagnosis,
    is_empty_assistant_message,
    observe_openai_stream_event,
)

__all__ = [
    "GenerationDiagnosis",
    "GenerationStatus",
    "GenerationTrace",
    "apply_dynamic_max_tokens",
    "build_continuation_instruction",
    "build_message_generation_patch",
    "build_stream_completion_event",
    "build_truncation_diagnosis",
    "is_empty_assistant_message",
    "observe_openai_stream_event",
]
