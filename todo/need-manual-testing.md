# Need Manual Testing

This file tracks checks intentionally deferred to manual QA after automated checks.

## E3 — Global Hotkey

### Scope
- Task: `E3-TASK-04` ([TEST] Global Hotkey — Integration & Testing)
- Related tasks: `E3-TASK-01`, `E3-TASK-02`, `E3-TASK-03`

### Manual Checklist
- [ ] Option+Space fires `onToggle` from Safari, Notes, and Terminal (system-wide behavior).
- [ ] Toggle state is correct: odd presses start, even presses stop.
- [ ] `startRecordingFlow()` / `stopRecordingFlow()` are called on the corresponding toggle.
- [ ] Before onboarding completes, hotkey is not active.
- [ ] Changing hotkey in settings (example: Option+G) re-registers immediately.
- [ ] Old hotkey stops working right after re-registration.
- [ ] New hotkey persists after app relaunch.
- [ ] Permissions flow from E2 still works without regressions (onboarding and permission gating).
- [ ] No regressions at E3/E5 intersection (icon state behavior) once E5 is implemented.

### Notes
- Automated gate used before deferring to manual checks:
  - `xcodebuild -project Murmur.xcodeproj -scheme Murmur -configuration Debug -sdk macosx -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build`
  - Result: `BUILD SUCCEEDED`

## E5 — Menu Bar UI

### Scope
- Task: `E5-TASK-05` ([TEST] Menu Bar UI — Integration & Testing)
- Related tasks: `E5-TASK-01`, `E5-TASK-02`, `E5-TASK-03`, `E5-TASK-04`

### Manual Checklist
- [ ] Verify menu bar icon appears after onboarding and persists across Spaces.
- [ ] Verify icon transitions on hotkey cycle: `idle -> recording -> processing -> idle`.
- [ ] Verify dropdown order and labels: Start/Stop, Language submenu placeholder, Settings, Quit.
- [ ] Verify Start/Stop menu title toggles correctly while recording state changes.
- [ ] Verify floating indicator appears/disappears with recording and stays click-through.
- [ ] Verify indicator remains visible across Spaces and over full-screen apps.
- [ ] Verify icon legibility in both Light and Dark menu bar appearances.
- [ ] Verify no regression in E3 hotkey behavior after menu bar integration.

### Notes
- Automated gate used before deferring to manual checks:
  - `xcodebuild -project Murmur.xcodeproj -scheme Murmur -configuration Debug -sdk macosx -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build`
  - Result: `BUILD SUCCEEDED`

## E4 — Audio Recording

### Scope
- Task: `E4-TASK-04` ([TEST] Audio Recording — Integration & Testing)
- Related tasks: `E4-TASK-01`, `E4-TASK-02`, `E4-TASK-03`

### Manual Checklist
- [ ] Record 10 seconds of speech and open resulting `.wav` in QuickTime (audible, clear).
- [ ] Verify file properties are exactly 16000 Hz, mono, PCM via `AVAudioFile`.
- [ ] Deny microphone permission and call `startRecording()` (graceful error, no crash).
- [ ] Record twice in succession and verify file names differ.
- [ ] Verify full state sequence under real recording flow: `idle -> recording -> ready(url) -> idle`.
- [ ] Verify no regressions in E2 permission gating with real onboarding conditions.

### Notes
- Automated gate used before deferring to manual checks:
  - `xcodebuild -project Murmur.xcodeproj -scheme Murmur -configuration Debug -sdk macosx -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build`
  - Result: `BUILD SUCCEEDED`
