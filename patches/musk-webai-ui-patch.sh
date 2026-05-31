#!/bin/sh
set -eu

python3 - <<'PY'
from pathlib import Path
import json
import os
import re
import time

build = Path(os.environ.get('MUSK_WEBAI_BUILD_DIR', '/app/build'))
html_paths = [build / 'index.html', build / 'app.html']
version_path = build / '_app/version.json'

STYLE_IDS = (
    'musk-webai-ui-polish',
    'musk-webai-sidebar-polish',
)
SCRIPT_IDS = (
    'musk-webai-ui-runtime',
    'musk-webai-runtime-polish',
)

style = r'''
<style id="musk-webai-ui-polish">
  :root {
    --musk-bg: #ffffff;
    --musk-surface: #f7f8fa;
    --musk-surface-raised: #ffffff;
    --musk-border: #e6e9ee;
    --musk-border-strong: #d5dae3;
    --musk-text: #151923;
    --musk-text-muted: #69707d;
    --musk-text-soft: #949aa5;
    --musk-accent: #2f80ed;
    --musk-accent-soft: #e8f2ff;
    --musk-success: #16a34a;
    --musk-danger: #dc2626;
    --musk-radius-sm: 8px;
    --musk-radius-md: 12px;
    --musk-radius-lg: 18px;
    --musk-shadow-soft: 0 8px 22px rgba(20, 24, 32, 0.048);
    --musk-composer-height: 132px;
    --musk-font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC",
      "Hiragino Sans GB", "Microsoft YaHei", "Helvetica Neue", Arial, sans-serif;
    --musk-font-mono: "SFMono-Regular", "SF Mono", Consolas, "Liberation Mono", Menlo, monospace;
  }

  html.musk-webai-ui,
  html.musk-webai-ui body {
    font-family: var(--musk-font-sans) !important;
    color: var(--musk-text);
    background: var(--musk-bg);
    letter-spacing: 0 !important;
    text-rendering: optimizeLegibility;
    -webkit-font-smoothing: antialiased;
  }

  html.musk-webai-ui body {
    font-size: 15px;
  }

  html.musk-webai-ui #sidebar {
    background: var(--musk-surface) !important;
    border-right: 1px solid var(--musk-border) !important;
    box-shadow: none !important;
  }

  html.musk-webai-ui #sidebar,
  html.musk-webai-ui #sidebar * {
    letter-spacing: 0 !important;
  }

  html.musk-webai-ui #sidebar a,
  html.musk-webai-ui #sidebar button {
    border-radius: var(--musk-radius-sm) !important;
    font-size: 14.5px !important;
    line-height: 1.35 !important;
  }

  html.musk-webai-ui #sidebar a:hover,
  html.musk-webai-ui #sidebar button:hover {
    background: rgba(20, 24, 32, 0.055) !important;
  }

  html.musk-webai-ui #sidebar [aria-current="page"],
  html.musk-webai-ui #sidebar .active,
  html.musk-webai-ui #sidebar .musk-active-sidebar-link {
    background: #ffffff !important;
    border-color: rgba(213, 218, 227, 0.95) !important;
    color: var(--musk-text) !important;
    font-weight: 650 !important;
    box-shadow: 0 1px 2px rgba(16, 24, 40, 0.04) !important;
  }

  html.musk-webai-ui #sidebar a[href^="/c/"] {
    position: relative !important;
    background: transparent !important;
    border: 1px solid transparent !important;
    box-shadow: none !important;
    min-height: 32px !important;
  }

  html.musk-webai-ui #sidebar a[href^="/c/"]:hover {
    background: rgba(255, 255, 255, 0.72) !important;
    border-color: rgba(230, 233, 238, 0.92) !important;
  }

  html.musk-webai-ui #sidebar a[href^="/c/"].musk-active-sidebar-link {
    background: #ffffff !important;
    border-color: rgba(47, 128, 237, 0.26) !important;
    box-shadow: 0 1px 2px rgba(16, 24, 40, 0.05) !important;
  }

  html.musk-webai-ui #sidebar a[href^="/c/"].musk-active-sidebar-link::before {
    content: "";
    position: absolute;
    left: 4px;
    top: 50%;
    width: 3px;
    height: 16px;
    border-radius: 999px;
    background: var(--musk-accent);
    transform: translateY(-50%);
  }

  html.musk-webai-ui #sidebar-new-chat-button,
  html.musk-webai-ui #new-chat-button {
    background: var(--musk-surface-raised) !important;
    border: 1px solid rgba(213, 218, 227, 0.9) !important;
    color: var(--musk-text) !important;
    box-shadow: 0 1px 2px rgba(15, 18, 25, 0.035) !important;
    min-height: 42px !important;
    font-size: 15px !important;
    font-weight: 620 !important;
  }

  html.musk-webai-ui #sidebar h1,
  html.musk-webai-ui #sidebar h2,
  html.musk-webai-ui #sidebar h3,
  html.musk-webai-ui #sidebar [class*="text-xl"],
  html.musk-webai-ui #sidebar [class*="text-2xl"] {
    font-size: 22px !important;
    line-height: 1.15 !important;
    font-weight: 720 !important;
  }

  html.musk-webai-ui #sidebar [class*="text-xs"],
  html.musk-webai-ui #sidebar [class*="text-gray-400"],
  html.musk-webai-ui #sidebar [class*="text-gray-500"] {
    font-size: 12.5px !important;
    color: var(--musk-text-soft) !important;
  }

  html.musk-webai-ui button[id^="model-selector"],
  html.musk-webai-ui [id^="model-selector"] button,
  html.musk-webai-ui [id^="model-selector"] {
    font-size: 16px !important;
    line-height: 1.3 !important;
    font-weight: 620 !important;
    color: #3f4652 !important;
  }

  html.musk-webai-ui .musk-hidden-top-add-model {
    display: none !important;
  }

  html.musk-webai-ui .musk-model-dropdown {
    min-width: min(360px, calc(100vw - 24px)) !important;
  }

  html.musk-webai-ui .musk-model-dropdown-empty,
  html.musk-webai-ui .musk-model-dropdown-footer-title {
    padding: 8px 12px !important;
    color: var(--musk-text-soft) !important;
    font-size: 12px !important;
    line-height: 1.35 !important;
    font-weight: 520 !important;
  }

  html.musk-webai-ui .musk-model-dropdown-footer {
    margin-top: 6px !important;
    padding: 7px !important;
    border-top: 1px solid rgba(230, 233, 238, 0.95) !important;
  }

  html.musk-webai-ui .musk-model-dropdown-footer-row {
    width: 100% !important;
    min-height: 34px !important;
    display: flex !important;
    align-items: center !important;
    gap: 8px !important;
    padding: 7px 9px !important;
    border: 0 !important;
    border-radius: 8px !important;
    background: transparent !important;
    box-shadow: none !important;
    color: #303846 !important;
    font-size: 13.5px !important;
    line-height: 1.3 !important;
    font-weight: 560 !important;
    text-align: left !important;
  }

  html.musk-webai-ui .musk-model-dropdown-footer-row:hover {
    background: rgba(20, 24, 32, 0.055) !important;
  }

  html.musk-webai-ui .musk-model-api-list {
    margin: 4px 7px 2px !important;
    padding: 4px 0 6px !important;
    border-top: 1px solid rgba(232, 235, 241, 0.9) !important;
  }

  html.musk-webai-ui .musk-model-api-list-title {
    padding: 7px 6px 5px !important;
    color: var(--musk-text-soft) !important;
    font-size: 12px !important;
    line-height: 1.3 !important;
    font-weight: 560 !important;
  }

  html.musk-webai-ui .musk-model-api-row {
    width: 100% !important;
    min-height: 38px !important;
    display: flex !important;
    align-items: center !important;
    justify-content: space-between !important;
    gap: 10px !important;
    padding: 8px 8px !important;
    border: 0 !important;
    border-radius: 9px !important;
    background: transparent !important;
    color: #303846 !important;
    box-shadow: none !important;
    text-align: left !important;
    cursor: pointer !important;
  }

  html.musk-webai-ui .musk-model-api-row:hover {
    background: rgba(20, 24, 32, 0.055) !important;
  }

  html.musk-webai-ui .musk-model-api-row.is-selected {
    background: rgba(47, 128, 237, 0.08) !important;
    color: #1f5fbf !important;
  }

  html.musk-webai-ui .musk-model-api-row-main {
    min-width: 0 !important;
    display: flex !important;
    flex-direction: column !important;
    gap: 2px !important;
  }

  html.musk-webai-ui .musk-model-api-row-name,
  html.musk-webai-ui .musk-model-api-row-id {
    overflow: hidden !important;
    text-overflow: ellipsis !important;
    white-space: nowrap !important;
  }

  html.musk-webai-ui .musk-model-api-row-name {
    font-size: 13.5px !important;
    line-height: 1.3 !important;
    font-weight: 590 !important;
  }

  html.musk-webai-ui .musk-model-api-row-id {
    color: var(--musk-text-soft) !important;
    font-size: 11.5px !important;
    line-height: 1.2 !important;
    font-weight: 500 !important;
  }

  html.musk-webai-ui .musk-model-api-check {
    flex: 0 0 auto !important;
    color: var(--musk-accent) !important;
    font-size: 13px !important;
    font-weight: 700 !important;
  }

  html.musk-webai-ui .musk-response-share-button {
    color: inherit !important;
  }

  html.musk-webai-ui main,
  html.musk-webai-ui [role="main"] {
    background: var(--musk-bg) !important;
  }

  html.musk-webai-ui #messages-container {
    padding-bottom: calc(var(--musk-composer-height, 132px) + 32px) !important;
    scroll-padding-bottom: calc(var(--musk-composer-height, 132px) + 32px) !important;
  }

  html.musk-webai-ui #chat-pane {
    scroll-padding-bottom: calc(var(--musk-composer-height, 132px) + 32px) !important;
  }

  html.musk-webai-ui .message-listitem {
    max-width: 980px !important;
  }

  html.musk-webai-ui .prose,
  html.musk-webai-ui [class*="prose"] {
    max-width: 900px !important;
    color: #172033 !important;
    font-size: 16px !important;
    line-height: 1.76 !important;
    letter-spacing: 0 !important;
  }

  html.musk-webai-ui .prose > :first-child,
  html.musk-webai-ui [class*="prose"] > :first-child {
    margin-top: 0 !important;
  }

  html.musk-webai-ui .prose p,
  html.musk-webai-ui [class*="prose"] p {
    margin: 0.72em 0 !important;
  }

  html.musk-webai-ui .prose h1,
  html.musk-webai-ui [class*="prose"] h1 {
    font-size: 32px !important;
    line-height: 1.18 !important;
    margin: 0.65em 0 0.38em !important;
    font-weight: 760 !important;
    letter-spacing: 0 !important;
    color: #0f172a !important;
  }

  html.musk-webai-ui .prose h2,
  html.musk-webai-ui [class*="prose"] h2 {
    font-size: 25px !important;
    line-height: 1.28 !important;
    margin: 1.05em 0 0.42em !important;
    font-weight: 720 !important;
    letter-spacing: 0 !important;
    color: #111827 !important;
  }

  html.musk-webai-ui .prose h3,
  html.musk-webai-ui [class*="prose"] h3 {
    font-size: 20px !important;
    line-height: 1.38 !important;
    margin: 1em 0 0.36em !important;
    font-weight: 690 !important;
    letter-spacing: 0 !important;
    color: #162033 !important;
  }

  html.musk-webai-ui .prose h4,
  html.musk-webai-ui [class*="prose"] h4 {
    font-size: 17px !important;
    line-height: 1.45 !important;
    margin: 0.9em 0 0.3em !important;
    font-weight: 680 !important;
  }

  html.musk-webai-ui .prose ul,
  html.musk-webai-ui .prose ol,
  html.musk-webai-ui [class*="prose"] ul,
  html.musk-webai-ui [class*="prose"] ol {
    margin: 0.58em 0 0.82em !important;
    padding-left: 1.35em !important;
  }

  html.musk-webai-ui .prose li,
  html.musk-webai-ui [class*="prose"] li {
    margin: 0.32em 0 !important;
    padding-left: 0.12em !important;
  }

  html.musk-webai-ui .prose blockquote,
  html.musk-webai-ui [class*="prose"] blockquote {
    border-left: 3px solid #e1dfd7 !important;
    color: #4b5563 !important;
    background: #fafaf8 !important;
    border-radius: 0 var(--musk-radius-sm) var(--musk-radius-sm) 0 !important;
    margin: 0.9em 0 !important;
    padding: 0.55em 0.9em !important;
    font-style: normal !important;
  }

  html.musk-webai-ui .prose table,
  html.musk-webai-ui [class*="prose"] table {
    font-size: 14.5px !important;
    line-height: 1.55 !important;
    border-collapse: separate !important;
    border-spacing: 0 !important;
    overflow: hidden !important;
    border: 1px solid var(--musk-border) !important;
    border-radius: var(--musk-radius-sm) !important;
  }

  html.musk-webai-ui .markdown-prose .overflow-x-auto,
  html.musk-webai-ui [class*="prose"] .overflow-x-auto,
  html.musk-webai-ui .musk-table-shell {
    max-width: 100% !important;
    overflow-x: auto !important;
    border-radius: var(--musk-radius-sm) !important;
  }

  html.musk-webai-ui .musk-table-shell button,
  html.musk-webai-ui .musk-table-action {
    height: 24px !important;
    min-height: 24px !important;
    padding: 3px 8px !important;
    border-radius: 999px !important;
    border: 1px solid rgba(213, 218, 227, 0.86) !important;
    background: rgba(255, 255, 255, 0.78) !important;
    color: #667085 !important;
    box-shadow: none !important;
    font-size: 12px !important;
    font-weight: 520 !important;
    opacity: 0.58;
    transition: opacity 0.16s ease, background-color 0.16s ease, color 0.16s ease;
  }

  html.musk-webai-ui .musk-table-shell:hover button,
  html.musk-webai-ui .musk-table-shell:hover .musk-table-action {
    opacity: 1;
    background: #ffffff !important;
    color: #303846 !important;
  }

  html.musk-webai-ui .prose th,
  html.musk-webai-ui [class*="prose"] th {
    background: #f5f5f2 !important;
    color: #303846 !important;
    font-weight: 680 !important;
  }

  html.musk-webai-ui .prose td,
  html.musk-webai-ui .prose th,
  html.musk-webai-ui [class*="prose"] td,
  html.musk-webai-ui [class*="prose"] th {
    border-color: var(--musk-border) !important;
    padding: 9px 11px !important;
  }

  html.musk-webai-ui pre,
  html.musk-webai-ui code {
    font-family: var(--musk-font-mono) !important;
    letter-spacing: 0 !important;
  }

  html.musk-webai-ui .prose :not(pre) > code,
  html.musk-webai-ui [class*="prose"] :not(pre) > code {
    font-size: 0.88em !important;
    color: #1f2937 !important;
    background: #f0f1ef !important;
    border: 1px solid #e1e3df !important;
    border-radius: 6px !important;
    padding: 0.12em 0.34em !important;
  }

  html.musk-webai-ui pre {
    background: #f3f3f1 !important;
    border: 1px solid var(--musk-border) !important;
    border-radius: var(--musk-radius-md) !important;
    color: #202631 !important;
    font-size: 13.5px !important;
    line-height: 1.62 !important;
    box-shadow: none !important;
  }

  html.musk-webai-ui .musk-code-block-shell {
    overflow: hidden !important;
    border-radius: 14px !important;
    border-color: rgba(226, 229, 235, 0.95) !important;
  }

  html.musk-webai-ui .musk-code-toolbar {
    position: static !important;
    top: auto !important;
    left: auto !important;
    right: auto !important;
    z-index: 1 !important;
    min-height: 36px !important;
    padding: 7px 12px !important;
    border-bottom: 1px solid rgba(226, 229, 235, 0.86) !important;
    border-radius: 14px 14px 0 0 !important;
    background: #ffffff !important;
  }

  html.musk-webai-ui .musk-code-toolbar button {
    background: transparent !important;
    border-radius: 7px !important;
    color: #4b5563 !important;
  }

  html.musk-webai-ui .musk-code-toolbar button:hover {
    background: rgba(20, 24, 32, 0.06) !important;
    color: #111827 !important;
  }

  html.musk-webai-ui .musk-code-content {
    margin-top: 0 !important;
    border-radius: 0 0 14px 14px !important;
    overflow: hidden !important;
  }

  html.musk-webai-ui .musk-code-content > div:first-child:empty {
    display: none !important;
  }

  html.musk-webai-ui .musk-code-content pre,
  html.musk-webai-ui .musk-code-content .cm-editor {
    margin-top: 0 !important;
    border-top: 0 !important;
    border-radius: 0 0 14px 14px !important;
  }

  html.musk-webai-ui .musk-code-content .cm-editor,
  html.musk-webai-ui .musk-code-content .cm-scroller,
  html.musk-webai-ui .musk-code-content .cm-gutters {
    background: #f3f3f1 !important;
  }

  html.musk-webai-ui .musk-code-content .cm-activeLine,
  html.musk-webai-ui .musk-code-content .cm-activeLineGutter,
  html.musk-webai-ui .musk-code-content .cm-line.cm-activeLine {
    background: transparent !important;
  }

  html.musk-webai-ui .musk-code-content .cm-activeLineGutter {
    color: inherit !important;
  }

  html.musk-webai-ui .musk-thinking-block,
  html.musk-webai-ui [class*="thinking"],
  html.musk-webai-ui [class*="reasoning"],
  html.musk-webai-ui [class*="thought"],
  html.musk-webai-ui details {
    color: var(--musk-text-muted) !important;
    font-size: 14.5px !important;
    line-height: 1.62 !important;
  }

  html.musk-webai-ui .musk-thinking-label,
  html.musk-webai-ui details summary {
    color: #8a909a !important;
    font-size: 14px !important;
    font-weight: 610 !important;
  }

  html.musk-webai-ui .musk-thinking-block blockquote,
  html.musk-webai-ui [class*="thinking"] blockquote,
  html.musk-webai-ui [class*="reasoning"] blockquote {
    color: #667085 !important;
    background: transparent !important;
    border-left-color: #e5e7eb !important;
    font-size: 14.5px !important;
  }

  html.musk-webai-ui .musk-user-message,
  html.musk-webai-ui [class*="message"] [class*="bg-blue"],
  html.musk-webai-ui [class*="chat"] [class*="bg-blue"] {
    background: var(--musk-accent-soft) !important;
    color: #182033 !important;
    border-radius: var(--musk-radius-lg) !important;
    font-size: 15.5px !important;
    line-height: 1.55 !important;
  }

  html.musk-webai-ui #chat-input {
    font-size: 16px !important;
    line-height: 1.55 !important;
    color: var(--musk-text) !important;
  }

  html.musk-webai-ui #chat-input::placeholder {
    color: #a0a5ad !important;
  }

  html.musk-webai-ui .musk-composer,
  html.musk-webai-ui form:has(#chat-input) {
    max-width: 820px !important;
    margin-left: auto !important;
    margin-right: auto !important;
    border-radius: var(--musk-radius-lg) !important;
    border: 1px solid rgba(213, 218, 227, 0.52) !important;
    box-shadow: var(--musk-shadow-soft) !important;
    background: rgba(255, 255, 255, 0.96) !important;
    backdrop-filter: blur(14px);
  }

  html.musk-webai-ui #message-input-container {
    background: transparent !important;
    border: 0 !important;
    box-shadow: none !important;
  }

  html.musk-webai-ui #chat-input-container {
    background: transparent !important;
  }

  html.musk-webai-ui form:has(#chat-input) button {
    border-radius: 999px !important;
  }

  html.musk-webai-ui form:has(#chat-input) button[aria-label="语音模式"],
  html.musk-webai-ui form:has(#chat-input) button[aria-label="Voice Mode"] {
    background: #eef1f5 !important;
    color: #3f4652 !important;
    box-shadow: none !important;
  }

  html.musk-webai-ui form:has(#chat-input) button[aria-label="语音模式"]:hover,
  html.musk-webai-ui form:has(#chat-input) button[aria-label="Voice Mode"]:hover {
    background: #e5e8ee !important;
    color: #20242c !important;
  }

  html.musk-webai-ui form:has(#chat-input) button[aria-label*="发送"],
  html.musk-webai-ui form:has(#chat-input) button[aria-label*="Send"],
  html.musk-webai-ui form:has(#chat-input) #send-message-button {
    background: #20242c !important;
    color: #ffffff !important;
    box-shadow: 0 2px 8px rgba(17, 24, 39, 0.1) !important;
  }

  html.musk-webai-ui form:has(#chat-input):focus-within {
    border-color: rgba(47, 128, 237, 0.34) !important;
    box-shadow: 0 10px 28px rgba(47, 128, 237, 0.055), 0 2px 10px rgba(20, 24, 32, 0.045) !important;
  }

  html.musk-webai-ui .musk-status-banner {
    position: fixed;
    left: 50%;
    bottom: calc(var(--musk-composer-height, 132px) + 18px);
    z-index: 50;
    transform: translateX(-50%);
    max-width: min(520px, calc(100vw - 32px));
    padding: 7px 12px;
    border: 1px solid rgba(213, 218, 227, 0.86);
    border-radius: 999px;
    background: rgba(255, 255, 255, 0.94);
    box-shadow: 0 6px 18px rgba(20, 24, 32, 0.07);
    color: #596170;
    font-size: 12.5px;
    line-height: 1.35;
    backdrop-filter: blur(12px);
  }

  html.musk-webai-ui .musk-status-banner.is-error {
    border-color: rgba(220, 38, 38, 0.18);
    color: #9f1239;
    background: rgba(255, 246, 246, 0.94);
  }

  html.musk-webai-ui .musk-status-banner.is-connection {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  html.musk-webai-ui .musk-status-banner button {
    height: 24px;
    padding: 0 9px;
    border: 1px solid rgba(213, 218, 227, 0.9);
    border-radius: 999px;
    background: #ffffff;
    color: #303846;
    font-size: 12px;
    font-weight: 600;
    white-space: nowrap;
  }

  html.musk-webai-ui .musk-connection-notice {
    max-width: min(420px, calc(100vw - 32px)) !important;
    border-radius: 999px !important;
    box-shadow: 0 6px 18px rgba(20, 24, 32, 0.075) !important;
    font-size: 12.5px !important;
  }

  html.musk-webai-ui .musk-connection-notice.is-muted-repeat {
    display: none !important;
  }

  html.musk-webai-ui.musk-home-empty .musk-home-static-title {
    font-size: 28px !important;
    line-height: 1.28 !important;
    font-weight: 680 !important;
    color: #172033 !important;
    letter-spacing: 0 !important;
    text-align: center !important;
    margin-bottom: 8px !important;
  }

  html.musk-webai-ui.musk-home-empty .musk-home-model-heading-hidden {
    display: none !important;
  }

  html.musk-webai-ui.musk-home-empty .musk-home-suggestions {
    width: min(600px, calc(100vw - 40px)) !important;
    max-height: none !important;
    margin-top: 2px !important;
    overflow: visible !important;
  }

  html.musk-webai-ui.musk-home-empty .musk-home-suggestion-item {
    min-height: 54px !important;
    padding: 8px 12px !important;
    border: 1px solid transparent !important;
    border-radius: 10px !important;
    background: transparent !important;
    box-shadow: none !important;
    transition: background-color 0.16s ease, border-color 0.16s ease, transform 0.16s ease;
  }

  html.musk-webai-ui.musk-home-empty .musk-home-suggestion-item:hover {
    background: rgba(20, 24, 32, 0.045) !important;
    border-color: rgba(230, 233, 238, 0.7) !important;
  }

  html.musk-webai-ui.musk-home-empty .musk-home-suggestion-title {
    font-size: 15px !important;
    line-height: 1.35 !important;
    font-weight: 620 !important;
    color: #242b38 !important;
  }

  html.musk-webai-ui.musk-home-empty .musk-home-suggestion-desc {
    margin-top: 1px !important;
    font-size: 12.5px !important;
    line-height: 1.35 !important;
    color: #747b87 !important;
  }

  html.musk-webai-ui form:has(input[type="password"]) {
    width: min(440px, calc(100vw - 40px)) !important;
  }

  html.musk-webai-ui input,
  html.musk-webai-ui textarea,
  html.musk-webai-ui select {
    font-size: 15.5px !important;
    letter-spacing: 0 !important;
  }

  html.musk-webai-ui button {
    letter-spacing: 0 !important;
  }

  html.musk-webai-ui [class*="text-5xl"],
  html.musk-webai-ui [class*="text-6xl"],
  html.musk-webai-ui [class*="text-7xl"] {
    letter-spacing: 0 !important;
  }

  html.musk-webai-ui [class*="citation"],
  html.musk-webai-ui [class*="source"],
  html.musk-webai-ui sup,
  html.musk-webai-ui .prose small,
  html.musk-webai-ui [class*="prose"] small {
    font-size: 12.5px !important;
    color: var(--musk-text-soft) !important;
  }

  @media (max-width: 768px) {
    html.musk-webai-ui body {
      font-size: 14.5px;
    }

    html.musk-webai-ui button[id^="model-selector"],
    html.musk-webai-ui [id^="model-selector"] button,
    html.musk-webai-ui [id^="model-selector"] {
      max-width: calc(100vw - 142px) !important;
      min-width: 0 !important;
      overflow: hidden !important;
      text-overflow: ellipsis !important;
      white-space: nowrap !important;
      font-size: 14.5px !important;
      line-height: 1.25 !important;
    }

    html.musk-webai-ui button[id^="model-selector"] > div,
    html.musk-webai-ui [id^="model-selector"] button > div,
    html.musk-webai-ui [id^="model-selector"] > div {
      display: block !important;
      min-width: 0 !important;
      max-width: 100% !important;
      overflow: hidden !important;
      text-overflow: ellipsis !important;
      white-space: nowrap !important;
      font-size: 0 !important;
    }

    html.musk-webai-ui button[id^="model-selector"] svg,
    html.musk-webai-ui [id^="model-selector"] button svg,
    html.musk-webai-ui [id^="model-selector"] svg {
      display: none !important;
    }

    html.musk-webai-ui button[id^="model-selector"] > div::before,
    html.musk-webai-ui [id^="model-selector"] button > div::before,
    html.musk-webai-ui [id^="model-selector"] > div::before {
      content: "模型";
      font-size: 14.5px !important;
      line-height: 1.25 !important;
      color: #3f4652 !important;
      font-weight: 620 !important;
    }

    html.musk-webai-ui .prose,
    html.musk-webai-ui [class*="prose"] {
      max-width: 100% !important;
      font-size: 15.5px !important;
      line-height: 1.72 !important;
      padding-left: 2px !important;
      padding-right: 2px !important;
    }

    html.musk-webai-ui .prose h1,
    html.musk-webai-ui [class*="prose"] h1 {
      font-size: 28px !important;
      line-height: 1.2 !important;
    }

    html.musk-webai-ui .prose h2,
    html.musk-webai-ui [class*="prose"] h2 {
      font-size: 22px !important;
    }

    html.musk-webai-ui .prose h3,
    html.musk-webai-ui [class*="prose"] h3 {
      font-size: 18px !important;
    }

    html.musk-webai-ui .musk-composer,
    html.musk-webai-ui form:has(#chat-input) {
      max-width: calc(100vw - 20px) !important;
      border-radius: 16px !important;
    }

    html.musk-webai-ui #messages-container {
      padding-bottom: calc(var(--musk-composer-height, 132px) + 24px) !important;
      scroll-padding-bottom: calc(var(--musk-composer-height, 132px) + 24px) !important;
    }

    html.musk-webai-ui .musk-status-banner {
      bottom: calc(var(--musk-composer-height, 132px) + 12px);
    }

    html.musk-webai-ui.musk-home-empty .musk-home-suggestions {
      width: min(100%, calc(100vw - 32px)) !important;
    }
  }
</style>
'''.strip()

runtime = r'''
<script id="musk-webai-ui-runtime">
  (() => {
    const TEXT_REPLACEMENTS = [
      ['AI 对话探索区', '对话创作']
    ];
    const GENERATION_TIMEOUT_MS = 5 * 60 * 1000;
    const LOADING_WARN_MS = 5 * 1000;
    const LOADING_ERROR_MS = 15 * 1000;
    const CONNECTION_REPEAT_MS = 15 * 1000;
    const CONNECTION_RECOVERY_NUDGE_MS = 4 * 1000;
    const CONNECTION_RECOVERY_WARN_MS = 8 * 1000;
    const CONNECTION_RECOVERY_SOFT_ROUTE_MS = 12 * 1000;
    const CONNECTION_RECOVERY_RELOAD_MS = 22 * 1000;
    const CONNECTION_RECOVERY_RELOAD_COOLDOWN_MS = 2 * 60 * 1000;
    const CONNECTION_DRAFT_TTL_MS = 10 * 60 * 1000;
    const MODEL_CACHE_TTL_MS = 45 * 1000;
    const MODEL_PREFERENCE_KEY = 'musk:webai:selected-model';
    const state = {
      path: window.location.pathname,
      routeStartedAt: Date.now(),
      lastConnectionNoticeAt: 0,
      connectionNoticeStartedAt: 0,
      connectionNoticeLastSeenAt: 0,
      connectionRecoveryNudgeAt: 0,
      connectionRecoverySoftRouteAt: 0,
      connectionRecoveryProbePending: false,
      lastConnectionRecoveryAttemptAt: 0,
      modelsCache: [],
      modelsLoadedAt: 0,
      modelsLoading: null,
      lastNativeModelPrimeAt: 0,
      polishPending: false
    };

    const removeById = (root, ids) => {
      ids.forEach((id) => root.querySelectorAll(`#${id}`).forEach((el) => el.remove()));
    };

    const replaceText = () => {
      const target = document.body || document.documentElement;
      if (!target) return;
      const walker = document.createTreeWalker(target, NodeFilter.SHOW_TEXT);
      const nodes = [];
      while (walker.nextNode()) nodes.push(walker.currentNode);
      for (const node of nodes) {
        if (!node.nodeValue) continue;
        let value = node.nodeValue;
        for (const [oldText, newText] of TEXT_REPLACEMENTS) {
          if (value.includes(oldText)) value = value.replaceAll(oldText, newText);
        }
        if (value !== node.nodeValue) node.nodeValue = value;
      }
    };

    const hideNativeSearch = () => {
      document
        .querySelectorAll('#sidebar button[aria-label="Search"], #sidebar button[aria-label="搜索"], #sidebar a[aria-label="Search"], #sidebar a[aria-label="搜索"]')
        .forEach((el) => {
          el.style.setProperty('display', 'none', 'important');
        });
    };

    const markComposer = () => {
      const input = document.getElementById('chat-input');
      if (!input) return;
      input.classList.add('musk-chat-input');
      const form = input.closest('form');
      if (form) {
        form.classList.add('musk-composer');
        const formRect = form.getBoundingClientRect();
        const parentRect = form.parentElement?.getBoundingClientRect();
        const height = Math.max(
          formRect.height || 0,
          parentRect && parentRect.height < 240 ? parentRect.height : 0,
          118
        );
        document.documentElement.style.setProperty(
          '--musk-composer-height',
          `${Math.ceil(Math.min(Math.max(height, 96), 220))}px`
        );
      }
    };

    const markThinking = () => {
      document
        .querySelectorAll('button, summary, div, span')
        .forEach((el) => {
          const text = (el.textContent || '').trim();
          if (!text || text.length > 90) return;
          if (!/^(思考用时|已分析|Thinking|Reasoning|Analyzed)/i.test(text)) return;
          el.classList.add('musk-thinking-label');
          const block = el.closest('details') || el.parentElement;
          if (block) block.classList.add('musk-thinking-block');
        });
    };

    const markUserMessages = () => {
      document
        .querySelectorAll('[class*="bg-blue"], [class*="bg-[#E"], [class*="bg-sky"]')
        .forEach((el) => {
          const text = (el.textContent || '').trim();
          if (text && text.length < 2400) el.classList.add('musk-user-message');
        });
    };

    const markActiveSidebarLink = () => {
      const currentPath = window.location.pathname;
      document
        .querySelectorAll('#sidebar a[href^="/c/"]')
        .forEach((el) => {
          let active = false;
          try {
            active = new URL(el.href, window.location.origin).pathname === currentPath;
          } catch {
            active = false;
          }
          el.classList.toggle('musk-active-sidebar-link', active);
        });
    };

    const markTableShells = () => {
      document.querySelectorAll('.musk-table-shell, .musk-table-action').forEach((el) => {
        if (el.classList.contains('musk-table-shell') && el.querySelector('table')) return;
        if (el.classList.contains('musk-table-action') && el.closest('.musk-table-shell')) return;
        el.classList.remove('musk-table-shell', 'musk-table-action');
      });

      document.querySelectorAll('table').forEach((table) => {
        const shell = table.closest('.overflow-x-auto, [class*="overflow-x-auto"]') || table.parentElement;
        if (!shell) return;
        shell.classList.add('musk-table-shell');
        shell.querySelectorAll('button').forEach((button) => {
          const text = (button.textContent || button.getAttribute('aria-label') || '').trim();
          if (/^(预览|下载\s*Excel|Preview|Download)/i.test(text)) {
            button.classList.add('musk-table-action');
          }
        });
      });
    };

    const getCurrentChatId = () => {
      const match = window.location.pathname.match(/^\/c\/([^/?#]+)/);
      return match ? decodeURIComponent(match[1]) : '';
    };

    const copyText = async (text) => {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(text);
        return true;
      }
      const input = document.createElement('textarea');
      input.value = text;
      input.setAttribute('readonly', 'readonly');
      input.style.position = 'fixed';
      input.style.opacity = '0';
      document.body.appendChild(input);
      input.select();
      const ok = document.execCommand('copy');
      input.remove();
      return ok;
    };

    const shareChatDirectly = async () => {
      const chatId = getCurrentChatId();
      if (!chatId) {
        ensureStatusBanner('musk-share-status', '当前为空会话，发送第一条消息后即可分享。');
        return;
      }

      try {
        const response = await fetch(`/api/v1/chats/${encodeURIComponent(chatId)}/share`, {
          method: 'POST',
          headers: {
            ...getAuthHeaders(),
            'content-type': 'application/json'
          },
          credentials: 'include',
          cache: 'no-store'
        });
        if (!response.ok) throw new Error(`share ${response.status}`);
        const payload = await response.json();
        const shareId = payload?.share_id || payload?.id || payload?.data?.share_id;
        if (!shareId) throw new Error('missing share id');
        const url = `${window.location.origin}/s/${shareId}`;
        await copyText(url);
        ensureStatusBanner('musk-share-status', '分享链接已复制。', 'info');
      } catch (error) {
        console.warn('[Musk WebAI] share failed', error);
        ensureStatusBanner('musk-share-status', '分享失败，请检查权限或稍后重试。', 'error');
      }
    };

    const openShareFlow = () => {
      const menuButton = document.getElementById('chat-context-menu-button');
      if (!menuButton) {
        shareChatDirectly();
        return;
      }

      menuButton.click();
      window.setTimeout(() => {
        const shareButton = document.getElementById('chat-share-button') ||
          [...document.querySelectorAll('button')].find((button) =>
            !button.classList.contains('musk-response-share-button') && /^(分享|Share)$/i.test(noticeText(button))
          );
        if (shareButton) {
          shareButton.click();
        } else {
          shareChatDirectly();
        }
      }, 120);
    };

    const createShareButton = () => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'musk-response-share-button p-1.5 hover:bg-black/5 dark:hover:bg-white/5 rounded-lg dark:hover:text-white hover:text-black transition';
      button.setAttribute('aria-label', '分享');
      button.setAttribute('title', '分享');
      button.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.3" stroke="currentColor" class="w-4 h-4" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" d="M7.217 10.907a2.25 2.25 0 1 0 0 2.186m0-2.186 9.566-5.314m-9.566 7.5 9.566 5.314m0-12.814a2.25 2.25 0 1 0 2.25 3.897 2.25 2.25 0 0 0-2.25-3.897Zm0 12.814a2.25 2.25 0 1 0 2.25 3.897 2.25 2.25 0 0 0-2.25-3.897Z" />
        </svg>
      `;
      button.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        openShareFlow();
      });
      return button;
    };

    const ensureAssistantShareButtons = () => {
      if (!getCurrentChatId()) return;
      document.querySelectorAll('.buttons').forEach((row) => {
        if (!(row instanceof HTMLElement)) return;
        if (row.querySelector('.musk-response-share-button')) return;
        const copyButton = row.querySelector('.copy-response-button, button[aria-label="Copy"], button[aria-label="复制"]');
        if (!copyButton) return;
        const button = createShareButton();
        let anchor = copyButton;
        while (anchor.parentElement && anchor.parentElement !== row && anchor.parentElement.childElementCount === 1) {
          anchor = anchor.parentElement;
        }
        row.insertBefore(button, anchor.nextSibling);
      });
    };

    const markCodeBlocks = () => {
      document.querySelectorAll('#response-content-container [class*="language-"]').forEach((content) => {
        if (!(content instanceof HTMLElement)) return;
        const shell = content.parentElement;
        if (!(shell instanceof HTMLElement)) return;
        const toolbar = [...shell.children].find((child) => {
          if (!(child instanceof HTMLElement)) return false;
          return child !== content && child.querySelector('.copy-code-button, .save-code-button, .run-code-button');
        });
        if (!(toolbar instanceof HTMLElement)) return;

        shell.classList.add('musk-code-block-shell');
        toolbar.classList.add('musk-code-toolbar');
        content.classList.add('musk-code-content');

        content.querySelectorAll('.cm-editor').forEach((editor) => {
          if (!(editor instanceof HTMLElement) || editor.dataset.muskReadonlyNormalized === '1') return;
          const lines = [...editor.querySelectorAll('.cm-line')]
            .map((line) => line.textContent || '')
            .join('\n');
          if (!lines.trim()) return;
          const pre = document.createElement('pre');
          pre.className = 'hljs p-4 px-5 overflow-x-auto musk-readonly-code';
          const code = document.createElement('code');
          code.textContent = lines;
          pre.appendChild(code);
          editor.dataset.muskReadonlyNormalized = '1';
          editor.replaceWith(pre);
        });
      });
    };

    const getVisibleRect = (el) => {
      const rect = el.getBoundingClientRect();
      if (!rect.width || !rect.height) return null;
      if (rect.bottom < 0 || rect.top > window.innerHeight) return null;
      return rect;
    };

    const noticeText = (el) => (el.textContent || el.getAttribute('aria-label') || '')
      .trim()
      .replace(/\s+/g, ' ');

    const cleanModelLabel = (text) => String(text || '')
      .replace(/\s+/g, ' ')
      .replace(/[✓✔]/g, '')
      .replace(/^已选择[:：]\s*/i, '')
      .replace(/^Selected[:：]\s*/i, '')
      .replace(/^模型\s*/i, '')
      .trim();

    const getModelSelectorButtons = () => [
      ...document.querySelectorAll('button[id^="model-selector"], [id^="model-selector"] button')
    ].filter((button) => button instanceof HTMLElement);

    const getSelectedModelLabel = () => {
      for (const button of getModelSelectorButtons()) {
        const label = cleanModelLabel(button.getAttribute('aria-label') || button.textContent || '');
        if (label && !/选择模型|Select model/i.test(label)) return label;
      }
      return '';
    };

    const getAuthHeaders = () => {
      const token = localStorage.getItem('token') || localStorage.token || '';
      return token ? { authorization: `Bearer ${token}` } : {};
    };

    const getModelId = (model) => String(model?.id || model?.model || model?.value || model?.name || '').trim();

    const getModelName = (model) => String(model?.name || model?.label || getModelId(model)).trim();

    const getModelSearchText = (model) => `${getModelId(model)} ${getModelName(model)}`.toLowerCase();

    const modelIsActive = (model) => {
      if (!model || typeof model !== 'object') return false;
      if (Object.prototype.hasOwnProperty.call(model, 'is_active')) {
        return model.is_active === true || model.is_active === 1 || model.is_active === '1';
      }
      if (Object.prototype.hasOwnProperty.call(model, 'active')) {
        return model.active === true || model.active === 1 || model.active === '1';
      }
      return !(model?.info?.meta?.hidden || model?.meta?.hidden || model?.hidden);
    };

    const getModelsArray = (payload) => Array.isArray(payload)
      ? payload
      : Array.isArray(payload?.data)
        ? payload.data
        : Array.isArray(payload?.items)
          ? payload.items
          : Array.isArray(payload?.data?.items)
            ? payload.data.items
            : Array.isArray(payload?.models)
              ? payload.models
              : Array.isArray(payload?.data?.models)
                ? payload.data.models
                : [];

    const getModelsTotal = (payload) => {
      const total = payload?.total ?? payload?.data?.total ?? payload?.meta?.total ?? payload?.data?.meta?.total;
      return typeof total === 'number' ? total : null;
    };

    const normalizeModelsResponse = (payload) => {
      const raw = getModelsArray(payload);
      const seen = new Set();
      return raw
        .filter(modelIsActive)
        .map((model) => ({
          ...model,
          id: getModelId(model),
          name: getModelName(model)
        }))
        .filter((model) => {
          if (!model.id || seen.has(model.id)) return false;
          seen.add(model.id);
          return true;
        });
    };

    const mergeModels = (...groups) => {
      const seen = new Set();
      const merged = [];
      groups.flat().forEach((model) => {
        const id = getModelId(model);
        if (!id || seen.has(id)) return;
        seen.add(id);
        merged.push({
          ...model,
          id,
          name: getModelName(model)
        });
      });
      return merged;
    };

    const fetchJson = async (url) => {
      const response = await fetch(url, {
        headers: getAuthHeaders(),
        credentials: 'include',
        cache: 'no-store'
      });
      if (!response.ok) throw new Error(`${url} ${response.status}`);
      return response.json();
    };

    const fetchManagementModels = async () => {
      const all = [];
      let page = 1;
      let total = null;

      while (page <= 5) {
        const payload = await fetchJson(`/api/v1/models/list?page=${page}`);
        const pageItems = getModelsArray(payload);
        const items = normalizeModelsResponse(payload);
        all.push(...items.map((model) => ({ ...model, source: 'model-management' })));
        total = getModelsTotal(payload) ?? total;
        if (!pageItems.length) break;
        if (total !== null && all.length >= total) break;
        page += 1;
      }

      return all;
    };

    const fetchAvailableModels = (force = false) => {
      const fresh = Date.now() - state.modelsLoadedAt < MODEL_CACHE_TTL_MS;
      if (!force && fresh && state.modelsCache.length) return Promise.resolve(state.modelsCache);
      if (state.modelsLoading) return state.modelsLoading;

      state.modelsLoading = Promise.allSettled([
        fetchJson('/api/models?refresh=true').then(normalizeModelsResponse),
        fetchManagementModels()
      ])
        .then((results) => {
          results
            .filter((result) => result.status === 'rejected')
            .forEach((result) => console.warn('[Musk WebAI] model source failed', result.reason));
          const groups = results
            .filter((result) => result.status === 'fulfilled')
            .map((result) => result.value);
          const models = mergeModels(...groups);
          state.modelsCache = models;
          state.modelsLoadedAt = Date.now();
          window.dispatchEvent(new CustomEvent('musk:models-loaded', { detail: { models } }));
          return models;
        })
        .catch((error) => {
          console.warn('[Musk WebAI] model refresh failed', error);
          return state.modelsCache;
        })
        .finally(() => {
          state.modelsLoading = null;
        });

      return state.modelsLoading;
    };

    const primeNativeModelStore = () => {
      const now = Date.now();
      if (now - state.lastNativeModelPrimeAt < 900) return;
      state.lastNativeModelPrimeAt = now;
      const needsRuntimeRefresh = !state.modelsCache.length || now - state.modelsLoadedAt >= MODEL_CACHE_TTL_MS;
      getModelSelectorButtons().forEach((button) => {
        const target = button.querySelector('div') || button;
        ['mouseenter', 'mouseover', 'pointerenter'].forEach((type) => {
          target.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: true, view: window }));
        });
      });
      fetchAvailableModels(false).then(() => {
        if (needsRuntimeRefresh) schedulePolish();
      });
    };

    const bindModelSelectorRefresh = () => {
      getModelSelectorButtons().forEach((button) => {
        if (button.dataset.muskModelRefreshBound === '1') return;
        button.dataset.muskModelRefreshBound = '1';
        ['pointerdown', 'focus', 'click'].forEach((type) => {
          button.addEventListener(type, () => primeNativeModelStore(), { passive: true });
        });
      });
    };

    const bindNativeModelSelectionTracking = () => {
      if (document.documentElement.dataset.muskNativeModelTrackingBound === '1') return;
      document.documentElement.dataset.muskNativeModelTrackingBound = '1';
      document.addEventListener('click', (event) => {
        const target = event.target instanceof Element ? event.target : null;
        const dropdown = target?.closest?.('.musk-model-dropdown');
        if (!dropdown || target.closest('.musk-model-api-list, .musk-model-dropdown-footer')) return;
        const row = target.closest('[role="option"], button, [data-value], [cmdk-item]');
        if (!(row instanceof HTMLElement)) return;
        const label = cleanModelLabel(`${row.textContent || ''} ${row.getAttribute('aria-label') || ''} ${row.getAttribute('data-value') || ''}`).toLowerCase();
        const match = state.modelsCache.find((model) => {
          const id = getModelId(model).toLowerCase();
          const name = getModelName(model).toLowerCase();
          return label === id || label === name || label.includes(id) || label.includes(name);
        });
        if (match) setPreferredModel(match, false);
      }, true);
    };

    const getPreferredModel = () => {
      try {
        const value = sessionStorage.getItem(MODEL_PREFERENCE_KEY);
        return value ? JSON.parse(value) : null;
      } catch {
        return null;
      }
    };

    const setPreferredModel = (model, forceLabel = false) => {
      const normalized = { id: getModelId(model), name: getModelName(model), forceLabel };
      if (!normalized.id) return;
      sessionStorage.setItem(MODEL_PREFERENCE_KEY, JSON.stringify(normalized));
    };

    const applyPreferredModelLabel = () => {
      const preferred = getPreferredModel();
      if (!preferred?.id || !preferred.forceLabel) return;
      getModelSelectorButtons().forEach((button) => {
        const target = button.querySelector('div') || button;
        const label = preferred.name || preferred.id;
        if (!target || noticeText(target).includes(label)) return;
        const svg = target.querySelector('svg');
        target.textContent = label;
        if (svg) target.appendChild(svg);
        button.setAttribute('aria-label', `Selected model: ${label}`);
      });
    };

    const isChatCompletionRequest = (input) => {
      const url = typeof input === 'string' ? input : input?.url || '';
      return /\/api\/(chat\/completions|v1\/chat\/completions|v1\/chats\/completion|chat\/completion)/i.test(url);
    };

    const installPreferredModelFetchPatch = () => {
      if (window.__muskPreferredModelFetchPatched) return;
      window.__muskPreferredModelFetchPatched = true;
      const nativeFetch = window.fetch.bind(window);
      window.fetch = (input, init = {}) => {
        const preferred = getPreferredModel();
        if (!preferred?.id || !isChatCompletionRequest(input)) return nativeFetch(input, init);

        try {
          const nextInit = { ...init };
          const body = nextInit.body;
          if (typeof body === 'string' && body.trim().startsWith('{')) {
            const payload = JSON.parse(body);
            if (payload && typeof payload === 'object') {
              payload.model = preferred.id;
              if (Array.isArray(payload.models)) payload.models = [preferred.id];
              nextInit.body = JSON.stringify(payload);
              return nativeFetch(input, nextInit);
            }
          }
        } catch (error) {
          console.warn('[Musk WebAI] preferred model patch skipped', error);
        }

        return nativeFetch(input, init);
      };
    };

    const isLikelyTopAddModelButton = (button) => {
      if (!(button instanceof HTMLElement)) return false;
      const label = noticeText(button);
      if (!/^(Add Model|添加模型)$/i.test(label)) return false;
      if (button.closest('#sidebar, form, [role="dialog"], [role="menu"], [role="listbox"], .musk-model-dropdown')) {
        return false;
      }

      const nav = button.closest('nav');
      const rect = button.getBoundingClientRect();
      if (!rect.width || !rect.height) return false;

      const modelButtons = getModelSelectorButtons();
      const nearModelSelector = modelButtons.some((modelButton) => {
        const modelRect = modelButton.getBoundingClientRect();
        if (!modelRect.width || !modelRect.height) return false;
        const verticalDelta = Math.abs((rect.top + rect.height / 2) - (modelRect.top + modelRect.height / 2));
        const horizontalGap = rect.left - modelRect.right;
        return verticalDelta <= 28 && horizontalGap >= -8 && horizontalGap <= 72;
      });

      return Boolean(nav && nearModelSelector);
    };

    const findTopAddModelButton = () => {
      const candidates = [
        ...document.querySelectorAll('button[aria-label="Add Model"], button[aria-label="添加模型"]')
      ].filter((button) => button instanceof HTMLElement);
      return candidates.find((button) => button.classList.contains('musk-hidden-top-add-model')) ||
        candidates.find(isLikelyTopAddModelButton) ||
        null;
    };

    const hideTopAddModelButton = () => {
      document
        .querySelectorAll('button[aria-label="Add Model"], button[aria-label="添加模型"]')
        .forEach((button) => {
          if (!(button instanceof HTMLElement)) return;
          const shouldHide = button.classList.contains('musk-hidden-top-add-model') || isLikelyTopAddModelButton(button);
          button.classList.toggle('musk-hidden-top-add-model', shouldHide);
        });
    };

    const isModelDropdownCandidate = (container, selectedModel) => {
      if (!(container instanceof HTMLElement)) return false;
      if (container.closest('nav, #sidebar, form, .musk-model-dropdown-footer')) return false;
      const rect = getVisibleRect(container);
      if (!rect || rect.width < 180 || rect.height < 48 || rect.height > window.innerHeight * 0.92) return false;
      const text = noticeText(container);
      const hasModelSearch = /搜索模型|Search Models?|Search models?/i.test(text) ||
        [...container.querySelectorAll('input')].some((input) => {
          const inputLabel = `${input.getAttribute('placeholder') || ''} ${input.getAttribute('aria-label') || ''}`;
          return /搜索模型|Search Models?|Search models?/i.test(inputLabel);
        });
      if (!hasModelSearch) return false;
      const hasModelOption = Boolean(container.querySelector('[role="option"], button, [data-value], [cmdk-item]'));
      return hasModelOption || Boolean(selectedModel && text.includes(selectedModel));
    };

    const findModelDropdown = () => {
      const selectedModel = getSelectedModelLabel();
      const searchInputs = [...document.querySelectorAll('input')].filter((input) => {
        const label = `${input.getAttribute('placeholder') || ''} ${input.getAttribute('aria-label') || ''}`;
        return /搜索模型|Search Models?|Search models?/i.test(label);
      });

      for (const input of searchInputs) {
        let parent = input.parentElement;
        while (parent && parent !== document.body) {
          if (isModelDropdownCandidate(parent, selectedModel)) return parent;
          parent = parent.parentElement;
        }
      }

      const candidates = [
        ...document.querySelectorAll('[role="listbox"], [role="menu"], [role="dialog"], [data-headlessui-state], [data-radix-popper-content-wrapper], [class*="popover"], [class*="Popover"], [class*="dropdown"], [class*="Dropdown"]')
      ];
      return candidates.find((container) => isModelDropdownCandidate(container, selectedModel)) || null;
    };

    const getDropdownModelLabels = (container) => {
      const ignore = /(搜索模型|Search Models?|Search models?|添加模型|Add Model|管理模型|Manage Models?|模型管理|暂无其他|当前模型|可用模型|选择模型|Select model|Remove Model|设为默认|更多选项|More options?)/i;
      const selectedModel = getSelectedModelLabel();
      const labels = [
        ...container.querySelectorAll('[role="option"], button, [data-value], [cmdk-item]')
      ]
        .filter((el) => {
          if (!(el instanceof HTMLElement)) return false;
          if (el.closest('.musk-model-dropdown-footer')) return false;
          return Boolean(getVisibleRect(el));
        })
        .map((el) => cleanModelLabel(el.textContent || el.getAttribute('aria-label') || el.getAttribute('data-value') || ''))
        .filter((label) => label && !ignore.test(label));

      if (!labels.length && selectedModel && noticeText(container).includes(selectedModel)) labels.push(selectedModel);
      return [...new Set(labels)];
    };

    const ensureModelDropdownFooter = (container) => {
      let footer = container.querySelector('.musk-model-dropdown-footer');
      if (!footer) {
        footer = document.createElement('div');
        footer.className = 'musk-model-dropdown-footer';
        footer.innerHTML = `
          <div class="musk-model-dropdown-footer-title">模型管理</div>
          <button type="button" class="musk-model-dropdown-footer-row" data-musk-model-action="add">+ 添加模型</button>
          <button type="button" class="musk-model-dropdown-footer-row" data-musk-model-action="manage">管理模型</button>
        `;
        container.appendChild(footer);
      }

      const addButton = footer.querySelector('[data-musk-model-action="add"]');
      if (addButton && addButton.dataset.muskBound !== '1') {
        addButton.dataset.muskBound = '1';
        addButton.addEventListener('click', (event) => {
          event.preventDefault();
          event.stopPropagation();
          const nativeAdd = findTopAddModelButton();
          if (nativeAdd) {
            nativeAdd.click();
            schedulePolish();
          }
        });
      }

      const manageButton = footer.querySelector('[data-musk-model-action="manage"]');
      if (manageButton && manageButton.dataset.muskBound !== '1') {
        manageButton.dataset.muskBound = '1';
        manageButton.addEventListener('click', (event) => {
          event.preventDefault();
          event.stopPropagation();
          window.location.assign('/workspace/models');
        });
      }
    };

    const dropdownHasModel = (labels, model) => {
      const id = getModelId(model).toLowerCase();
      const name = getModelName(model).toLowerCase();
      return labels.some((label) => {
        const value = label.toLowerCase();
        return value === id || value === name || value.includes(id) || value.includes(name);
      });
    };

    const findNativeModelOption = (container, model) => {
      const id = getModelId(model).toLowerCase();
      const name = getModelName(model).toLowerCase();
      const options = [
        ...container.querySelectorAll('[role="option"], button, [data-value], [cmdk-item]')
      ].filter((el) => {
        if (!(el instanceof HTMLElement)) return false;
        if (el.closest('.musk-model-dropdown-footer, .musk-model-api-list')) return false;
        return Boolean(getVisibleRect(el));
      });
      return options.find((el) => {
        const value = cleanModelLabel(`${el.textContent || ''} ${el.getAttribute('aria-label') || ''} ${el.getAttribute('data-value') || ''}`).toLowerCase();
        return value === id || value === name || value.includes(id) || value.includes(name);
      }) || null;
    };

    const closeModelDropdown = () => {
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', code: 'Escape', bubbles: true }));
    };

    const clickNativeModelOption = (container, model) => {
      const nativeOption = findNativeModelOption(container, model);
      if (!nativeOption) return false;
      nativeOption.click();
      setPreferredModel(model, false);
      return true;
    };

    const selectApiModel = (model, row) => {
      row?.setAttribute('aria-busy', 'true');
      primeNativeModelStore();
      const dropdown = findModelDropdown();
      if (dropdown && clickNativeModelOption(dropdown, model)) {
        row?.removeAttribute('aria-busy');
        return;
      }

      window.setTimeout(() => {
        const refreshedDropdown = findModelDropdown() || dropdown;
        if (refreshedDropdown && clickNativeModelOption(refreshedDropdown, model)) {
          row?.removeAttribute('aria-busy');
          return;
        }

        setPreferredModel(model, true);
        applyPreferredModelLabel();
        closeModelDropdown();
        ensureStatusBanner(
          'musk-model-select-status',
          `已选择 ${getModelName(model)}，新对话会使用该模型。`,
          'info'
        );
        row?.removeAttribute('aria-busy');
      }, 520);
    };

    const bindDropdownSearchFiltering = (container) => {
      const input = container.querySelector('input');
      if (!input || input.dataset.muskModelSearchBound === '1') return;
      input.dataset.muskModelSearchBound = '1';
      input.addEventListener('input', () => {
        const query = input.value.trim().toLowerCase();
        container.querySelectorAll('.musk-model-api-row').forEach((row) => {
          const match = !query || (row.dataset.muskSearchText || '').includes(query);
          row.style.display = match ? '' : 'none';
        });
      });
    };

    const renderApiModelsInDropdown = (container, labels) => {
      let list = container.querySelector('.musk-model-api-list');
      const hasLoaded = state.modelsLoadedAt > 0;
      const models = state.modelsCache;
      const selectedLabel = getSelectedModelLabel().toLowerCase();

      if (!hasLoaded && !models.length) {
        fetchAvailableModels(false).then(() => schedulePolish());
        return;
      }

      if (!list) {
        list = document.createElement('div');
        list.className = 'musk-model-api-list';
        const footer = container.querySelector('.musk-model-dropdown-footer');
        container.insertBefore(list, footer || null);
      }

      const visibleModels = models.filter((model) => !dropdownHasModel(labels, model) || labels.length <= 1);
      if (!visibleModels.length) {
        list.remove();
        return;
      }

      list.innerHTML = '<div class="musk-model-api-list-title">可用模型</div>';
      visibleModels.forEach((model) => {
        const id = getModelId(model);
        const name = getModelName(model);
        const row = document.createElement('button');
        row.type = 'button';
        row.className = 'musk-model-api-row';
        row.dataset.muskModelId = id;
        row.dataset.muskSearchText = getModelSearchText(model);
        if (selectedLabel && (selectedLabel.includes(id.toLowerCase()) || selectedLabel.includes(name.toLowerCase()))) {
          row.classList.add('is-selected');
        }
        row.innerHTML = `
          <span class="musk-model-api-row-main">
            <span class="musk-model-api-row-name"></span>
            <span class="musk-model-api-row-id"></span>
          </span>
          <span class="musk-model-api-check" aria-hidden="true"></span>
        `;
        row.querySelector('.musk-model-api-row-name').textContent = name;
        row.querySelector('.musk-model-api-row-id').textContent = id === name ? '' : id;
        row.querySelector('.musk-model-api-check').textContent = row.classList.contains('is-selected') ? '✓' : '';
        row.addEventListener('click', (event) => {
          event.preventDefault();
          event.stopPropagation();
          selectApiModel(model, row);
        });
        list.appendChild(row);
      });

      bindDropdownSearchFiltering(container);
    };

    const enhanceModelDropdown = () => {
      const dropdown = findModelDropdown();
      if (!dropdown) return;

      dropdown.classList.add('musk-model-dropdown');
      primeNativeModelStore();
      const labels = getDropdownModelLabels(dropdown);
      renderApiModelsInDropdown(dropdown, labels);
      const selectedModel = getSelectedModelLabel();
      const isSelectedModelRow = (label) => selectedModel &&
        (label === selectedModel || label.includes(selectedModel) || selectedModel.includes(label));
      const hasLoadedModels = state.modelsLoadedAt > 0;
      const hasApiOtherModel = hasLoadedModels && state.modelsCache.length > 1;
      const hasOtherModel = hasApiOtherModel ||
        labels.some((label) => selectedModel ? !isSelectedModelRow(label) : true);
      let empty = dropdown.querySelector('.musk-model-dropdown-empty');

      if (hasLoadedModels && !hasOtherModel) {
        if (!empty) {
          empty = document.createElement('div');
          empty.className = 'musk-model-dropdown-empty';
          empty.textContent = '暂无其他可切换模型';
          const existingFooter = dropdown.querySelector('.musk-model-dropdown-footer');
          dropdown.insertBefore(empty, existingFooter || null);
        }
      } else if (empty) {
        empty.remove();
      }

      ensureModelDropdownFooter(dropdown);
    };

    const ensureStatusBanner = (id, text, kind = 'info') => {
      let banner = document.getElementById(id);
      if (!text) {
        if (banner) banner.remove();
        return;
      }
      if (!banner) {
        banner = document.createElement('div');
        banner.id = id;
        banner.className = 'musk-status-banner';
        banner.setAttribute('role', 'status');
        document.body.appendChild(banner);
      }
      banner.textContent = text;
      banner.classList.toggle('is-error', kind === 'error');
    };

    const reloadWithCacheBust = () => {
      const url = new URL(window.location.href);
      url.searchParams.set('musk-reconnect', String(Date.now()));
      window.location.replace(url.toString());
    };

    const getConnectionDraftKey = () => `musk:webai:connection-draft:${window.location.pathname}`;

    const getComposerDraft = () => {
      const input = document.getElementById('chat-input');
      if (!input) return '';
      if ('value' in input) return String(input.value || '').trim();
      return (input.textContent || '').trim();
    };

    const stashComposerDraft = () => {
      const draft = getComposerDraft();
      if (!draft) return false;
      try {
        sessionStorage.setItem(
          getConnectionDraftKey(),
          JSON.stringify({
            value: draft,
            savedAt: Date.now()
          })
        );
        return true;
      } catch {
        return false;
      }
    };

    const restoreComposerDraft = () => {
      const input = document.getElementById('chat-input');
      if (!input || getComposerDraft()) return;
      let payload = null;
      try {
        payload = JSON.parse(sessionStorage.getItem(getConnectionDraftKey()) || 'null');
      } catch {
        payload = null;
      }
      if (!payload || !payload.value || Date.now() - Number(payload.savedAt || 0) > CONNECTION_DRAFT_TTL_MS) {
        sessionStorage.removeItem(getConnectionDraftKey());
        return;
      }
      if ('value' in input) {
        input.value = payload.value;
      } else {
        input.textContent = payload.value;
      }
      try {
        input.dispatchEvent(new InputEvent('input', { bubbles: true, inputType: 'insertFromPaste', data: payload.value }));
      } catch {
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
      sessionStorage.removeItem(getConnectionDraftKey());
      ensureConnectionBanner('连接已恢复，已保留输入内容。');
      setTimeout(() => ensureStatusBanner('musk-connection-recovery', ''), 4200);
    };

    const nudgeConnectionClient = () => {
      if (navigator.onLine === false) return;
      window.dispatchEvent(new Event('online'));
      window.dispatchEvent(new Event('focus'));
      document.dispatchEvent(new Event('visibilitychange'));
    };

    const softRefreshRoute = () => {
      try {
        const url = new URL(window.location.href);
        url.searchParams.set('musk-soft-reconnect', String(Date.now()));
        window.history.replaceState(window.history.state, '', url.toString());
        window.dispatchEvent(new PopStateEvent('popstate', { state: window.history.state }));
      } catch {
        window.dispatchEvent(new Event('popstate'));
      }
      nudgeConnectionClient();
    };

    const ensureConnectionBanner = (text, kind = 'info', withButton = false) => {
      ensureStatusBanner('musk-connection-recovery', text, kind);
      const banner = document.getElementById('musk-connection-recovery');
      if (!banner) return;
      banner.classList.add('is-connection');
      let button = banner.querySelector('button');
      if (withButton) {
        if (!button) {
          button = document.createElement('button');
          button.type = 'button';
          button.textContent = '刷新连接';
          button.addEventListener('click', reloadWithCacheBust);
          banner.appendChild(button);
        }
      } else if (button) {
        button.remove();
      }
    };

    const findStopButton = () => {
      for (const button of document.querySelectorAll('button')) {
        if (!getVisibleRect(button)) continue;
        const label = [
          button.textContent,
          button.getAttribute('aria-label'),
          button.getAttribute('title')
        ].filter(Boolean).join(' ').trim();
        if (!label) continue;
        if (/(停止|Stop generating|Stop response|Stop)/i.test(label)) return button;
      }
      return null;
    };

    const hasComposerDraft = () => {
      return Boolean(getComposerDraft());
    };

    const generationWatchdog = () => {
      const key = `musk:webai:running:${window.location.pathname}`;
      const stopButton = findStopButton();
      if (!stopButton) {
        sessionStorage.removeItem(key);
        sessionStorage.removeItem(`${key}:stopped`);
        ensureStatusBanner('musk-generation-watchdog', '');
        return;
      }

      const now = Date.now();
      let startedAt = Number(sessionStorage.getItem(key) || 0);
      if (!startedAt) {
        startedAt = now;
        sessionStorage.setItem(key, String(startedAt));
      }

      const elapsed = now - startedAt;
      if (elapsed < GENERATION_TIMEOUT_MS) return;

      ensureStatusBanner(
        'musk-generation-watchdog',
        '任务已超过 5 分钟，已尝试停止。可重新发送或缩小任务范围后重试。',
        'error'
      );

      if (sessionStorage.getItem(`${key}:stopped`) !== '1') {
        sessionStorage.setItem(`${key}:stopped`, '1');
        stopButton.click();
      }
    };

    const updateRouteState = () => {
      if (state.path === window.location.pathname) return;
      state.path = window.location.pathname;
      state.routeStartedAt = Date.now();
      ensureStatusBanner('musk-route-loading-watchdog', '');
    };

    const routeLoadingWatchdog = () => {
      updateRouteState();
      const loading = [...document.querySelectorAll('[role="status"], [aria-live], .animate-spin, [class*="animate-spin"], div, span')]
        .some((el) => {
          if (el.classList.contains('musk-status-banner')) return false;
          const rect = getVisibleRect(el);
          if (!rect) return false;
          const text = noticeText(el);
          if (/^(加载中|加载|Loading|Please wait)/i.test(text)) return true;
          return /animate-spin/.test(String(el.className || '')) && rect.top > 48 && rect.top < window.innerHeight - 96;
        });

      if (!loading) {
        ensureStatusBanner('musk-route-loading-watchdog', '');
        return;
      }

      const elapsed = Date.now() - state.routeStartedAt;
      if (elapsed > LOADING_ERROR_MS) {
        ensureStatusBanner('musk-route-loading-watchdog', '加载时间过长，可刷新或返回后重试。', 'error');
      } else if (elapsed > LOADING_WARN_MS) {
        ensureStatusBanner('musk-route-loading-watchdog', '加载较慢，正在继续尝试。');
      }
    };

    const markConnectionNotices = () => {
      const pattern = /(重新连接|正在重新连接|断开连接|连接已断开|连接中断|Reconnecting|Disconnected|Connection lost|Trying to reconnect)/i;
      let seenCount = 0;
      document.querySelectorAll('[role="alert"], [role="status"], [aria-live], [class*="toast"], [class*="notification"], [class*="sonner"], div')
        .forEach((el) => {
          const text = noticeText(el);
          if (!pattern.test(text)) return;
          const rect = getVisibleRect(el);
          if (!rect) return;
          const style = window.getComputedStyle(el);
          const className = String(el.className || '');
          const isNoticeSurface =
            el.matches('[role="alert"], [role="status"], [aria-live]') ||
            /toast|notification|sonner/i.test(className) ||
            (['fixed', 'sticky'].includes(style.position) && rect.height < 120);
          if (!isNoticeSurface) return;

          seenCount += 1;
          el.classList.add('musk-connection-notice');
          if (el.dataset.muskConnectionNoticeSeen === '1') return;

          const now = Date.now();
          if (now - state.lastConnectionNoticeAt < CONNECTION_REPEAT_MS) {
            el.classList.add('is-muted-repeat');
          } else {
            state.lastConnectionNoticeAt = now;
            el.classList.remove('is-muted-repeat');
          }
          el.dataset.muskConnectionNoticeSeen = '1';
        });
      return seenCount;
    };

    const connectionRecoveryWatchdog = (noticeCount) => {
      const now = Date.now();
      if (!noticeCount) {
        if (state.connectionNoticeLastSeenAt && now - state.connectionNoticeLastSeenAt > 3000) {
          state.connectionNoticeStartedAt = 0;
          state.connectionRecoveryNudgeAt = 0;
          state.connectionRecoverySoftRouteAt = 0;
          ensureStatusBanner('musk-connection-recovery', '');
        }
        return;
      }

      state.connectionNoticeLastSeenAt = now;
      if (!state.connectionNoticeStartedAt) state.connectionNoticeStartedAt = now;
      const elapsed = now - state.connectionNoticeStartedAt;

      if (elapsed > CONNECTION_RECOVERY_NUDGE_MS && now - state.connectionRecoveryNudgeAt > 5000) {
        state.connectionRecoveryNudgeAt = now;
        nudgeConnectionClient();
      }

      if (elapsed > CONNECTION_RECOVERY_WARN_MS) {
        ensureConnectionBanner('连接状态不稳定，正在尝试恢复。');
      }

      if (elapsed > CONNECTION_RECOVERY_SOFT_ROUTE_MS && now - state.connectionRecoverySoftRouteAt > 30000) {
        state.connectionRecoverySoftRouteAt = now;
        softRefreshRoute();
        ensureConnectionBanner('连接仍未恢复，正在重建当前会话连接。');
      }

      if (elapsed < CONNECTION_RECOVERY_RELOAD_MS) return;
      if (state.connectionRecoveryProbePending) return;
      if (now - state.lastConnectionRecoveryAttemptAt < 30000) return;

      state.connectionRecoveryProbePending = true;
      state.lastConnectionRecoveryAttemptAt = now;

      const probe = (url) => fetch(url, {
        cache: 'no-store',
        credentials: 'include'
      });

      probe(`/api/version?musk_reconnect_probe=${now}`)
        .catch(() => probe(`/_app/version.json?musk_reconnect_probe=${now}`))
        .then((response) => {
          if (!response.ok) throw new Error('probe failed');
          const reloadKey = `musk:webai:connection-reload:${window.location.pathname}`;
          const lastReloadAt = Number(sessionStorage.getItem(reloadKey) || 0);
          const hasDraft = hasComposerDraft();
          const canAutoReload =
            document.visibilityState === 'visible' &&
            navigator.onLine !== false &&
            !findStopButton() &&
            now - lastReloadAt > CONNECTION_RECOVERY_RELOAD_COOLDOWN_MS;

          if (canAutoReload) {
            if (hasDraft) stashComposerDraft();
            sessionStorage.setItem(reloadKey, String(Date.now()));
            ensureConnectionBanner(hasDraft ? '连接已卡住，正在刷新恢复；已暂存输入内容。' : '连接已卡住，正在刷新当前页面恢复。');
            setTimeout(reloadWithCacheBust, 350);
          } else {
            ensureConnectionBanner('连接仍未恢复。当前有生成任务或恢复过于频繁，请确认后刷新连接。', 'error', true);
          }
        })
        .catch(() => {
          ensureConnectionBanner('当前网络到服务器不稳定，恢复后会继续尝试连接。', 'error');
        })
        .finally(() => {
          state.connectionRecoveryProbePending = false;
        });
    };

    const clearHomeSuggestions = () => {
      document
        .querySelectorAll('.musk-home-suggestions, .musk-home-suggestion-item, .musk-home-suggestion-title, .musk-home-suggestion-desc')
        .forEach((el) => {
          el.classList.remove(
            'musk-home-suggestions',
            'musk-home-suggestion-item',
            'musk-home-suggestion-title',
            'musk-home-suggestion-desc'
          );
        });
    };

    const markHomeSuggestions = () => {
      const buttons = [...document.querySelectorAll('button.waterfall, button[class*="waterfall"]')]
        .filter((button) => {
          if (button.closest('nav, #sidebar, form')) return false;
          const text = (button.textContent || '').trim().replace(/\s+/g, ' ');
          const rect = button.getBoundingClientRect();
          return text.length >= 8 && text.length <= 120 && rect.width > 240 && rect.height >= 36;
        });

      if (!buttons.length) return;
      const container = buttons[0].parentElement;
      if (container) container.classList.add('musk-home-suggestions');

      buttons.forEach((button) => {
        button.classList.add('musk-home-suggestion-item');
        const title = button.querySelector('.font-medium') || button.firstElementChild?.firstElementChild;
        const desc = button.querySelector('.text-xs') || title?.nextElementSibling;
        if (title) title.classList.add('musk-home-suggestion-title');
        if (desc) desc.classList.add('musk-home-suggestion-desc');
      });
    };

    const ensureHomeStaticTitle = () => {
      const selectedModel = getSelectedModelLabel();
      const helpText = [...document.querySelectorAll('p, div, span')]
        .find((el) => {
          if (!(el instanceof HTMLElement)) return false;
          if (el.closest('nav, #sidebar, form, button, .musk-model-dropdown, [role="listbox"], [role="menu"], [role="dialog"]')) return false;
          const text = noticeText(el);
          if (!/^(有什么我能帮您的吗？|有什么我能帮您的吗\?|How can I help you\??)$/i.test(text)) return false;
          const rect = getVisibleRect(el);
          return Boolean(rect && rect.top > 80 && rect.width > 180);
        });

      let container = helpText?.parentElement || null;
      let insertBefore = helpText || null;
      let modelBlock = null;

      if (!container && selectedModel) {
        const modelNode = [...document.querySelectorAll('div, span, h1, h2')]
          .find((el) => {
            if (!(el instanceof HTMLElement)) return false;
            if (el.closest('nav, #sidebar, form, button, .musk-model-dropdown, [role="listbox"], [role="menu"], [role="dialog"]')) return false;
            if (noticeText(el) !== selectedModel) return false;
            const rect = getVisibleRect(el);
            return Boolean(rect && rect.top > 80 && rect.width > 120);
          });

        if (modelNode) {
          modelBlock = modelNode;
          while (
            modelBlock.parentElement &&
            modelBlock.parentElement !== document.body &&
            !/建议|Suggestions/i.test(noticeText(modelBlock.parentElement)) &&
            noticeText(modelBlock.parentElement).includes(selectedModel)
          ) {
            modelBlock = modelBlock.parentElement;
          }
          container = modelBlock.parentElement;
          insertBefore = modelBlock;
        }
      }

      if (!container) return;
      let title = container.querySelector('.musk-home-static-title');
      if (!title) {
        title = document.createElement('div');
        title.className = 'musk-home-static-title';
        title.textContent = '今天要完成什么工作？';
        container.insertBefore(title, insertBefore);
      }

      if (modelBlock instanceof HTMLElement) {
        modelBlock.classList.add('musk-home-model-heading-hidden');
      }

      [...container.children].forEach((child) => {
        if (!(child instanceof HTMLElement) || child === title || child === helpText) return;
        const text = noticeText(child);
        const isModelHeading = selectedModel &&
          (text === selectedModel || text.includes(selectedModel) || selectedModel.includes(text));
        child.classList.toggle('musk-home-model-heading-hidden', Boolean(isModelHeading));
      });
    };

    const markHomeEmptyState = () => {
      const isHome = window.location.pathname === '/';
      document.documentElement.classList.toggle('musk-home-empty', isHome);
      if (!isHome) {
        clearHomeSuggestions();
        return;
      }

      const input = document.getElementById('chat-input');
      if (!input) return;

      ensureHomeStaticTitle();
      markHomeSuggestions();
    };

    const polish = () => {
      document.documentElement.classList.add('musk-webai-ui');
      installPreferredModelFetchPatch();
      hideNativeSearch();
      bindModelSelectorRefresh();
      bindNativeModelSelectionTracking();
      hideTopAddModelButton();
      enhanceModelDropdown();
      applyPreferredModelLabel();
      replaceText();
      markComposer();
      markThinking();
      markUserMessages();
      markActiveSidebarLink();
      markTableShells();
      markCodeBlocks();
      ensureAssistantShareButtons();
      markHomeEmptyState();
      restoreComposerDraft();
      generationWatchdog();
      routeLoadingWatchdog();
      connectionRecoveryWatchdog(markConnectionNotices());
    };

    const schedulePolish = () => {
      if (state.polishPending) return;
      state.polishPending = true;
      requestAnimationFrame(() => {
        state.polishPending = false;
        polish();
      });
    };

    polish();
    document.addEventListener('DOMContentLoaded', schedulePolish);
    window.addEventListener('popstate', schedulePolish);
    window.addEventListener('hashchange', schedulePolish);
    window.addEventListener('online', schedulePolish);
    window.addEventListener('offline', schedulePolish);
    window.addEventListener('focus', schedulePolish);
    document.addEventListener('visibilitychange', schedulePolish);
    window.setInterval(schedulePolish, 2000);
    new MutationObserver(schedulePolish).observe(document.documentElement, {
      childList: true,
      subtree: true,
      characterData: true
    });
  })();
</script>
'''.strip()


def strip_existing(html: str) -> str:
    for style_id in STYLE_IDS:
        html = re.sub(
            rf'<style id="{re.escape(style_id)}">.*?</style>\s*',
            '',
            html,
            flags=re.S,
        )
    for script_id in SCRIPT_IDS:
        html = re.sub(
            rf'<script id="{re.escape(script_id)}">.*?</script>\s*',
            '',
            html,
            flags=re.S,
        )
    return html


def inject(html: str) -> str:
    html = strip_existing(html)
    if '</head>' in html:
        html = html.replace('</head>', f'{style}\n</head>', 1)
    else:
        html = f'{style}\n{html}'
    if '</body>' in html:
        html = html.replace('</body>', f'{runtime}\n</body>', 1)
    else:
        html = f'{html}\n{runtime}'
    return html


for html_path in html_paths:
    if not html_path.exists():
        continue
    original = html_path.read_text(errors='ignore')
    updated = inject(original)
    if updated != original:
        html_path.write_text(updated)
        print(f'updated {html_path}')

if version_path.exists():
    version_path.write_text(json.dumps({'version': f'musk-webai-ui-{int(time.time())}'}))
    print(f'updated {version_path}')
PY
