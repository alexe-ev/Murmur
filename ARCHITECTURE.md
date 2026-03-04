# Murmur — Architecture

**Version**: 0.1
**Date**: 2026-03-04
**Status**: Draft

---

## 1. Overview

Murmur is a native macOS menu bar application. Its core job is to:

1. Listen for a global hotkey system-wide
2. Capture microphone audio
3. Send audio to a Whisper model (local or API) for transcription/translation
4. Paste the resulting text into the currently focused input field

The architecture is intentionally minimal. There is no server, no database, no account system. Everything runs on the user's machine.

---

## 2. Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Language | **Swift** | Native macOS, best access to system APIs |
| UI Framework | **SwiftUI + AppKit** | SwiftUI for settings UI; AppKit for menu bar (`NSStatusItem`) |
| Audio capture | **AVFoundation** | Native macOS audio recording API |
| Transcription (local) | **WhisperKit** | Swift-native Whisper inference, runs fully on-device via Core ML |
| Transcription (API) | **OpenAI Whisper API** | Fallback/option for users who prefer cloud; supports translation natively |
| Global hotkey | **Carbon / CGEvent tap** | Required for system-wide key event listening |
| Paste mechanism | **NSPasteboard + CGEvent (Cmd+V)** | Write text to clipboard, simulate Cmd+V into focused app |
| Accessibility | **AXUIElement (Accessibility API)** | Identify and target the focused UI element |
| Persistence | **UserDefaults** | Lightweight storage for settings (hotkey, language, backend choice) |

---

## 3. Component Breakdown

```
Murmur.app
├── AppDelegate                  # App entry point, menu bar setup, permission checks
├── MenuBarController            # NSStatusItem, icon state management, dropdown menu
├── HotkeyManager                # Global hotkey registration and event handling
├── AudioRecorder                # AVFoundation microphone capture, audio buffer management
├── TranscriptionService         # Protocol + implementations: LocalWhisper, OpenAIWhisper
├── TranslationConfig            # Target language selection, translation mode toggle
├── PasteController              # Clipboard write + Cmd+V simulation via CGEvent
└── SettingsView                 # SwiftUI settings window (hotkey, language, backend, login item)
```

---

## 4. Core Data Flow

```
[Global Hotkey Press]
        │
        ▼
  HotkeyManager detects keydown
        │
        ▼
  AudioRecorder.startRecording()     ← AVFoundation opens mic
  MenuBarController → icon: recording
        │
  [User clicks into target input field]
        │
  [Global Hotkey Press again]
        │
        ▼
  AudioRecorder.stopRecording()      ← returns audio buffer (m4a/wav)
        │
        ▼
  TranscriptionService.transcribe(audio, targetLanguage?)
        │         │
        │         ├─ LocalWhisper (WhisperKit, on-device)
        │         └─ OpenAIWhisper (API call, requires network)
        │
        ▼
  PasteController.paste(text)
        ├─ NSPasteboard.general.setString(text)
        └─ CGEvent: simulate Cmd+V → focused app receives paste
        │
        ▼
  MenuBarController → icon: idle
```

---

## 5. Global Hotkey

- Registered using a **CGEvent tap** (low-level) or the **Carbon `RegisterEventHotKey`** API
- Must be registered system-wide (not just when Murmur is frontmost)
- User can configure the hotkey in Settings; stored in `UserDefaults`
- Default hotkey: TBD (needs conflict analysis against common macOS shortcuts)

---

## 6. Audio Recording

- **Format**: record as uncompressed PCM (WAV) for best Whisper compatibility, or compressed m4a and convert before sending
- **Sample rate**: 16 kHz mono — Whisper's native input format
- **Buffer**: held in memory during recording; written to a temp file for Whisper input; deleted immediately after transcription

---

## 7. Transcription & Translation

### Local (default)

- Uses **WhisperKit** — a Swift package that runs Whisper models natively via Core ML
- Model is downloaded once and stored in `~/Library/Application Support/Murmur/`
- Recommended default model: `whisper-base` or `whisper-small` (balance of speed and accuracy)
- Translation: WhisperKit supports Whisper's built-in translation task (speak any language → English output). For non-English target languages, a second-pass translation step would be needed.

### API (optional)

- Calls **OpenAI Whisper API** (`/v1/audio/transcriptions` or `/v1/audio/translations`)
- The `/translations` endpoint natively outputs English from any input language
- For other target languages via API: chain with OpenAI Chat Completions for translation
- API key stored securely in **macOS Keychain**

---

## 8. Paste Mechanism

1. Transcription result is written to `NSPasteboard.general`
2. A `CGEvent` (key down + key up for Cmd+V) is posted to the system event stream
3. The currently focused application receives the paste event and inserts the text

This approach works universally across all macOS apps without needing to know which app is in focus.

**Requirement**: Murmur must have **Accessibility permission** granted in System Settings → Privacy & Security → Accessibility to post `CGEvent` keystrokes to other processes.

---

## 9. Permissions & First-Launch Flow

On first launch, Murmur will:

1. Request **Microphone** access via `AVCaptureDevice.requestAccess`
2. Check for **Accessibility** permission via `AXIsProcessTrusted()`; if not granted, show a prompt directing the user to System Settings

Both are required for core functionality. The app will display a clear onboarding screen explaining why each permission is needed before requesting them.

---

## 10. Settings Persistence

All user preferences stored in `UserDefaults`:

| Key | Type | Default |
|---|---|---|
| `hotkeyKeyCode` | Int | TBD |
| `hotkeyModifiers` | Int | TBD |
| `translationEnabled` | Bool | false |
| `targetLanguage` | String | "en" |
| `whisperBackend` | String | "local" |
| `launchAtLogin` | Bool | false |

OpenAI API key stored in **Keychain** (never in UserDefaults).

---

## 11. Open Architecture Questions

- **Translation to non-English languages locally**: WhisperKit's translation task only outputs English. A local LLM or LibreTranslate instance would be needed for local non-English translation — worth evaluating complexity vs. just requiring API for that feature.
- **Model size vs. speed tradeoff**: `whisper-tiny` is fastest but less accurate; `whisper-small` is a good default. Allow user to choose?
- **Streaming transcription**: not in scope for v1 but could improve perceived speed — worth evaluking for v2.
