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
- **Cloud transcription** — uses OpenAI Whisper API for high-quality speech-to-text.
- **Voice translation** — speak in one language, get text in another. Supports 12 target languages: English, Spanish, French, German, Italian, Portuguese, Chinese, Japanese, Korean, Russian, Arabic, Hindi.
- **Clean-up mode** — transcribes your speech and cleans up grammar, filler words, and formatting.
- **Menu bar app** — lives in the menu bar, stays out of your way. No Dock icon.
- **Floating recording indicator** — a subtle, always-on-top panel shows when recording or processing is active.
- **Configurable hotkey** — change the global shortcut in Settings.
- **Clipboard-friendly** — optionally restores your clipboard contents after pasting so your clipboard history isn't polluted.
- **Privacy-conscious** — audio files are cleaned up after use. API key stored in macOS Keychain.

## Requirements

- **macOS 13.0+** (Ventura or later)
- **Apple Silicon** (M1/M2/M3/M4)
- **OpenAI API key** — required for transcription
- **Permissions**: Microphone access and Accessibility (for pasting into other apps)

## Getting Started

### Install from Release

Download the latest `Murmur.app.zip` from [Releases](https://github.com/alexe-ev/Murmur/releases), unzip, and move `Murmur.app` to `/Applications`.

> The app is not notarized, so on first launch you may need to right-click -> Open (or allow it in System Settings -> Privacy & Security).

### Build from Source

Requires Xcode 16+ (or just the Command Line Tools with `xcodebuild`).

```bash
git clone https://github.com/alexe-ev/Murmur.git
cd Murmur

# Build
xcodebuild -scheme Murmur -configuration Release -derivedDataPath build

# The app bundle is at:
# build/Build/Products/Release/Murmur.app

# Copy to Applications (optional)
cp -R build/Build/Products/Release/Murmur.app /Applications/
```

Or open `Murmur.xcodeproj` in Xcode and press `Cmd + R`.

### First Launch

On first launch, Murmur shows an onboarding screen requesting two permissions:

- **Microphone** — needed to capture your voice.
- **Accessibility** — needed to paste text into other apps via simulated `Cmd+V`.

Grant both, and you're ready to go.

### OpenAI API Key

Murmur requires an OpenAI API key for transcription:

1. Open **Settings** from the menu bar dropdown.
2. Go to the **Transcription** tab.
3. Enter your OpenAI API key (stored securely in the macOS Keychain).

## Architecture

```
Murmur/
├── App/                  # Entry point, AppDelegate, flow coordinators
├── Core/                 # AudioRecorder, HotkeyManager, PasteController, Permissions
├── Transcription/        # OpenAI Whisper API service
├── Translation/          # Language configuration
├── Settings/             # UserDefaults preferences, Keychain for API keys
└── UI/                   # Menu bar, settings window, onboarding, recording indicator
```

| Component | Role |
|---|---|
| `HotkeyManager` | Registers a system-wide hotkey via Carbon API |
| `AudioRecorder` | Captures mic input as 16 kHz mono WAV via AVFoundation |
| `RecordingFlowCoordinator` | State machine: idle → recording → processing → idle |
| `TranscriptionCoordinator` | Manages transcription requests via OpenAI API |
| `OpenAIWhisperService` | Transcription + cleanup + translation via OpenAI API |
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
                └─ OpenAIWhisperService (transcription / cleanup / translation)
                        ↓
              PasteController.paste(text)
                ├─ Try: direct AX text insertion
                └─ Fallback: clipboard + simulated Cmd+V
                        ↓
              Cleanup temp audio file
```

## Settings

Accessible from the menu bar dropdown:

- **Recording** — hotkey configuration
- **Transcription** — speech language, OpenAI API key
- **Output** — output mode (transcription / clean-up / translation), target language
- **General** — launch at login, restore clipboard after paste

## Tech Stack

| | |
|---|---|
| Language | Swift 5.0 |
| UI | SwiftUI + AppKit |
| Audio | AVFoundation |
| Transcription | OpenAI Whisper API |
| Translation | OpenAI Chat Completions API |
| Hotkey | Carbon `RegisterEventHotKey` |
| Paste | Accessibility API + CGEvent |
| Secrets | macOS Keychain |
| Build | Xcode 16+, arm64 |

## Privacy

- **No telemetry**: Murmur does not phone home.
- **Temp files only**: audio recordings are written to a temporary directory and deleted after transcription.
- **Keychain storage**: your OpenAI API key is stored in the macOS Keychain with Data Protection, never in plain text.
- **Clipboard respect**: optionally restores prior clipboard contents after pasting.

## License

All rights reserved. This is a private project.
