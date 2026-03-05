# Roadmap

This file is the **agent's entry point** for all task work.
Open this first, find the next task, then read the full context before touching any code.

---

## How to read this file

- Epics are listed in priority order (top = highest priority)
- Each epic links to its detail file
- Statuses are kept in sync with the individual task files
- **Next task to pick up** = the first `pending` task in the first non-`done` epic

---

## Quick Links

| Document | Purpose |
|---|---|
| `todo/roadmap.md` | This file — task navigation and status overview |
| `todo/bugs.md` | Global bug log — all found bugs, fixes, and pre-release re-verification |
| `todo/RULES.md` | Full conventions for epics, tasks, bugs, and agent workflow |

---

## Current Focus

> **E2 — Permissions & Onboarding** is the active epic.
> Next up: **E2-TASK-04** ([TEST] Permissions & Onboarding — Integration & Testing).
>
> Before picking up any task: read `CLAUDE.md`, `ARCHITECTURE.md`, `PRD.md`, this file,
> and the full epic file for the task you are about to start. See `RULES.md §Agent Workflow`.

---

## Epics

| # | Epic | File | Status | Progress |
|---|---|---|---|---|
| E1 | Project Skeleton & App Foundation | `todo/e1-foundation.md` | `in progress` | 4 / 5 |
| E2 | Permissions & Onboarding | `todo/e2-permissions.md` | `in progress` | 3 / 4 |
| E3 | Global Hotkey | `todo/e3-hotkey.md` | `pending` | 0 / 4 |
| E4 | Audio Recording | `todo/e4-audio.md` | `pending` | 0 / 4 |
| E5 | Menu Bar UI | `todo/e5-menubar.md` | `pending` | 0 / 5 |
| E6 | Local Transcription (WhisperKit) | `todo/e6-transcription-local.md` | `pending` | 0 / 5 |
| E7 | Paste & Core Flow Integration | `todo/e7-paste-flow.md` | `pending` | 0 / 4 |
| E8 | API Backend & Settings UI | `todo/e8-api-settings.md` | `pending` | 0 / 5 |
| E9 | Voice Translation | `todo/e9-translation.md` | `pending` | 0 / 6 |

---

## Epic Detail

---

### Epic E1 — Project Skeleton & App Foundation

**File**: `todo/e1-foundation.md`
**Status**: `in progress`
**Depends on**: None

| Task | Title | Status |
|---|---|---|
| E1-TASK-01 | Create Xcode project | `done` |
| E1-TASK-02 | Implement MurmurApp + AppDelegate skeleton | `done` |
| E1-TASK-03 | Implement SettingsModel (UserDefaults wrapper) | `done` |
| E1-TASK-04 | LaunchAtLogin via SMAppService | `done` |
| E1-TASK-05 | [TEST] Project Skeleton & App Foundation — Integration & Testing | `in progress` |

---

### Epic E2 — Permissions & Onboarding

**File**: `todo/e2-permissions.md`
**Status**: `in progress`
**Depends on**: E1

| Task | Title | Status |
|---|---|---|
| E2-TASK-01 | Implement PermissionsManager | `done` |
| E2-TASK-02 | Build OnboardingView | `done` |
| E2-TASK-03 | Integrate onboarding into launch flow | `done` |
| E2-TASK-04 | [TEST] Permissions & Onboarding — Integration & Testing | `pending` |

---

### Epic E3 — Global Hotkey

**File**: `todo/e3-hotkey.md`
**Status**: `pending`
**Depends on**: E1

| Task | Title | Status |
|---|---|---|
| E3-TASK-01 | Implement HotkeyManager core | `pending` |
| E3-TASK-02 | Wire toggle callback to AppDelegate | `pending` |
| E3-TASK-03 | Configurable hotkey (persist and re-register on change) | `pending` |
| E3-TASK-04 | [TEST] Global Hotkey — Integration & Testing | `pending` |

---

### Epic E4 — Audio Recording

**File**: `todo/e4-audio.md`
**Status**: `pending`
**Depends on**: E1, E2

| Task | Title | Status |
|---|---|---|
| E4-TASK-01 | Implement AudioRecorder (AVFoundation setup, 16kHz mono WAV) | `pending` |
| E4-TASK-02 | Temp file management | `pending` |
| E4-TASK-03 | Recording state machine (Combine publisher) | `pending` |
| E4-TASK-04 | [TEST] Audio Recording — Integration & Testing | `pending` |

---

### Epic E5 — Menu Bar UI

**File**: `todo/e5-menubar.md`
**Status**: `pending`
**Depends on**: E1

| Task | Title | Status |
|---|---|---|
| E5-TASK-01 | MenuBarController skeleton (NSStatusItem + basic dropdown) | `pending` |
| E5-TASK-02 | Icon state management (idle / recording / processing) | `pending` |
| E5-TASK-03 | Floating recording indicator (NSPanel) | `pending` |
| E5-TASK-04 | Dropdown menu (wired to AppDelegate actions) | `pending` |
| E5-TASK-05 | [TEST] Menu Bar UI — Integration & Testing | `pending` |

---

### Epic E6 — Local Transcription (WhisperKit)

**File**: `todo/e6-transcription-local.md`
**Status**: `pending`
**Depends on**: E1, E4

| Task | Title | Status |
|---|---|---|
| E6-TASK-01 | Define TranscriptionService protocol | `pending` |
| E6-TASK-02 | Add WhisperKit Swift Package dependency | `pending` |
| E6-TASK-03 | Implement LocalWhisperService | `pending` |
| E6-TASK-04 | Implement ModelManager (download, store, select) | `pending` |
| E6-TASK-05 | [TEST] Local Transcription — Integration & Testing | `pending` |

---

### Epic E7 — Paste & Core Flow Integration

**File**: `todo/e7-paste-flow.md`
**Status**: `pending`
**Depends on**: E2, E3, E4, E5, E6

| Task | Title | Status |
|---|---|---|
| E7-TASK-01 | Implement PasteController | `pending` |
| E7-TASK-02 | Wire core flow in AppDelegate | `pending` |
| E7-TASK-03 | Error handling (transcription failure → user notification) | `pending` |
| E7-TASK-04 | [TEST] Paste & Core Flow — Integration & Testing | `pending` |

---

### Epic E8 — API Backend & Settings UI

**File**: `todo/e8-api-settings.md`
**Status**: `pending`
**Depends on**: E6, E7

| Task | Title | Status |
|---|---|---|
| E8-TASK-01 | Implement KeychainManager | `pending` |
| E8-TASK-02 | Implement OpenAIWhisperService | `pending` |
| E8-TASK-03 | Backend switching in AppDelegate | `pending` |
| E8-TASK-04 | Build full SettingsView | `pending` |
| E8-TASK-05 | [TEST] API Backend & Settings UI — Integration & Testing | `pending` |

---

### Epic E9 — Voice Translation

**File**: `todo/e9-translation.md`
**Status**: `pending`
**Depends on**: E8

| Task | Title | Status |
|---|---|---|
| E9-TASK-01 | Implement TranslationConfig | `pending` |
| E9-TASK-02 | English target translation via /v1/audio/translations | `pending` |
| E9-TASK-03 | Non-English target translation via Chat Completions chaining | `pending` |
| E9-TASK-04 | Auto-backend enforcement | `pending` |
| E9-TASK-05 | Language picker in menu bar and SettingsView | `pending` |
| E9-TASK-06 | [TEST] Voice Translation — Integration & Testing | `pending` |

---

> **Agent workflow rules** are defined in `todo/RULES.md` — read it before picking up any task.
