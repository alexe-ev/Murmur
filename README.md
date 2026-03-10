# Murmur

A lightweight macOS menu bar app that turns your voice into text — anywhere on your system. Press a hotkey, speak, click into any text field, press the hotkey again. Murmur transcribes (and optionally translates) your speech and pastes the result right where you need it.

## How It Works

```
Option+Space  →  speak  →  click into any text field  →  Option+Space
                                                            ↓
                                              text appears in the field
```

1. **Press the hotkey** (default: `Option + Space`) — recording starts, a floating indicator appears.
2. **Speak** in any language.
3. **Click** into any text input on your system (browser, editor, messenger, terminal — anything).
4. **Press the hotkey again** — Murmur stops recording, transcribes, and pastes the result into the focused field.

That's it. No windows to switch to, no copy-paste dance.

## Features

- **Focus-and-paste** — transcribed text goes directly into whichever input is focused. Zero extra steps.
- **On-device transcription** — uses [WhisperKit](https://github.com/argmaxinc/WhisperKit) to run Whisper models locally on Apple Silicon. No internet required for basic transcription.
- **Cloud transcription** — optional OpenAI Whisper API backend for users who prefer it or need translation.
- **Voice translation** — speak in one language, get text in another. Supports 12 target languages: English, Spanish, French, German, Italian, Portuguese, Chinese, Japanese, Korean, Russian, Arabic, Hindi.
- **Menu bar app** — lives in the menu bar, stays out of your way. No Dock icon.
- **Floating recording indicator** — a subtle, always-on-top panel shows when recording or processing is active.
- **Configurable hotkey** — change the global shortcut in Settings.
- **Clipboard-friendly** — optionally restores your clipboard contents after pasting so your clipboard history isn't polluted.
- **Local-first** — recordings and transcriptions stay on your machine. Audio files are cleaned up after use.

## Requirements

- **macOS 13.0+** (Ventura or later)
- **Apple Silicon** (M1/M2/M3/M4) — required for local WhisperKit transcription
- **Permissions**: Microphone access and Accessibility (for pasting into other apps)

## Getting Started

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/alexe-ev/Murmur.git
   cd Murmur
   ```

2. Open in Xcode 16+:
   ```bash
   open Murmur.xcodeproj
   ```

3. Build and run (`Cmd + R`). The app appears in the menu bar.

### First Launch

On first launch, Murmur shows an onboarding screen requesting two permissions:

- **Microphone** — needed to capture your voice.
- **Accessibility** — needed to paste text into other apps via simulated `Cmd+V`.

Grant both, and you're ready to go.

### Using the OpenAI API (Optional)

If you want cloud-based transcription or non-English translation:

1. Open **Settings** from the menu bar dropdown.
2. Go to the **Transcription** tab and select **API** as the backend.
3. Enter your OpenAI API key (stored securely in the macOS Keychain).

## Architecture

```
Murmur/
├── App/                  # Entry point, AppDelegate, flow coordinators
├── Core/                 # AudioRecorder, HotkeyManager, PasteController, Permissions
├── Transcription/        # WhisperKit (local) & OpenAI API services, model manager
├── Translation/          # Language configuration
├── Settings/             # UserDefaults preferences, Keychain for API keys
└── UI/                   # Menu bar, settings window, onboarding, recording indicator
```

| Component | Role |
|---|---|
| `HotkeyManager` | Registers a system-wide hotkey via Carbon API |
| `AudioRecorder` | Captures mic input as 16 kHz mono WAV via AVFoundation |
| `RecordingFlowCoordinator` | State machine: idle → recording → processing → idle |
| `TranscriptionCoordinator` | Picks the right backend (local or API) based on settings |
| `LocalWhisperService` | On-device Whisper inference via WhisperKit (arm64) |
| `OpenAIWhisperService` | Cloud transcription + translation via OpenAI API |
| `PasteController` | Inserts text via Accessibility API or clipboard + `Cmd+V` |
| `MenuBarController` | NSStatusItem menu with state icons and language pickers |

### Data Flow

```
Hotkey pressed → AudioRecorder.start()
                        ↓
              [user speaks, clicks into a field]
                        ↓
Hotkey pressed → AudioRecorder.stop() → temp WAV file
                        ↓
              TranscriptionCoordinator.transcribe()
                ├─ LocalWhisperService (on-device)
                └─ OpenAIWhisperService (cloud, optional translation)
                        ↓
              PasteController.paste(text)
                ├─ Try: direct AX text insertion
                └─ Fallback: clipboard + simulated Cmd+V
                        ↓
              Cleanup temp audio file
```

## Whisper Models

When using local transcription, Murmur downloads Whisper models on first use:

| Model | Size | Speed | Quality |
|---|---|---|---|
| `tiny` | ~75 MB | ~0.5s | Good for short notes |
| `base` | ~140 MB | ~1s | **Default.** Best balance. |
| `small` | ~460 MB | ~2-3s | Higher accuracy |

Models are stored in `~/Library/Application Support/Murmur/models/`.

## Settings

Accessible from the menu bar dropdown:

- **Recording** — hotkey configuration, speech language
- **Transcription** — backend (local / API), Whisper model selection, API key
- **Translation** — enable/disable, target language
- **General** — launch at login, restore clipboard after paste

## Tech Stack

| | |
|---|---|
| Language | Swift 5.0 |
| UI | SwiftUI + AppKit |
| Audio | AVFoundation |
| Local transcription | WhisperKit (Core ML) |
| Cloud transcription | OpenAI Whisper API |
| Translation | OpenAI Chat Completions API |
| Hotkey | Carbon `RegisterEventHotKey` |
| Paste | Accessibility API + CGEvent |
| Secrets | macOS Keychain |
| Build | Xcode 16+, arm64 |

## Privacy

- **Local-first**: core recording and transcription work entirely offline (with local backend).
- **No telemetry**: Murmur does not phone home.
- **Temp files only**: audio recordings are written to a temporary directory and deleted after transcription.
- **Keychain storage**: your OpenAI API key is stored in the macOS Keychain with Data Protection, never in plain text.
- **Clipboard respect**: optionally restores prior clipboard contents after pasting.

## License

All rights reserved. This is a private project.
