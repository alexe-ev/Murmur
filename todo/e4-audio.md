# Epic 4: Audio Recording

## Epic 4: Audio Recording

Implements microphone capture using AVFoundation. Records at 16 kHz mono — Whisper's native
input format — and writes the output to a temporary WAV file. Exposes a state machine
(idle / recording / ready) via Combine so other components can react to recording lifecycle events.
Temp files are deleted immediately after use to keep storage footprint minimal.

### Dependencies
- **Depends on**: E1 (Project Skeleton & App Foundation) — needs the Xcode project and entitlements
- **Depends on**: E2 (Permissions & Onboarding) — `startRecording()` must only be called when mic permission is granted
- **Intersects with**: E6 (Local Transcription) — `AudioRecorder` produces the temp WAV file consumed by `TranscriptionService`
- **Intersects with**: E7 (Paste & Core Flow) — `AudioRecorder.stop()` is called by `AppDelegate.stopRecordingFlow()`, the returned URL is passed to transcription

### Affected Files
- `Murmur/Core/AudioRecorder.swift` — created
- `Murmur.xcodeproj/project.pbxproj` — modified
- `todo/e4-audio.md` — modified (status updates)
- `todo/roadmap.md` — modified (status updates)

### Tasks
- [x] E4-TASK-01 — Implement AudioRecorder (AVFoundation setup, 16kHz mono WAV)
- [ ] E4-TASK-02 — Temp file management
- [ ] E4-TASK-03 — Recording state machine (Combine publisher)
- [ ] E4-TASK-04 — [TEST] Audio Recording — Integration & Testing

---

### E4-TASK-01 — Implement AudioRecorder (AVFoundation setup, 16kHz mono WAV)

**Epic**: Audio Recording
**Status**: `done`
**Depends on**: E1-TASK-01, E2-TASK-01
**Intersects with**: E4-TASK-02 (output file URL), E4-TASK-03 (state transitions)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Core/AudioRecorder.swift` | created |
| `Murmur.xcodeproj/project.pbxproj` | modified |
| `todo/e4-audio.md` | modified (status updates) |
| `todo/roadmap.md` | modified (status updates) |

#### Description
`AudioRecorder` wraps `AVAudioEngine` and `AVAudioFile` to capture microphone input at 16 kHz
mono — the exact format WhisperKit and OpenAI Whisper expect. The format conversion is handled
inline using `AVAudioConverter` so no post-processing step is needed.

#### Work
- Create class `AudioRecorder`
- Configure `AVAudioSession` (macOS: use `AVCaptureDevice` path, not AVAudioSession which is iOS-only); use `AVAudioEngine` with the system input node
- Tap the input node at its native hardware format
- Install an `AVAudioConverter` to convert to 16000 Hz, 1 channel, PCM (Int16 or Float32)
- Write converted buffers to an `AVAudioFile` (WAV/LPCM, `.wav` extension)
- `func startRecording() throws` — configures and starts the engine, opens the output file
- `func stopRecording() -> URL?` — stops the engine, closes the file, returns the temp file URL
- Guard against starting when mic permission is not granted (`PermissionsManager.shared.microphoneGranted`)

#### Definition of Done (DoD)
- [x] `startRecording()` opens the mic and writes 16kHz mono WAV to disk
- [x] `stopRecording()` returns a valid `URL` pointing to a playable WAV file
- [x] Audio format is exactly: PCM, 16000 Hz, 1 channel (mono)
- [x] Calling `startRecording()` without mic permission throws or is a no-op (logs error)
- [x] No memory leaks from the tap block

#### Test Checklist
- [ ] Record 5 seconds of speech → open the resulting WAV in QuickTime → audio is audible and clear
- [ ] Verify WAV file properties with `AVAudioFile`: sample rate = 16000, channels = 1
- [ ] Call `startRecording()` with mic permission denied → error logged, no crash
- [ ] Record twice in succession → second recording is independent and valid

---

### E4-TASK-02 — Temp file management

**Epic**: Audio Recording
**Status**: `pending`
**Depends on**: E4-TASK-01
**Intersects with**: E6 (TranscriptionService deletes the file after use — coordinate ownership)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Core/AudioRecorder.swift` | modified |

#### Description
Audio recordings are ephemeral — they exist only long enough to be transcribed. This task
establishes the file lifecycle: creation in the system temp directory, unique naming, and
deletion after the consumer is done with the file.

#### Work
- Generate a unique temp file path: `FileManager.default.temporaryDirectory.appendingPathComponent("murmur_\(UUID().uuidString).wav")`
- Store the path internally as `private var currentTempURL: URL?`
- `stopRecording()` returns this URL and nils out `currentTempURL`
- Add `func deleteCurrentRecording()` — deletes `currentTempURL` if it still exists (used as a cleanup fallback)
- The consumer (`TranscriptionService`) is responsible for deleting the file after use; `AudioRecorder` deletes only on failure or if a new recording starts before the previous file was consumed
- On `startRecording()`, if `currentTempURL` is non-nil (leftover), delete it before creating a new file

#### Definition of Done (DoD)
- [ ] Each recording writes to a uniquely named file in `FileManager.temporaryDirectory`
- [ ] `stopRecording()` returns the URL and clears `currentTempURL`
- [ ] Stale temp file from a previous session is cleaned up on next `startRecording()`
- [ ] `deleteCurrentRecording()` removes the file from disk

#### Test Checklist
- [ ] Record twice — two different file names in temp dir
- [ ] After transcription deletes the file, temp dir contains no leftover `.wav` files
- [ ] Start a new recording while a previous temp file still exists → old file is deleted, new one created
- [ ] `deleteCurrentRecording()` removes the file and the file is gone on disk

---

### E4-TASK-03 — Recording state machine (Combine publisher)

**Epic**: Audio Recording
**Status**: `pending`
**Depends on**: E4-TASK-01
**Intersects with**: E5 (MenuBarController subscribes to state to update icon), E7 (AppDelegate uses state to drive UI during processing)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Core/AudioRecorder.swift` | modified |

#### Description
Exposes a `@Published var state: RecordingState` so that `MenuBarController` and other
components can react to recording lifecycle changes without polling.

#### Work
- Define `enum RecordingState { case idle, recording, ready(URL) }`
- Add `@Published private(set) var state: RecordingState = .idle` to `AudioRecorder`
- Transition `state` at the right moments:
  - `startRecording()` succeeds → `.recording`
  - `stopRecording()` returns URL → `.ready(url)`
  - After consumer picks up the URL and calls `deleteCurrentRecording()` → `.idle`
  - Any error during recording → `.idle` (with error logged)
- Expose `var statePublisher: AnyPublisher<RecordingState, Never>` for external subscription

#### Definition of Done (DoD)
- [ ] `state` transitions correctly through the full lifecycle
- [ ] `.recording` state is set synchronously when `startRecording()` succeeds
- [ ] `.ready(url)` is set synchronously when `stopRecording()` is called
- [ ] State returns to `.idle` after the file is consumed/deleted
- [ ] `statePublisher` emits on the main thread (or callers receive on main)

#### Test Checklist
- [ ] Observe `statePublisher` — sequence is idle → recording → ready(url) → idle
- [ ] Cancel recording by calling `stopRecording()` immediately → transitions idle → recording → ready
- [ ] State does not get stuck in `.recording` if `stopRecording()` throws
- [ ] `MenuBarController` (E5) can subscribe to `statePublisher` and receive updates

---

### E4-TASK-04 — [TEST] Audio Recording — Integration & Testing

**Epic**: Audio Recording
**Status**: `pending`
**Depends on**: E4-TASK-01, E4-TASK-02, E4-TASK-03
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/e4-audio.md` | modified |
| `todo/roadmap.md` | modified |

#### Description
End-to-end testing task for the Audio Recording epic. Validates the full recording lifecycle
from mic capture to temp file delivery and cleanup, plus state machine correctness.

#### Work
- Review all E4 tasks are marked `done`
- Perform manual recording tests
- Verify file format and cleanup behaviour

#### Definition of Done (DoD)
- [ ] E4-TASK-01 is `done`
- [ ] E4-TASK-02 is `done`
- [ ] E4-TASK-03 is `done`
- [ ] All test cases below pass
- [ ] No regressions in E1 or E2

#### Test Checklist
- [ ] E4-TASK-01: Record 10 s of speech → WAV file at 16000 Hz mono, audible in QuickTime
- [ ] E4-TASK-01: `startRecording()` with mic denied → graceful error, no crash
- [ ] E4-TASK-02: Each recording creates a uniquely named file; file deleted after use; no stale files in temp dir
- [ ] E4-TASK-03: State sequence is always idle → recording → ready → idle; no stuck states
- [ ] Full flow: `start()` → speak → `stop()` → URL returned → file deleted → state = idle
- [ ] Regression — E2: Mic permission check in `AudioRecorder` agrees with `PermissionsManager`
