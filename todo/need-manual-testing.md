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
