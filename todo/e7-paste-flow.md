# Epic 7: Paste & Core Flow Integration

## Epic 7: Paste & Core Flow Integration

Connects all previously built components into the complete end-to-end user flow:
hotkey press → audio recording → transcription → paste into the focused text field.
Implements `PasteController` (clipboard write + simulated Cmd+V) and wires everything
together in `AppDelegate`. After this epic the core product is working: a user can press
Option+Space, speak, press it again, and have transcribed text appear in any text field on
their system.

### Dependencies
- **Depends on**: E2 (Permissions) — Accessibility permission must be granted for paste to work
- **Depends on**: E3 (Global Hotkey) — `onToggle` callback drives the flow
- **Depends on**: E4 (Audio Recording) — `AudioRecorder.stopRecording()` supplies the WAV file
- **Depends on**: E5 (Menu Bar UI) — `MenuBarController.setState(.processing)` called during transcription
- **Depends on**: E6 (Local Transcription) — `TranscriptionService.transcribe()` converts audio to text
- **Intersects with**: E8 (API Backend) — E8-TASK-03 swaps the `TranscriptionService` instance; this epic must leave that seam open
- **Intersects with**: E9 (Voice Translation) — E9 inserts a translation step between transcription and paste inside the same flow

### Affected Files
- `Murmur/Core/PasteController.swift` — created
- `Murmur/App/AppDelegate.swift` — modified (startRecordingFlow, stopRecordingFlow, error handling)
- `Murmur.xcodeproj/project.pbxproj` — modified (target membership for PasteController)
- `todo/e7-paste-flow.md` — modified (status updates)
- `todo/roadmap.md` — modified (status updates)

### Tasks
- [x] E7-TASK-01 — Implement PasteController
- [x] E7-TASK-02 — Wire core flow in AppDelegate
- [ ] E7-TASK-03 — Error handling (transcription failure → user notification)
- [ ] E7-TASK-04 — [TEST] Paste & Core Flow — Integration & Testing

---

### E7-TASK-01 — Implement PasteController

**Epic**: Paste & Core Flow Integration
**Status**: `done`
**Depends on**: E2-TASK-01
**Intersects with**: E7-TASK-02 (called from stopRecordingFlow)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Core/PasteController.swift` | created |

#### Description
`PasteController` writes text to the system clipboard and then simulates a Cmd+V keystroke
via `CGEvent`, causing the currently focused application to paste. This is the only
system-wide paste mechanism that works universally across all macOS apps.

Accessibility permission is required for `CGEvent` to post to other processes. The controller
guards against missing permission before attempting to post.

#### Work
- Create class `PasteController`
- `func paste(_ text: String) throws`:
  1. Guard `PermissionsManager.shared.accessibilityGranted`, else throw a `PasteError.accessibilityNotGranted`
  2. Set clipboard: `NSPasteboard.general.clearContents()` then `NSPasteboard.general.setString(text, forType: .string)`
  3. Post `CGEvent` key-down for Cmd+V:
     ```swift
     let source = CGEventSource(stateID: .hidSystemState)
     let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09 /* V */, keyDown: true)
     keyDown?.flags = .maskCommand
     keyDown?.post(tap: .cghidEventTap)
     let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
     keyUp?.post(tap: .cghidEventTap)
     ```
  4. Add a tiny `usleep(50_000)` delay between clipboard write and key event to let the clipboard settle
- Define `enum PasteError: Error { case accessibilityNotGranted, clipboardWriteFailed }`

#### Definition of Done (DoD)
- [x] `paste(_:)` writes text to `NSPasteboard.general`
- [x] Cmd+V keystroke is posted to the system event stream
- [x] Text appears in the focused text field of another app
- [x] `accessibilityNotGranted` is thrown when Accessibility permission is missing
- [x] No leftover text in clipboard that could interfere with user's own copy/paste history (clipboard is overwritten, not appended)

#### Test Checklist
- [x] Focus a text field in Safari → call `paste("hello world")` → "hello world" appears
- [x] Focus a text field in Notes → `paste("test")` → "test" appears
- [x] Focus a terminal → `paste("echo hi")` → "echo hi" is pasted (do not press Enter)
- [x] Call `paste()` without Accessibility permission → throws `PasteError.accessibilityNotGranted`

---

### E7-TASK-02 — Wire core flow in AppDelegate

**Epic**: Paste & Core Flow Integration
**Status**: `done`
**Depends on**: E7-TASK-01, E3-TASK-02, E4-TASK-01, E5-TASK-02, E6-TASK-04
**Intersects with**: E8 (backend switching: `transcriptionService` property must be swappable), E9 (translation inserted here after transcription)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/App/AppDelegate.swift` | modified |
| `Murmur.xcodeproj/project.pbxproj` | modified |

#### Description
Replaces the stub `startRecordingFlow()` / `stopRecordingFlow()` methods with the full
implementation, connecting `AudioRecorder`, `TranscriptionService`, `PasteController`, and
`MenuBarController` in the correct sequence.

#### Work
- Add properties to `AppDelegate`:
  ```swift
  let audioRecorder = AudioRecorder()
  let pasteController = PasteController()
  var transcriptionService: TranscriptionService = LocalWhisperService()  // swappable in E8
  ```
- Implement `startRecordingFlow()`:
  1. `menuBarController?.setState(.recording)` + `menuBarController?.showIndicator()`
  2. `try audioRecorder.startRecording()`
  3. Update menu item title to "Stop Recording"
- Implement `stopRecordingFlow()`:
  1. `menuBarController?.setState(.processing)` + `menuBarController?.hideIndicator()`
  2. `guard let url = audioRecorder.stopRecording()` — if nil, show error and return
  3. Update menu item title to "Start Recording"
  4. Call `transcriptionService.transcribe(audioURL: url, targetLanguage: nil)` inside a `Task { }` block
  5. On success: `pasteController.paste(text)`, then `menuBarController?.setState(.idle)`
  6. On failure: call `showErrorNotification(error)` (implemented in E7-TASK-03), then `menuBarController?.setState(.idle)`
- All UI updates dispatched on `@MainActor`

#### Definition of Done (DoD)
- [x] `startRecordingFlow()` starts mic capture and updates UI
- [x] `stopRecordingFlow()` stops capture, transcribes, and pastes
- [x] `transcriptionService` is a swappable property (not hardcoded)
- [x] Icon returns to `.idle` in all code paths (success and error)
- [x] Whole async pipeline runs without blocking the main thread

#### Test Checklist
- [x] Press hotkey → icon → recording, indicator appears
- [x] Press hotkey again → icon → processing, indicator hides
- [x] After transcription → text pasted into focused field, icon → idle
- [x] If transcription throws → error notification shown, icon → idle (no stuck state)
- [x] `transcriptionService` can be replaced with a mock at runtime without changing other code

---

### E7-TASK-03 — Error handling (transcription failure → user notification)

**Epic**: Paste & Core Flow Integration
**Status**: `pending`
**Depends on**: E7-TASK-02
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `Murmur/App/AppDelegate.swift` | modified |

#### Description
When transcription or paste fails, Murmur must inform the user briefly without blocking them.
A `UNUserNotification` (or `NSUserNotification` fallback) is shown for 3 seconds then dismissed
automatically. The app must never enter a stuck state — icon always returns to idle.

#### Work
- Request `UNUserNotificationCenter` authorisation at app startup (`.alert` + `.sound`)
- Implement `AppDelegate.showErrorNotification(_ error: Error)`:
  - Create a `UNMutableNotificationContent`: title "Murmur", body based on error type:
    - `TranscriptionError.modelNotLoaded` → "Whisper model is not ready yet. Please wait."
    - `TranscriptionError.audioFileNotFound` → "Recording file was missing. Please try again."
    - `TranscriptionError.apiError` → "Transcription failed. Check your API key in Settings."
    - `PasteError.accessibilityNotGranted` → "Accessibility permission needed. Open Settings."
    - Default → "Something went wrong. Please try again."
  - Deliver with `timeInterval: 0.1` trigger (immediate)
- Ensure `menuBarController?.setState(.idle)` is always called even when errors occur (already covered in E7-TASK-02 but verify here)

#### Definition of Done (DoD)
- [ ] Error notification appears within 1 s of a transcription or paste failure
- [ ] Notification body correctly maps each error type to a human-readable message
- [ ] Notification is non-blocking (does not require user interaction)
- [ ] Icon always returns to `.idle` after an error

#### Test Checklist
- [ ] Force `TranscriptionError.apiError` (e.g., by using a mock service) → notification appears with correct body
- [ ] Force `PasteError.accessibilityNotGranted` → notification appears
- [ ] After notification → icon is in `.idle` state, app is fully responsive
- [ ] App does not crash when notifications permission is denied (notification is silently skipped)

---

### E7-TASK-04 — [TEST] Paste & Core Flow — Integration & Testing

**Epic**: Paste & Core Flow Integration
**Status**: `pending`
**Depends on**: E7-TASK-01, E7-TASK-02, E7-TASK-03
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/e7-paste-flow.md` | modified |
| `todo/roadmap.md` | modified |

#### Description
End-to-end testing task for the Paste & Core Flow epic. This is the first test of the complete
user flow: hotkey → speak → hotkey → text appears in focused field. Tests multiple target apps
and edge cases (denied permissions, long clips, silence).

#### Work
- Review all E7 tasks are marked `done`
- Test the full flow in at least three different apps (browser, native app, terminal)
- Test error paths

#### Definition of Done (DoD)
- [ ] E7-TASK-01 is `done`
- [ ] E7-TASK-02 is `done`
- [ ] E7-TASK-03 is `done`
- [ ] All test cases below pass
- [ ] No regressions in E1–E6

#### Test Checklist
- [ ] E7-TASK-01: Text pasted via `PasteController` into Safari, Notes, and Terminal text fields
- [ ] E7-TASK-02: Full flow (hotkey → record → transcribe → paste) works end-to-end; icon states are correct throughout
- [ ] E7-TASK-03: Simulated transcription failure → notification shown; icon returns to idle
- [ ] Target: hotkey-stop to text pasted in < 2 s for a 10 s clip on local model (whisper-base)
- [ ] Silence-only recording: transcription returns empty or near-empty string; paste does not crash; notification not shown for empty result
- [ ] Long clip (> 60 s): transcription completes without timeout or crash
- [ ] Regression — E3: Hotkey still fires correctly after AppDelegate wiring changes
- [ ] Regression — E5: Icon states still correct; floating indicator still shows/hides
- [ ] No regressions at E7/E8 intersection: `transcriptionService` property is a plain `var` (not `let`), confirming E8 can swap it
