# Murmur

A lightweight macOS menu bar app that turns your voice into text anywhere on your system. Press a hotkey, speak, click into any text field, press the hotkey again. Murmur transcribes (and optionally translates) your speech and pastes the result right where you need it.

## How It Works

```
Option+Space  →  speak  →  click into any text field  →  Option+Space
                                                            ↓
                                              text appears in the field
```

1. **Press the hotkey** (default: `Option + Space`). A floating indicator appears.
2. **Speak** in any language.
3. **Click** into any text input (browser, editor, messenger, terminal).
4. **Press the hotkey again**. Murmur stops recording, transcribes, and pastes the result.

No windows to switch to, no copy-paste dance.

## Features

- **Focus-and-paste**: transcribed text goes directly into whichever input is focused.
- **Cloud transcription**: OpenAI Whisper API, 97 supported languages.
- **3 output modes**: Transcription (raw), Clean-up (grammar + filler removal), Translation.
- **97 target languages** for translation.
- **Menu bar only**: lives in the menu bar, no Dock icon.
- **Animated recording indicator**: floating pill with cancel button, collapses to a spinner during processing.
- **Silent recording detection**: skips transcription when no speech is detected (prevents Whisper hallucinations).
- **Configurable hotkey**: change the global shortcut in Settings.
- **ESC to cancel**: discard recording without transcription.
- **Clipboard-friendly**: optionally restores clipboard contents after pasting.

## Requirements

- **macOS 13.0+** (Ventura or later)
- **Apple Silicon** (M1/M2/M3/M4)
- **OpenAI API key** for transcription
- **Permissions**: Microphone + Accessibility (for pasting into other apps)

## Install

### From Release

Download `Murmur.dmg` from [Releases](https://github.com/alexe-ev/Murmur/releases), open it, drag `Murmur.app` to Applications.

> The app is not notarized. On first launch: right-click → Open (or allow in System Settings → Privacy & Security).

### Build from Source

Requires Xcode 16+.

```bash
git clone https://github.com/alexe-ev/Murmur.git
cd Murmur
xcodebuild -scheme Murmur -configuration Release -derivedDataPath build
cp -R build/Build/Products/Release/Murmur.app /Applications/
```

Or open `Murmur.xcodeproj` in Xcode and press `Cmd + R`.

### First Launch

Murmur shows an onboarding screen requesting two permissions:

- **Microphone**: needed to capture your voice.
- **Accessibility**: needed to paste text into other apps via simulated `Cmd+V`.

Then enter your OpenAI API key in Settings (Transcription tab).

## Architecture

```
Murmur/
├── App/                  # Entry point, AppDelegate, flow coordinators
├── Core/                 # AudioRecorder, HotkeyManager, PasteController, Permissions
├── Transcription/        # OpenAI Whisper API service
├── Translation/          # Language configuration
├── Settings/             # UserDefaults preferences, file-based API key storage
└── UI/                   # Menu bar, settings window, onboarding, recording indicator
```

| Component | Role |
|---|---|
| `HotkeyManager` | System-wide hotkey via Carbon API |
| `AudioRecorder` | Mic input as 16 kHz mono WAV via AVFoundation, RMS-based speech detection |
| `RecordingFlowCoordinator` | State machine: idle → recording → processing → idle |
| `TranscriptionCoordinator` | Manages transcription requests via OpenAI API |
| `OpenAIWhisperService` | Transcription + cleanup + translation via OpenAI API |
| `PasteController` | Text insertion via Accessibility API or clipboard + `Cmd+V` |
| `MenuBarController` | NSStatusItem menu with state icons, output mode and language pickers |

### Data Flow

```
Hotkey pressed → AudioRecorder.start()
                        ↓
              [user speaks, clicks into a field]
                        ↓
Hotkey pressed → AudioRecorder.stop() → temp WAV file
                        ↓
              Silent? → discard, return to idle
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

Two tabs, accessible from the menu bar dropdown:

- **Transcription**: OpenAI API key, speech language
- **Settings**: hotkey, output mode, target language, launch at login, restore clipboard

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
| Build | Xcode 16+, arm64 |

## Privacy

- **No telemetry**: Murmur does not phone home.
- **Temp files only**: audio recordings are deleted after transcription.
- **Local API key storage**: stored in `~/Library/Application Support/Murmur/`, never sent anywhere except OpenAI.
- **Clipboard respect**: optionally restores prior clipboard contents after pasting.

## License

[MIT](LICENSE)
