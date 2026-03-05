# Roadmap

This file is the **agent's entry point** for all task work.
Open this first, find the next task, then read the full context before touching any code.

---

## How to read this file

- Epics are listed in priority order (top = highest priority)
- Each epic links to its detail file
- Statuses are kept in sync with the individual task files
- **Next task to pick up** = the first `pending` task in the first non-`done` epic
- Exception: when `Current Focus` declares an active remediation plan, use that plan first and do not auto-pick epic tasks

---

## Quick Links

| Document | Purpose |
|---|---|
| `todo/roadmap.md` | This file — task navigation and status overview |
| `todo/bugs.md` | Global bug log — all found bugs, fixes, and pre-release re-verification |
| `todo/RULES.md` | Full conventions for epics, tasks, bugs, and agent workflow |
| `todo/audit-2026-03-05.md` | Full audit findings and prioritized risk list |
| `todo/audit-remediation-plan.md` | Active implementation plan for fixing audit findings |

---

## Current Focus

> **Active mode: Audit Remediation**
> Execute `todo/audit-remediation-plan.md` in PR order (PR-1 .. PR-6).
>
> Do not auto-pick epic tasks while this mode is active.
> Epic work is resumed only on explicit user instruction.

---

## Audit Remediation Track

**Plan file**: `todo/audit-remediation-plan.md`  
**Source findings**: `todo/audit-2026-03-05.md`

| PR | Scope | Status |
|---|---|---|
| PR-1 | Release blockers (`C-01`, `C-02`, `C-03`) | `done` |
| PR-2 | Runtime stability (`H-01`, `H-02`, `M-03`) | `done` |
| PR-3 | Privacy/Security hardening (`H-03`, `L-02`) | `done` |
| PR-4 | Type-safety foundation (`M-01`) | `done` |
| PR-5 | Decoupling and readability (`M-02`, `L-01`) | `done` |
| PR-6 | Quality gates and process (`H-05`, `H-06`, `H-07`, `M-05`, `M-06`, `L-03`) | `done` |

---

## Epics

| # | Epic | File | Status | Progress |
|---|---|---|---|---|
| E1 | Project Skeleton & App Foundation | `todo/e1-foundation.md` | `done` | 5 / 5 |
| E2 | Permissions & Onboarding | `todo/e2-permissions.md` | `done` | 4 / 4 |
| E3 | Global Hotkey | `todo/e3-hotkey.md` | `done` | 4 / 4 |
| E4 | Audio Recording | `todo/e4-audio.md` | `done` | 4 / 4 |
| E5 | Menu Bar UI | `todo/e5-menubar.md` | `done` | 5 / 5 |
| E6 | Local Transcription (WhisperKit) | `todo/e6-transcription-local.md` | `done` | 5 / 5 |
| E7 | Paste & Core Flow Integration | `todo/e7-paste-flow.md` | `done` | 4 / 4 |
| E8 | API Backend & Settings UI | `todo/e8-api-settings.md` | `done` | 5 / 5 |
| E9 | Voice Translation | `todo/e9-translation.md` | `done` | 6 / 6 |

---

## Epic Detail

---

### Epic E1 — Project Skeleton & App Foundation

**File**: `todo/e1-foundation.md`
**Status**: `done`
**Depends on**: None

| Task | Title | Status |
|---|---|---|
| E1-TASK-01 | Create Xcode project | `done` |
| E1-TASK-02 | Implement MurmurApp + AppDelegate skeleton | `done` |
| E1-TASK-03 | Implement SettingsModel (UserDefaults wrapper) | `done` |
| E1-TASK-04 | LaunchAtLogin via SMAppService | `done` |
| E1-TASK-05 | [TEST] Project Skeleton & App Foundation — Integration & Testing | `done` |

---

### Epic E2 — Permissions & Onboarding

**File**: `todo/e2-permissions.md`
**Status**: `done`
**Depends on**: E1

| Task | Title | Status |
|---|---|---|
| E2-TASK-01 | Implement PermissionsManager | `done` |
| E2-TASK-02 | Build OnboardingView | `done` |
| E2-TASK-03 | Integrate onboarding into launch flow | `done` |
| E2-TASK-04 | [TEST] Permissions & Onboarding — Integration & Testing | `done` |

---

### Epic E3 — Global Hotkey

**File**: `todo/e3-hotkey.md`
**Status**: `done`
**Depends on**: E1

| Task | Title | Status |
|---|---|---|
| E3-TASK-01 | Implement HotkeyManager core | `done` |
| E3-TASK-02 | Wire toggle callback to AppDelegate | `done` |
| E3-TASK-03 | Configurable hotkey (persist and re-register on change) | `done` |
| E3-TASK-04 | [TEST] Global Hotkey — Integration & Testing | `done` |

---

### Epic E4 — Audio Recording

**File**: `todo/e4-audio.md`
**Status**: `done`
**Depends on**: E1, E2

| Task | Title | Status |
|---|---|---|
| E4-TASK-01 | Implement AudioRecorder (AVFoundation setup, 16kHz mono WAV) | `done` |
| E4-TASK-02 | Temp file management | `done` |
| E4-TASK-03 | Recording state machine (Combine publisher) | `done` |
| E4-TASK-04 | [TEST] Audio Recording — Integration & Testing | `done` |

---

### Epic E5 — Menu Bar UI

**File**: `todo/e5-menubar.md`
**Status**: `done`
**Depends on**: E1

| Task | Title | Status |
|---|---|---|
| E5-TASK-01 | MenuBarController skeleton (NSStatusItem + basic dropdown) | `done` |
| E5-TASK-02 | Icon state management (idle / recording / processing) | `done` |
| E5-TASK-03 | Floating recording indicator (NSPanel) | `done` |
| E5-TASK-04 | Dropdown menu (wired to AppDelegate actions) | `done` |
| E5-TASK-05 | [TEST] Menu Bar UI — Integration & Testing | `done` |

---

### Epic E6 — Local Transcription (WhisperKit)

**File**: `todo/e6-transcription-local.md`
**Status**: `done`
**Depends on**: E1, E4

| Task | Title | Status |
|---|---|---|
| E6-TASK-01 | Define TranscriptionService protocol | `done` |
| E6-TASK-02 | Add WhisperKit Swift Package dependency | `done` |
| E6-TASK-03 | Implement ModelManager (download, store, select) | `done` |
| E6-TASK-04 | Implement LocalWhisperService | `done` |
| E6-TASK-05 | [TEST] Local Transcription — Integration & Testing | `done` |

---

### Epic E7 — Paste & Core Flow Integration

**File**: `todo/e7-paste-flow.md`
**Status**: `done`
**Depends on**: E2, E3, E4, E5, E6

| Task | Title | Status |
|---|---|---|
| E7-TASK-01 | Implement PasteController | `done` |
| E7-TASK-02 | Wire core flow in AppDelegate | `done` |
| E7-TASK-03 | Error handling (transcription failure → user notification) | `done` |
| E7-TASK-04 | [TEST] Paste & Core Flow — Integration & Testing | `done` |

---

### Epic E8 — API Backend & Settings UI

**File**: `todo/e8-api-settings.md`
**Status**: `done`
**Depends on**: E6, E7

| Task | Title | Status |
|---|---|---|
| E8-TASK-01 | Implement KeychainManager | `done` |
| E8-TASK-02 | Implement OpenAIWhisperService | `done` |
| E8-TASK-03 | Backend switching in AppDelegate | `done` |
| E8-TASK-04 | Build full SettingsView | `done` |
| E8-TASK-05 | [TEST] API Backend & Settings UI — Integration & Testing | `done` |

---

### Epic E9 — Voice Translation

**File**: `todo/e9-translation.md`
**Status**: `done`
**Depends on**: E8

| Task | Title | Status |
|---|---|---|
| E9-TASK-01 | Implement TranslationConfig | `done` |
| E9-TASK-02 | English target translation via /v1/audio/translations | `done` |
| E9-TASK-03 | Non-English target translation via Chat Completions chaining | `done` |
| E9-TASK-04 | Auto-backend enforcement | `done` |
| E9-TASK-05 | Language picker in menu bar and SettingsView | `done` |
| E9-TASK-06 | [TEST] Voice Translation — Integration & Testing | `done` |

---

> **Agent workflow rules** are defined in `todo/RULES.md` — read it before picking up any task.
