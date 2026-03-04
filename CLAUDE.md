# Murmur

## What is Murmur?

Murmur is a desktop voice recording tool for macOS. It lets users effortlessly capture their voice — whether for quick notes, memos, ideas, or messages — with minimal friction. Think of it as a whisper app: a lightweight, always-available tool that makes it easy for anyone to record their voice and do something useful with it.

## Core Concept

The goal is to make voice recording feel as natural and instant as typing a note. Murmur sits quietly in the background (menu bar or dock) and is ready whenever you need to capture a thought out loud.

## Platform

- **Primary target**: macOS (desktop app)
- **Future platforms**: potentially iOS, Windows, Linux

## Key Features (Planned)

- One-click or hotkey-triggered voice recording
- Automatic transcription of recorded audio (via Whisper or similar)
- Simple, clean UI with minimal setup required
- Local-first: recordings and transcriptions stay on the user's machine
- Menu bar integration for quick access
- Export/copy transcribed text to clipboard

## Tech Stack (TBD)

The technology choices are still being evaluated. Likely candidates:

- **Framework**: Electron, Tauri, or native macOS (Swift/AppKit)
- **Transcription**: OpenAI Whisper (local or API)
- **Audio**: system microphone access via native APIs

## Project Status

Early stage — the project is in the initial design and planning phase.

## Development Notes for Claude

- This is a macOS-first desktop app, so prioritize native macOS APIs and UX patterns when applicable
- Keep the UX minimal and low-friction — users should be able to record in one or two keystrokes
- Local-first is a strong preference: avoid requiring internet connectivity for core recording functionality
- When in doubt about architecture decisions, favor simplicity over extensibility at this stage
