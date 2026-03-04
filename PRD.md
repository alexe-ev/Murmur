# Murmur — Product Requirements Document

**Version**: 0.1
**Date**: 2026-03-04
**Status**: Draft

---

## 1. Overview

Murmur is a macOS desktop app that lets users record their voice and instantly get the transcribed (and optionally translated) text pasted into any text field on their system. The experience is designed to feel as fast and natural as typing — with zero extra steps between speaking and having your words appear on screen.

---

## 2. Problem Statement

Typing is slow. Dictation tools either require switching context (open an app, record, copy, paste) or are locked to specific apps. Users who think faster than they type — or who want to communicate in a language they don't type fluently — have no lightweight, universal solution that works everywhere on the desktop.

---

## 3. Target Users

- Professionals who want to write faster (emails, Slack messages, notes)
- Multilingual users who speak one language but need to write in another
- People with repetitive strain injuries or accessibility needs
- Anyone who finds it easier to talk than type

---

## 4. Goals

- Make voice-to-text feel instant and frictionless on macOS
- Work in any app, any text field — system-wide
- Support multilingual output via voice translation
- Keep user data local by default; no mandatory cloud dependency

---

## 5. Non-Goals (v1)

- Mobile apps (iOS, Android) — future consideration
- Real-time streaming transcription (word-by-word as you speak)
- Speaker diarization or multi-speaker support
- Audio file import or editing
- Cloud sync or account system

---

## 6. Core User Flow

```
1. User presses global hotkey  →  recording starts (visual indicator appears)
2. User clicks into any text field in any app on the system
3. User speaks
4. User presses hotkey again  →  recording stops
5. Murmur transcribes the audio (and translates if a target language is set)
6. Result is pasted directly into the focused text field
```

The entire flow from hotkey to pasted text should feel near-instant (target: under 2 seconds for short clips on a local model).

---

## 7. Features

### 7.1 Focus-and-Paste Recording (Core)

- A **global hotkey** (user-configurable, default TBD) starts and stops recording from anywhere on the system
- While recording, the user can click into any text input — browser fields, native app inputs, terminals, chat apps, etc.
- On stop, the transcribed/translated text is pasted into the currently focused input via the system clipboard (simulating Cmd+V)
- A subtle floating indicator shows that recording is active

### 7.2 Automatic Transcription

- Audio is transcribed using OpenAI Whisper (API or local model)
- Supports all languages Whisper supports
- Default mode: transcribe in the same language the user speaks

### 7.3 Voice Translation

- Optional mode: user selects a **target language** from a language picker (in the menu bar or settings)
- When enabled: user speaks in any language, output is delivered in the target language
- Example: speak English, paste Spanish
- Toggle should be easily accessible — one click from the menu bar

### 7.4 Menu Bar Integration

- Murmur lives in the macOS menu bar — no Dock icon required
- Menu bar icon changes state (idle / recording / processing)
- Quick access to: start/stop recording, language picker, settings, quit

### 7.5 Settings

- Configure global hotkey
- Select transcription mode (transcribe only vs. translate)
- Select target language for translation
- Choose Whisper backend: local model vs. OpenAI API (requires API key)
- Toggle: launch at login

---

## 8. Permissions Required

| Permission | Why |
|---|---|
| Microphone | Capture audio for recording |
| Accessibility API | Paste text into focused input fields in other apps |
| (Optional) Network | Required only if using OpenAI Whisper API backend |

Both Microphone and Accessibility permissions will be requested on first launch with clear explanations.

---

## 9. UX Principles

- **One interaction, one result**: press hotkey, speak, press hotkey — done
- **Invisible when idle**: Murmur should not distract when not in use
- **Fast feedback**: the recording indicator must appear immediately on hotkey press; no perceptible lag
- **Never block the user**: if transcription fails, fail silently with a brief notification — never freeze the input

---

## 10. Success Metrics (Initial)

- Time from hotkey-stop to text pasted: < 2s for clips under 15 seconds
- User can complete the full flow without opening Murmur's main window
- Zero data leaves the device when using the local Whisper backend

---

## 11. Open Questions

- What is the default hotkey? (needs to avoid conflicts with common apps)
- Should translation require an internet connection in v1, or invest in a local translation layer?
- Should there be a history/log of past recordings and transcriptions?
- How should Murmur handle background noise or silence-only recordings?
