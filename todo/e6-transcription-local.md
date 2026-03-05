# Epic 6: Local Transcription (WhisperKit)

## Epic 6: Local Transcription (WhisperKit)

Adds on-device speech-to-text using WhisperKit — a Swift-native Whisper implementation that
runs inference via Core ML without internet access. Defines the `TranscriptionService` protocol
that both the local and (future) API implementations will conform to. Handles model download,
storage, and selection. After this epic, pressing the hotkey and speaking produces a transcribed
String entirely on-device.

### Dependencies
- **Depends on**: E1 (Project Skeleton & App Foundation) — needs the Xcode project for SPM integration
- **Depends on**: E4 (Audio Recording) — `AudioRecorder` must produce a valid 16kHz WAV file before transcription can be tested
- **Intersects with**: E7 (Paste & Core Flow) — `TranscriptionService.transcribe()` is called inside `stopRecordingFlow()` in E7-TASK-02
- **Intersects with**: E8 (API Backend) — `OpenAIWhisperService` will conform to the same `TranscriptionService` protocol defined here

### Affected Files
- `Murmur/Transcription/TranscriptionService.swift` — created
- `Murmur/Transcription/LocalWhisperService.swift` — created
- `Murmur/Transcription/ModelManager.swift` — created
- `todo/e6-transcription-local.md` — modified (status updates)
- `todo/roadmap.md` — modified (status updates)

### Tasks
- [x] E6-TASK-01 — Define TranscriptionService protocol
- [x] E6-TASK-02 — Add WhisperKit Swift Package dependency
- [ ] E6-TASK-03 — Implement LocalWhisperService
- [ ] E6-TASK-04 — Implement ModelManager (download, store, select)
- [ ] E6-TASK-05 — [TEST] Local Transcription — Integration & Testing

---

### E6-TASK-01 — Define TranscriptionService protocol

**Epic**: Local Transcription (WhisperKit)
**Status**: `done`
**Depends on**: E1-TASK-01
**Intersects with**: E8 (OpenAIWhisperService conforms to this protocol)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Transcription/TranscriptionService.swift` | created |

#### Description
A Swift protocol that all transcription backends must conform to. Keeping backends behind a
protocol lets `AppDelegate` swap between local and API implementations without changing any
calling code.

#### Work
- Define `protocol TranscriptionService: AnyObject`:
  ```swift
  /// Transcribe audio at the given URL.
  /// - Parameters:
  ///   - audioURL: Path to a 16kHz mono WAV file.
  ///   - targetLanguage: BCP-47 language code for the desired output language, or nil for auto-detect.
  /// - Returns: The transcribed (and optionally translated) text.
  func transcribe(audioURL: URL, targetLanguage: String?) async throws -> String
  ```
- Define `enum TranscriptionError: Error`:
  - `case modelNotLoaded`
  - `case audioFileNotFound`
  - `case apiError(String)`
  - `case cancelled`
- Add a `var isAvailable: Bool { get }` requirement — `LocalWhisperService` returns `true` when model is loaded; `OpenAIWhisperService` returns `true` when API key is set

#### Definition of Done (DoD)
- [x] Protocol compiles with the signature above
- [x] `TranscriptionError` enum covers all cases listed
- [x] `isAvailable` is a protocol requirement
- [x] No concrete logic in this file — protocol only

#### Test Checklist
- [x] A mock conformance `MockTranscriptionService: TranscriptionService` compiles without errors
- [x] `TranscriptionError` cases can all be thrown and caught

---

### E6-TASK-02 — Add WhisperKit Swift Package dependency

**Epic**: Local Transcription (WhisperKit)
**Status**: `done`
**Depends on**: E1-TASK-01
**Intersects with**: E6-TASK-03 (LocalWhisperService imports WhisperKit)

#### Affected Files
| File | Change |
|---|---|
| `Murmur.xcodeproj/` | modified |

#### Description
Adds WhisperKit as a Swift Package dependency. WhisperKit provides on-device Whisper inference
via Core ML and is the primary transcription engine for Murmur's local mode.

#### Work
- In Xcode: File → Add Package Dependencies…
- Add package URL: `https://github.com/argmaxinc/WhisperKit`
- Pin to a stable release (latest stable at time of implementation)
- Add `WhisperKit` library to the Murmur app target
- Verify the package resolves and the project builds

#### Definition of Done (DoD)
- [x] WhisperKit appears in `Package.resolved` (or Xcode package cache)
- [x] `import WhisperKit` compiles without errors in a test file
- [x] Project builds after adding the dependency

#### Test Checklist
- [x] Clean build with WhisperKit dependency resolves successfully
- [x] `import WhisperKit` in any Swift file → no "no such module" error

---

### E6-TASK-03 — Implement LocalWhisperService

**Epic**: Local Transcription (WhisperKit)
**Status**: `pending`
**Depends on**: E6-TASK-01, E6-TASK-02, E6-TASK-04
**Intersects with**: E7 (called by stopRecordingFlow), E8 (AppDelegate swaps this out for OpenAIWhisperService based on settings)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Transcription/LocalWhisperService.swift` | created |

#### Description
Concrete `TranscriptionService` implementation using WhisperKit. Loads the selected Whisper
model via `ModelManager` and runs inference on a WAV file, returning the transcribed text.

#### Work
- Create `class LocalWhisperService: TranscriptionService`
- Depend on `ModelManager` for the loaded WhisperKit instance
- `var isAvailable: Bool` — returns `ModelManager.shared.isModelLoaded`
- `func transcribe(audioURL: URL, targetLanguage: String?) async throws -> String`:
  - Guard `isAvailable`, else throw `TranscriptionError.modelNotLoaded`
  - Guard file exists at `audioURL`, else throw `TranscriptionError.audioFileNotFound`
  - Call WhisperKit's transcribe API with the audio URL
  - If `targetLanguage` is set and not `"en"`: WhisperKit translate task is used (→ always English output); for non-English output, translation is deferred to E9
  - Return the concatenated transcription segments as a `String`
  - Delete the temp audio file after successful transcription (call `try? FileManager.default.removeItem(at: audioURL)`)
- Handle WhisperKit errors and wrap them in `TranscriptionError.apiError`

#### Definition of Done (DoD)
- [ ] Transcription of a 10 s WAV clip returns a non-empty String
- [ ] `isAvailable` correctly reflects model load state
- [ ] Temp file is deleted after transcription
- [ ] `modelNotLoaded` and `audioFileNotFound` errors are thrown in the correct conditions
- [ ] Whisper errors are wrapped and re-thrown as `TranscriptionError.apiError`

#### Test Checklist
- [ ] Record 10 s of English speech → `transcribe()` returns accurate text
- [ ] Call with unloaded model → throws `TranscriptionError.modelNotLoaded`
- [ ] Call with non-existent file → throws `TranscriptionError.audioFileNotFound`
- [ ] After successful transcription, temp file no longer exists on disk

---

### E6-TASK-04 — Implement ModelManager (download, store, select)

**Epic**: Local Transcription (WhisperKit)
**Status**: `pending`
**Depends on**: E6-TASK-02, E1-TASK-03
**Intersects with**: E6-TASK-03 (LocalWhisperService calls ModelManager), E8 (model selection picker in SettingsView writes to SettingsModel.whisperModel which triggers ModelManager)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Transcription/ModelManager.swift` | created |

#### Description
Manages the WhisperKit model lifecycle: downloading on first use, storing in
`~/Library/Application Support/Murmur/`, and loading the user-selected model size into memory.

#### Work
- Create `class ModelManager: ObservableObject` (singleton: `ModelManager.shared`)
- `@Published var isModelLoaded: Bool = false`
- `@Published var isDownloading: Bool = false`
- `@Published var downloadProgress: Double = 0`
- Storage directory: `~Library/Application Support/Murmur/models/`
- `func loadModel() async throws`:
  - Read `SettingsModel.shared.whisperModel` (tiny / base / small)
  - Check if model files exist locally; if not, download via WhisperKit
  - Initialise a `WhisperKit` instance with the model
  - Set `isModelLoaded = true`
- `var whisperKit: WhisperKit?` — the loaded instance, accessed by `LocalWhisperService`
- Observe `SettingsModel.shared.whisperModel` changes → call `loadModel()` to reload

#### Definition of Done (DoD)
- [ ] `loadModel()` downloads the model on first call and loads it into memory
- [ ] Model files are persisted in `~/Library/Application Support/Murmur/models/`
- [ ] Subsequent launches load the model from disk (no re-download)
- [ ] `isModelLoaded` transitions from `false` → `true` after successful load
- [ ] Changing `whisperModel` in SettingsModel triggers a model reload
- [ ] `downloadProgress` updates during download (for future UI use)

#### Test Checklist
- [ ] First launch (no model cached): download occurs, progress updates, model loads
- [ ] Second launch: model loads from disk, no download
- [ ] Change model from `"base"` to `"small"` → `isModelLoaded` briefly `false`, then `true` with new model
- [ ] `whisperKit` is non-nil after `loadModel()` succeeds

---

### E6-TASK-05 — [TEST] Local Transcription — Integration & Testing

**Epic**: Local Transcription (WhisperKit)
**Status**: `pending`
**Depends on**: E6-TASK-01, E6-TASK-02, E6-TASK-03, E6-TASK-04
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/e6-transcription-local.md` | modified |
| `todo/roadmap.md` | modified |

#### Description
End-to-end testing task for the Local Transcription epic. Validates the full pipeline from
WAV file input to transcribed String output, model management, and protocol conformance.

#### Work
- Review all E6 tasks are marked `done`
- Test transcription accuracy with several audio samples
- Test model download, caching, and model switching

#### Definition of Done (DoD)
- [ ] E6-TASK-01 is `done`
- [ ] E6-TASK-02 is `done`
- [ ] E6-TASK-03 is `done`
- [ ] E6-TASK-04 is `done`
- [ ] All test cases below pass
- [ ] No regressions in E1–E4

#### Test Checklist
- [ ] E6-TASK-01: `TranscriptionService` protocol — mock conformance compiles; errors throwable
- [ ] E6-TASK-02: WhisperKit package resolves; `import WhisperKit` compiles
- [ ] E6-TASK-03: 10 s English speech → transcription returns accurate text; temp file deleted after use
- [ ] E6-TASK-04: Model downloads on first use; loads from cache on second launch; model switch reloads correctly
- [ ] Full pipeline: `AudioRecorder.stop()` URL → `LocalWhisperService.transcribe()` → non-empty String in < 3 s (whisper-base, M1)
- [ ] Regression — E4: AudioRecorder still produces valid 16kHz WAV files after E6 integration
- [ ] No regressions at E6/E7 intersection: `TranscriptionService` protocol is ready to be called from core flow
