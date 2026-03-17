# Murmur

**Voice-to-meaning, not voice-to-text.**

Speak in your language. Get text in any other.

A macOS menu bar tool that captures your voice and delivers clean, natural text in the language you need. Not a word-by-word translation. Murmur understands what you mean and writes it the way a native speaker would.

## The Problem

Writing in a non-native language is slow. You either:

- Write in your language, paste into a translator, then fix the awkward result
- Write directly in the target language, second-guessing every word, looking things up, re-reading to check if it sounds right
- Use AI to translate, then spend time editing because the output is too literal or off-tone

This gets worse when you work with AI agents, where English is the better choice (fewer tokens, better model comprehension), but thinking happens in your native language.

## The Solution

Press a hotkey. Say what you mean. Get a ready-to-send message in the language you need.

```
Option+Space  →  speak in any language  →  Option+Space
                                               ↓
                                 clean text appears where you type
```

Murmur doesn't translate word by word. It takes your spoken thought, removes filler and verbal noise, and produces text that follows the grammar, tone, and conventions of the target language. The result reads like it was written, not translated.

## How It Works

1. **Press the hotkey** (default `Option + Space`). A recording indicator appears.
2. **Speak** in any language. Say it however you think it.
3. **Click** into any text field (browser, editor, messenger, terminal).
4. **Press the hotkey again**. Text appears where you need it.

No app switching. No copy-paste. No editing.

## Three Modes

- **Transcription**: raw speech-to-text in the spoken language.
- **Clean-up**: same language, but cleaned up. No filler words, proper grammar, structured sentences. Enumerations automatically formatted as lists.
- **Translation**: speak in one language, get clean text in another. 97 languages supported. Same cleanup applies: the output reads like it was written by a native speaker, not translated.

## Install

Download `Murmur.dmg` from [Releases](https://github.com/alexe-ev/Murmur/releases), drag to Applications.

> Not notarized. First launch: right-click the app, then Open.

### Build from Source

```bash
git clone https://github.com/alexe-ev/Murmur.git
cd Murmur
xcodebuild -scheme Murmur -configuration Release -derivedDataPath build
cp -R build/Build/Products/Release/Murmur.app /Applications/
```

### Setup

On first launch, grant **Microphone** and **Accessibility** permissions. Enter your [OpenAI API key](https://platform.openai.com/api-keys) in Settings.

## Requirements

- macOS 13.0+ (Ventura or later)
- Apple Silicon (M1/M2/M3/M4)
- OpenAI API key

Audio recordings are temporary and deleted right after transcription. Your API key is stored locally on your machine.

## License

[MIT](LICENSE)
