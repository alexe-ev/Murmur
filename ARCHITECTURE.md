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

### 3.1 Logical Components

```
Murmur.app
├── AppDelegate                  # App entry point, core flow coordinator, permission checks
├── MenuBarController            # NSStatusItem, icon state management, dropdown menu
├── HotkeyManager                # Global hotkey registration and event handling (Carbon)
├── AudioRecorder                # AVFoundation microphone capture, 16kHz mono WAV, temp file
├── TranscriptionService         # Protocol + implementations: LocalWhisperService, OpenAIWhisperService
├── ModelManager                 # WhisperKit model download, storage, selection
├── TranslationConfig            # Target language selection, translation mode toggle, auto-backend enforcement
├── PasteController              # Clipboard write + Cmd+V simulation via CGEvent
├── PermissionsManager           # Microphone + Accessibility permission check/request
├── KeychainManager              # OpenAI API key secure storage (Keychain)
└── SettingsView                 # SwiftUI settings window (hotkey, backend, model, language, login item)
```

### 3.2 File Structure

```
Murmur/
├── Murmur.xcodeproj/
└── Murmur/
    ├── App/
    │   ├── MurmurApp.swift             # @main, NSApplicationDelegateAdaptor
    │   ├── AppDelegate.swift           # Entry point, coordinator, startRecordingFlow / stopRecordingFlow
    │   └── Info.plist                  # LSUIElement=YES (hides from Dock)
    ├── Core/
    │   ├── HotkeyManager.swift         # Carbon RegisterEventHotKey, system-wide toggle, onToggle callback
    │   ├── AudioRecorder.swift         # AVFoundation, 16kHz mono WAV, temp file, RecordingState publisher
    │   ├── PasteController.swift       # NSPasteboard + CGEvent Cmd+V simulation
    │   └── PermissionsManager.swift    # Microphone + Accessibility check/request, polling
    ├── Transcription/
    │   ├── TranscriptionService.swift  # Protocol: transcribe(audioURL:targetLanguage:) async throws -> String
    │   ├── LocalWhisperService.swift   # WhisperKit on-device implementation
    │   ├── OpenAIWhisperService.swift  # OpenAI API implementation (/transcriptions + /translations + chat)
    │   └── ModelManager.swift          # WhisperKit model download, ~/Library/Application Support/Murmur/
    ├── Translation/
    │   └── TranslationConfig.swift     # Translation toggle, language selection, requiresAPI, supportedLanguages
    ├── Settings/
    │   ├── SettingsModel.swift         # UserDefaults wrapper — all 7 preference keys with defaults
    │   └── KeychainManager.swift       # OpenAI API key secure storage (kSecClassGenericPassword)
    └── UI/
        ├── MenuBarController.swift     # NSStatusItem, MenuBarState enum, floating indicator show/hide
        ├── RecordingIndicatorView.swift # Floating always-on-top NSPanel (borderless, .floating level)
        ├── SettingsView.swift          # Full SwiftUI settings window (all pickers, API key SecureField)
        └── OnboardingView.swift        # First-launch permission request screen
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
- Default hotkey: **Option + Space** (keyCode 49, modifier `optionKey`)

---

## 6. Audio Recording

- **Format**: record as uncompressed PCM (WAV) for best Whisper compatibility, or compressed m4a and convert before sending
- **Sample rate**: 16 kHz mono — Whisper's native input format
- **Buffer**: held in memory during recording; written to a temp file for Whisper input; deleted immediately after transcription

---

## 7. Transcription & Translation

### Local (default for transcription)

- Uses **WhisperKit** — a Swift package that runs Whisper models natively via Core ML
- Model is downloaded once and stored in `~/Library/Application Support/Murmur/`
- **Default model**: `whisper-base` — good balance of speed (~1s on M1) and accuracy
- **User-selectable**: `tiny` (fastest, ~0.5s, lower accuracy) / `base` (default) / `small` (~2-3s, best accuracy)
- Local mode supports **transcription only** — output language = spoken language
- Translation in local mode: WhisperKit can translate any language → English via Whisper's built-in translation task; non-English target languages are **not supported locally** (use API)

### API (required for translation to non-English; optional for transcription)

- Calls **OpenAI Whisper API** (`/v1/audio/transcriptions` or `/v1/audio/translations`)
- The `/translations` endpoint outputs English from any input language
- For non-English target languages: chain Whisper transcription with an OpenAI Chat Completions call for translation
- API key stored securely in **macOS Keychain**
- **v1 rule**: if translation mode is enabled with a non-English target language, API backend is required; the app will prompt the user to enter an API key if one is not set

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
| `hotkeyKeyCode` | Int | 49 (Space) |
| `hotkeyModifiers` | Int | optionKey (0x00080000) |
| `translationEnabled` | Bool | false |
| `targetLanguage` | String | "en" |
| `whisperBackend` | String | "local" |
| `whisperModel` | String | "base" |
| `launchAtLogin` | Bool | false |

OpenAI API key stored in **Keychain** (never in UserDefaults).

---

## 11. Architecture Decisions Log

| Question | Decision |
|---|---|
| Default hotkey | Option + Space (keyCode 49, optionKey modifier) |
| Local translation to non-English | **Not supported in v1** — API required for non-English target languages |
| Default Whisper model | **`whisper-base`** — ~1s on M1, good accuracy; user can select `tiny`/`base`/`small` in Settings |
| Streaming transcription | Not in scope for v1; evaluate for v2 |
