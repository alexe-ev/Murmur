# Murmur — Architecture

**Version**: 0.2
**Date**: 2026-03-05
**Status**: Active (v1 hardening)

---

## 1. Overview

Murmur is a native macOS menu bar application. Its core job is to:

1. Listen for a global hotkey system-wide
2. Capture microphone audio
3. Send audio to OpenAI Whisper API for transcription/translation
4. Paste the resulting text into the currently focused input field

The architecture is intentionally minimal. There is no server, no database, no account system. Everything runs on the user's machine.

---

## 2. Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Language | **Swift** | Native macOS, best access to system APIs |
| UI Framework | **SwiftUI + AppKit** | SwiftUI for settings UI; AppKit for menu bar (`NSStatusItem`) |
| Audio capture | **AVFoundation** | Native macOS audio recording API |
| Transcription | **OpenAI Whisper API** | Cloud transcription, cleanup, and translation |
| Global hotkey | **Carbon / CGEvent tap** | Required for system-wide key event listening |
| Paste mechanism | **NSPasteboard + CGEvent (Cmd+V)** | Write text to clipboard, simulate Cmd+V into focused app |
| Accessibility | **AXUIElement (Accessibility API)** | Identify and target the focused UI element |
| Persistence | **UserDefaults** | Lightweight storage for settings (hotkey, language, backend choice) |

---

## 3. Component Breakdown

### 3.1 Logical Components

```
Murmur.app
├── AppDelegate                  # App entry point, startup/window orchestration
├── RecordingFlowCoordinator     # Recording lifecycle coordinator (start/stop/process/cleanup)
├── TranscriptionCoordinator     # Backend policy + request orchestration for transcription
├── MenuBarController            # NSStatusItem, icon state management, dropdown menu
├── HotkeyManager                # Global hotkey registration and event handling (Carbon)
├── AudioRecorder                # AVFoundation microphone capture, 16kHz mono WAV, temp file
├── TranscriptionService         # Protocol + OpenAIWhisperService implementation
├── TranslationConfig            # Target language selection, output mode configuration
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
    │   ├── AppDelegate.swift           # Entry point, startup flow + windows/hotkey orchestration
    │   ├── RecordingFlowCoordinator.swift # Recording flow coordinator (record/process/paste/cleanup)
    │   ├── TranscriptionCoordinator.swift # Backend enforcement + explicit request assembly
    │   └── Info.plist                  # LSUIElement=YES (hides from Dock)
    ├── Core/
    │   ├── HotkeyManager.swift         # Carbon RegisterEventHotKey, system-wide toggle, onToggle callback
    │   ├── AudioRecorder.swift         # AVFoundation, 16kHz mono WAV, temp file, RecordingState publisher
    │   ├── PasteController.swift       # NSPasteboard + CGEvent Cmd+V simulation
    │   └── PermissionsManager.swift    # Microphone + Accessibility check/request, polling
    ├── Transcription/
    │   ├── TranscriptionService.swift  # Protocol: transcribe(audioURL:request:) async throws -> String
    │   └── OpenAIWhisperService.swift  # OpenAI API implementation (/transcriptions + chat completions)
    ├── Translation/
    │   └── TranslationConfig.swift     # Output mode, language selection, supportedLanguages
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
  TranscriptionService.transcribe(audio, request)
        │         │
        │         └─ OpenAIWhisperService (API call)
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

All transcription uses **OpenAI Whisper API** (`/v1/audio/transcriptions`). API key is required and stored securely in **macOS Keychain**.

Three output modes:
- **Transcription**: raw speech-to-text output
- **Clean-up**: transcribes then cleans up grammar, filler words via GPT-4o
- **Translation**: transcribes then translates to a target language via GPT-4o

If no API key is configured, the app prompts the user to add one in Settings.

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
| `outputMode` | String | "transcription" |
| `speechLanguage` | String | "en" |
| `targetLanguage` | String | "en" |
| `launchAtLogin` | Bool | false |
| `restoreClipboardAfterPaste` | Bool | true |

OpenAI API key stored in **Keychain** (never in UserDefaults).

---

## 11. Architecture Decisions Log

| Question | Decision |
|---|---|
| Default hotkey | Option + Space (keyCode 49, optionKey modifier) |
| Transcription backend | **OpenAI API only**. Local WhisperKit was removed: worked poorly and all valuable features (cleanup, translation) required API anyway. |
| App toolchain baseline | **Swift 5 language mode + Xcode 16+ toolchain**. |
| Target architectures | **arm64 only**. |
| Streaming transcription | Not in scope for v1; evaluate for v2 |
