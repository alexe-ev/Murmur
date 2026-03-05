# Bug Log

This file is a **global log of all bugs** found during development.
It is not tied to any epic. Every bug found — whether during a regular task or
a `[TEST]` task — must be recorded here.

**Purpose**: before a release, this file serves as the definitive checklist of
every known issue that was fixed, so each one can be re-verified one final time.

> Do not delete entries. Mark them `done` and keep them permanently.

---

## Process Guardrail

- Every `[TEST]` and `[RETEST]` task must either:
  - add at least one `BUG-XX` entry, or
  - explicitly state in task notes that no new bugs were found after checking this file.
- If a bug is found during implementation, add/update its entry in the same PR.

---

## How to add an entry

Copy the template below, assign the next `BUG-XX` number, and fill it in.

```
## BUG-XX — <Short Bug Title>

**Found in**: <Epic Name> / <EN-TASK-ID>
**Found during**: `regular task` | `[TEST] task`
**Status**: `pending` | `in progress` | `done`

### Description
What the bug was and how it manifested.

### Fix
What was done to fix it.

### Verification
- [ ] Fix confirmed in the task where it was found
- [ ] Re-tested in the epic [RETEST] task (if applicable)
```

---

## Bug Index

| ID | Title | Epic | Task | Found during | Status |
|---|---|---|---|---|---|
| BUG-01 | Missing microphone usage declaration | Audit Remediation | PR-1 (`C-01`) | `regular task` | `done` |
| BUG-02 | Sandbox/API entitlement mismatch | Audit Remediation | PR-1 (`C-02`) | `regular task` | `done` |
| BUG-03 | Temporary audio files leaked on non-success paths | Audit Remediation | PR-1 (`C-03`) | `regular task` | `done` |
| BUG-04 | Recording state and callback flow instability | Audit Remediation | PR-2 (`H-01`, `H-02`) | `regular task` | `done` |
| BUG-05 | Clipboard privacy + keychain hardening gaps | Audit Remediation | PR-3 (`H-03`, `L-02`) | `regular task` | `done` |
| BUG-06 | Stringly-typed backend/model/language config | Audit Remediation | PR-4 (`M-01`) | `regular task` | `done` |
| BUG-07 | Service hidden coupling + oversized AppDelegate responsibilities | Audit Remediation | PR-5 (`M-02`, `L-01`) | `regular task` | `done` |
| BUG-08 | Missing automated regression gate and stale process states | Audit Remediation | PR-6 (`H-05`, `H-06`, `H-07`) | `regular task` | `done` |
| BUG-09 | Toolchain/docs drift and architecture ambiguity | Audit Remediation | PR-6 (`M-05`, `M-06`, `L-03`) | `regular task` | `done` |

**Status values**: `pending` — found, not yet fixed · `in progress` — being fixed · `done` — fixed and verified

---

## Entries

## BUG-01 — Missing microphone usage declaration

**Found in**: Audit Remediation / PR-1 (`C-01`)
**Found during**: `regular task`
**Status**: `done`

### Description
`Info.plist` did not contain `NSMicrophoneUsageDescription`, which breaks privacy compliance and microphone permission flow.

### Fix
Added `NSMicrophoneUsageDescription` with user-facing rationale in the app plist.

### Verification
- [x] Fix confirmed in PR-1 implementation
- [x] Re-checked in remediation regression build

## BUG-02 — Sandbox/API entitlement mismatch

**Found in**: Audit Remediation / PR-1 (`C-02`)
**Found during**: `regular task`
**Status**: `done`

### Description
App sandbox was enabled but `com.apple.security.network.client` entitlement was missing while API backend remained available.

### Fix
Added required network client entitlement for sandboxed API mode.

### Verification
- [x] Fix confirmed in PR-1 implementation
- [x] Re-checked in remediation regression build

## BUG-03 — Temporary audio files leaked on non-success paths

**Found in**: Audit Remediation / PR-1 (`C-03`)
**Found during**: `regular task`
**Status**: `done`

### Description
Recorded temp audio files were not removed consistently on failure/cancel flows.

### Fix
Centralized cleanup ownership and enforced cleanup on success/error/cancel paths.

### Verification
- [x] Fix confirmed in PR-1 implementation
- [x] Re-checked in remediation regression build

## BUG-04 — Recording state and callback flow instability

**Found in**: Audit Remediation / PR-2 (`H-01`, `H-02`)
**Found during**: `regular task`
**Status**: `done`

### Description
Recording state ownership and callback actor boundary were inconsistent, causing potential desync/race conditions.

### Fix
Stabilized recording state flow and made callback-to-main-thread/actor boundary explicit.

### Verification
- [x] Fix confirmed in PR-2 implementation
- [x] Re-checked in remediation regression build

## BUG-05 — Clipboard privacy + keychain hardening gaps

**Found in**: Audit Remediation / PR-3 (`H-03`, `L-02`)
**Found during**: `regular task`
**Status**: `done`

### Description
Paste flow overwrote clipboard without restoration policy; keychain policy lacked explicit hardening settings.

### Fix
Added clipboard restoration behavior and explicit keychain accessibility policy.

### Verification
- [x] Fix confirmed in PR-3 implementation
- [x] Re-checked in remediation regression build

## BUG-06 — Stringly-typed backend/model/language config

**Found in**: Audit Remediation / PR-4 (`M-01`)
**Found during**: `regular task`
**Status**: `done`

### Description
Runtime behavior depended on free-form strings for backend/model/language, making persisted invalid values risky.

### Fix
Replaced string configuration with enums and added normalization migration from persisted values.

### Verification
- [x] Fix confirmed in PR-4 implementation
- [x] Re-checked in remediation regression build

## BUG-07 — Service hidden coupling + oversized AppDelegate responsibilities

**Found in**: Audit Remediation / PR-5 (`M-02`, `L-01`)
**Found during**: `regular task`
**Status**: `done`

### Description
OpenAI service depended on global singleton state; `AppDelegate` mixed orchestration with backend and recording flow internals.

### Fix
Introduced explicit transcription request context and extracted dedicated coordinators from `AppDelegate`.

### Verification
- [x] Fix confirmed in PR-5 implementation
- [x] Re-checked in remediation regression build

## BUG-08 — Missing automated regression gate and stale process states

**Found in**: Audit Remediation / PR-6 (`H-05`, `H-06`, `H-07`)
**Found during**: `regular task`
**Status**: `done`

### Description
No automated tests existed; test-status artifacts were stale; bug log process was not actively used.

### Fix
Added `MurmurTests` unit/smoke target + `scripts/smoke-regression.sh`, synchronized roadmap/epic test statuses, and backfilled bug log.

### Verification
- [x] Fix confirmed in PR-6 implementation
- [x] Re-checked via smoke regression run

## BUG-09 — Toolchain/docs drift and architecture ambiguity

**Found in**: Audit Remediation / PR-6 (`M-05`, `M-06`, `L-03`)
**Found during**: `regular task`
**Status**: `done`

### Description
Project Swift/toolchain and architecture expectations were documented inconsistently, and target architecture policy remained ambiguous.

### Fix
Aligned docs to project settings, explicitly documented architecture policy, and updated project build settings accordingly.

### Verification
- [x] Fix confirmed in PR-6 implementation
- [x] Re-checked via smoke regression run
