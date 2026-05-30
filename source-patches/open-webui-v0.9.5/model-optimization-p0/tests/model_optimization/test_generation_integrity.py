import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
sys.path.insert(0, str(BACKEND))

from open_webui.model_optimization.generation_integrity import (  # noqa: E402
    GenerationStatus,
    GenerationTrace,
    apply_dynamic_max_tokens,
    build_continuation_instruction,
    build_message_generation_patch,
    build_truncation_diagnosis,
    is_empty_assistant_message,
    observe_openai_stream_event,
)


class GenerationIntegrityTests(unittest.TestCase):
    def test_empty_assistant_message(self):
        message = {"role": "assistant", "content": "   ", "done": True}
        self.assertTrue(is_empty_assistant_message(message))

    def test_tool_message_is_not_empty(self):
        message = {"role": "assistant", "content": "", "tool_calls": [{"id": "x"}]}
        self.assertFalse(is_empty_assistant_message(message))

    def test_finish_reason_length_marks_incomplete(self):
        diagnosis = build_truncation_diagnosis(
            content="API gateway controls unified routing, rate",
            finish_reason="length",
        )
        self.assertEqual(diagnosis.status, GenerationStatus.INCOMPLETE)
        self.assertTrue(diagnosis.can_continue)

    def test_half_sentence_tail_marks_incomplete_with_multiple_weak_signals(self):
        diagnosis = build_truncation_diagnosis(content="API gateway: unified routing,")
        self.assertEqual(diagnosis.status, GenerationStatus.INCOMPLETE)

    def test_chinese_half_tail_marks_incomplete(self):
        diagnosis = build_truncation_diagnosis(content="API网关负责统一路由、限")
        self.assertEqual(diagnosis.status, GenerationStatus.INCOMPLETE)
        self.assertIn("chinese_tail_fragment", diagnosis.reasons)

    def test_unclosed_code_fence_marks_incomplete_for_long_task(self):
        diagnosis = build_truncation_diagnosis(content="```python\nprint('hello')")
        self.assertEqual(diagnosis.status, GenerationStatus.INCOMPLETE)
        self.assertIn("unclosed_code_fence", diagnosis.reasons)

    def test_stream_length_mismatch_marks_incomplete(self):
        diagnosis = build_truncation_diagnosis(
            content="short",
            stream_text_length=100,
            saved_message_length=5,
        )
        self.assertEqual(diagnosis.status, GenerationStatus.INCOMPLETE)

    def test_observe_stream_event_tracks_finish_reason_and_usage(self):
        trace = GenerationTrace.from_metadata({"chat_id": "c1", "message_id": "m1"})
        observe_openai_stream_event(
            trace,
            {"choices": [{"delta": {"content": "hello "}, "finish_reason": None}]},
        )
        observe_openai_stream_event(
            trace,
            {
                "choices": [{"delta": {"content": "world"}, "finish_reason": "length"}],
                "usage": {"prompt_tokens": 10, "completion_tokens": 20, "total_tokens": 30},
            },
        )
        self.assertEqual(trace.stream_text_length, 11)
        self.assertEqual(trace.finish_reason, "length")
        self.assertEqual(trace.total_tokens, 30)

    def test_generation_patch_contains_frontend_fields(self):
        trace = GenerationTrace.from_metadata({"chat_id": "c1", "message_id": "m1"})
        trace.finish_reason = "length"
        patch = build_message_generation_patch(trace, content="cut off,")
        self.assertEqual(patch["generation_status"], "incomplete")
        self.assertTrue(patch["can_continue"])
        self.assertIn("generation", patch)

    def test_dynamic_max_tokens_long_task(self):
        import os

        old = os.environ.get("ENABLE_DYNAMIC_MAX_TOKENS")
        os.environ["ENABLE_DYNAMIC_MAX_TOKENS"] = "true"
        try:
            payload = {
                "messages": [
                    {"role": "user", "content": "这个APP的后端技术架构和数据库设计方案能详细说明一下吗？"}
                ]
            }
            updated = apply_dynamic_max_tokens(payload, context_window=32000)
            self.assertEqual(updated["max_tokens"], 8192)
        finally:
            if old is None:
                os.environ.pop("ENABLE_DYNAMIC_MAX_TOKENS", None)
            else:
                os.environ["ENABLE_DYNAMIC_MAX_TOKENS"] = old

    def test_dynamic_max_tokens_respects_explicit_setting(self):
        import os

        old = os.environ.get("ENABLE_DYNAMIC_MAX_TOKENS")
        os.environ["ENABLE_DYNAMIC_MAX_TOKENS"] = "true"
        try:
            payload = {
                "max_tokens": 1234,
                "messages": [{"role": "user", "content": "完整方案"}],
            }
            updated = apply_dynamic_max_tokens(payload)
            self.assertEqual(updated["max_tokens"], 1234)
        finally:
            if old is None:
                os.environ.pop("ENABLE_DYNAMIC_MAX_TOKENS", None)
            else:
                os.environ["ENABLE_DYNAMIC_MAX_TOKENS"] = old

    def test_continuation_instruction(self):
        prompt = build_continuation_instruction(
            assistant_tail="API gateway controls unified routing, rate",
            active_task="Explain backend architecture",
        )
        self.assertIn("Do not repeat", prompt)
        self.assertIn("Explain backend architecture", prompt)


if __name__ == "__main__":
    unittest.main()
