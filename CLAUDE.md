# Murmur

## What is Murmur?

Murmur is a desktop voice recording tool for macOS. It lets users effortlessly capture their voice — whether for quick notes, memos, ideas, or messages — with minimal friction. Think of it as a whisper app: a lightweight, always-available tool that makes it easy for anyone to record their voice and do something useful with it.

## Core Concept

The goal is to make voice recording feel as natural and instant as typing a note. Murmur sits quietly in the background (menu bar or dock) and is ready whenever you need to capture a thought out loud.

## Platform

- **Primary target**: macOS (desktop app)
- **Future platforms**: potentially iOS, Windows, Linux

## Key Features (Planned)

- **Focus-and-paste recording** (core UX): user presses a global hotkey (e.g. Shift+P) to start recording, clicks into any text input anywhere on the system while speaking, then presses the hotkey again to stop — Murmur transcribes (and translates if enabled) and pastes the result directly into that focused input field. Zero extra steps.
- One-click or hotkey-triggered voice recording
- Automatic transcription of recorded audio (via Whisper or similar)
- **Voice translation**: user can select a target language before recording; they speak in any language (e.g. English) and the transcription output is delivered in the chosen target language (e.g. Spanish) — speech-to-translated-text in one step
- Simple, clean UI with minimal setup required
- Local-first: recordings and transcriptions stay on the user's machine
- Menu bar integration for quick access
- Export/copy transcribed text to clipboard

## Tech Stack (TBD)

The technology choices are still being evaluated. Likely candidates:

- **Framework**: Electron, Tauri, or native macOS (Swift/AppKit)
- **Transcription**: OpenAI Whisper (local or API)
- **Translation**: OpenAI Whisper API supports transcription-with-translation natively; for local-only mode, a translation layer (e.g. LibreTranslate or a local LLM) would be needed
- **Audio**: system microphone access via native APIs

## Project Status

Core v1 functionality is implemented (hotkey, recording, transcription, translation, menu bar flow).
Current phase is stabilization and hardening based on `todo/audit-2026-03-05.md`.

## Current Execution Mode

- Active implementation track is defined in `todo/audit-remediation-plan.md`
- While remediation mode is active in `todo/roadmap.md`, do not auto-pick epic tasks
- Resume epic/task progression only when explicitly requested by the user

## Development Notes for Claude

- This is a macOS-first desktop app, so prioritize native macOS APIs and UX patterns when applicable
- Keep the UX minimal and low-friction — users should be able to record in one or two keystrokes
- Local-first is a strong preference: avoid requiring internet connectivity for core recording functionality
- When in doubt about architecture decisions, favor simplicity over extensibility at this stage
- The focus-and-paste feature requires a **global hotkey** (registered system-wide, not just when Murmur is focused) and **Accessibility API access** (to programmatically paste into whichever input field the user clicked into); this is a core permission to request on first launch
- Paste should be done via simulating Cmd+V or writing to the clipboard, targeting the currently focused element
