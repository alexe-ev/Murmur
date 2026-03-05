# Epic 8: API Backend & Settings UI

## Epic 8: API Backend & Settings UI

Adds the OpenAI Whisper API as an alternative transcription backend and builds the full
SwiftUI `SettingsView`. Users can choose between on-device (WhisperKit) and cloud (OpenAI API)
transcription, configure their API key (stored securely in Keychain), change the global hotkey,
select the Whisper model size, and toggle launch-at-login — all from a single settings window.

### Dependencies
- **Depends on**: E6 (Local Transcription) — `TranscriptionService` protocol must exist; `LocalWhisperService` is the reference implementation
- **Depends on**: E7 (Paste & Core Flow) — `AppDelegate.transcriptionService` must be a swappable `var` (established in E7-TASK-02)
- **Intersects with**: E6 (OpenAIWhisperService conforms to the same `TranscriptionService` protocol)
- **Intersects with**: E9 (Voice Translation) — settings for translation and language are shown in the same SettingsView; API key entered here is required for translation in E9

### Affected Files
- `Murmur/Settings/KeychainManager.swift` — created
- `Murmur/Transcription/OpenAIWhisperService.swift` — created
- `Murmur/App/AppDelegate.swift` — modified (backend switching, settings window)
- `Murmur/UI/SettingsView.swift` — created
- `Murmur.xcodeproj/project.pbxproj` — modified (register new source files in target)
- `todo/e8-api-settings.md` — modified (status updates)
- `todo/roadmap.md` — modified (status updates)

### Tasks
- [x] E8-TASK-01 — Implement KeychainManager
- [x] E8-TASK-02 — Implement OpenAIWhisperService
- [x] E8-TASK-03 — Backend switching in AppDelegate
- [x] E8-TASK-04 — Build full SettingsView
- [ ] E8-TASK-05 — [TEST] API Backend & Settings UI — Integration & Testing

---

### E8-TASK-01 — Implement KeychainManager

**Epic**: API Backend & Settings UI
**Status**: `done`
**Depends on**: E1-TASK-01
**Intersects with**: E8-TASK-02 (OpenAIWhisperService reads key via KeychainManager), E8-TASK-04 (SettingsView writes key via KeychainManager), E9 (translation API calls also require this key)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Settings/KeychainManager.swift` | created |

#### Description
Secure storage for the OpenAI API key using the macOS Keychain (`Security` framework).
The API key must never be stored in `UserDefaults`, committed to source control, or logged.

#### Work
- Create `class KeychainManager`
- Use `kSecClassGenericPassword` with service = `"com.murmur.app"` and account = `"openai-api-key"`
- Implement:
  - `static func save(apiKey: String) throws` — `SecItemAdd` or `SecItemUpdate`
  - `static func load() -> String?` — `SecItemCopyMatching`; returns nil if not found
  - `static func delete() throws` — `SecItemDelete`
- Wrap Security framework status codes in `enum KeychainError: Error { case saveFailed(OSStatus), loadFailed, deleteFailed(OSStatus) }`
- Never log the API key value — log only success/failure status

#### Definition of Done (DoD)
- [x] `save(apiKey:)` stores the key in Keychain
- [x] `load()` retrieves the stored key; returns `nil` if none stored
- [x] `delete()` removes the key
- [x] API key survives app restart (persists in Keychain)
- [x] Keychain errors are wrapped and thrown — no raw OSStatus values exposed to callers

#### Test Checklist
- [x] `save("sk-test")` → `load()` returns `"sk-test"`
- [x] `delete()` → `load()` returns `nil`
- [x] Save a new key over an existing one → `load()` returns the new value
- [x] Key is accessible in Keychain Access.app under "com.murmur.app"

---

### E8-TASK-02 — Implement OpenAIWhisperService

**Epic**: API Backend & Settings UI
**Status**: `done`
**Depends on**: E6-TASK-01, E8-TASK-01
**Intersects with**: E7 (swapped in as `AppDelegate.transcriptionService`), E9 (extended to support translation endpoints)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Transcription/OpenAIWhisperService.swift` | created |
| `todo/e8-api-settings.md` | modified (status updates) |
| `todo/roadmap.md` | modified (status updates) |

#### Description
Concrete `TranscriptionService` implementation that calls the OpenAI Whisper API.
Sends the recorded WAV as a multipart/form-data request to `/v1/audio/transcriptions`
and returns the transcribed text. Requires a valid API key from `KeychainManager`.

#### Work
- Create `class OpenAIWhisperService: TranscriptionService`
- `var isAvailable: Bool` — returns `true` if `KeychainManager.load() != nil`
- `func transcribe(audioURL: URL, targetLanguage: String?) async throws -> String`:
  1. Load API key from `KeychainManager.load()` — throw `TranscriptionError.apiError("No API key")` if nil
  2. Build a `URLRequest` to `https://api.openai.com/v1/audio/transcriptions`
     - Method: `POST`
     - Headers: `Authorization: Bearer <key>`, `Content-Type: multipart/form-data`
     - Body: multipart form with fields: `file` (WAV data), `model` ("whisper-1"), `response_format` ("text"), optionally `language` (if `targetLanguage` is set)
  3. Execute with `URLSession.shared.data(for:)`
  4. Parse response as plain text (response_format = "text" returns plain text)
  5. Return the transcribed String
  6. On HTTP errors (4xx/5xx): throw `TranscriptionError.apiError(responseBody)`
  7. Delete temp audio file after successful response
- Timeout: 30 s (`URLRequest.timeoutInterval`)

#### Definition of Done (DoD)
- [x] `transcribe()` returns accurate text for a 10 s English WAV clip
- [x] API key is read from Keychain on each call (not cached in memory)
- [x] Throws `TranscriptionError.apiError("No API key")` if Keychain is empty
- [x] HTTP 4xx/5xx → throws `TranscriptionError.apiError` with response body
- [x] Temp file deleted after use

#### Test Checklist
- [x] With valid API key: record 10 s → `transcribe()` returns accurate text
- [x] With no API key stored: `transcribe()` throws `apiError("No API key")`
- [x] With invalid API key: OpenAI returns 401 → throws `apiError` with message
- [x] Network timeout (airplane mode): throws within 30 s without hanging
- [x] Temp file deleted after successful transcription

---

### E8-TASK-03 — Backend switching in AppDelegate

**Epic**: API Backend & Settings UI
**Status**: `done`
**Depends on**: E8-TASK-02, E7-TASK-02
**Intersects with**: E9 (translation mode may force API backend — E9-TASK-04)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/App/AppDelegate.swift` | modified |
| `Murmur.xcodeproj/project.pbxproj` | modified (register OpenAI/Keychain source files in target) |
| `todo/e8-api-settings.md` | modified (status updates) |
| `todo/roadmap.md` | modified (status updates) |

#### Description
`AppDelegate` reads `SettingsModel.whisperBackend` and instantiates the correct
`TranscriptionService` implementation. When the user changes the backend in Settings,
the active service is hot-swapped without restarting the app.

#### Work
- Add `func applyTranscriptionBackend()` to `AppDelegate`:
  - Read `SettingsModel.shared.whisperBackend`
  - If `"local"`: `transcriptionService = LocalWhisperService()`; call `ModelManager.shared.loadModel()`
  - If `"api"`: `transcriptionService = OpenAIWhisperService()`
- Call `applyTranscriptionBackend()` in `applicationDidFinishLaunching`
- Observe `SettingsModel.shared.whisperBackend` changes (Combine `sink` or `didSet`) → call `applyTranscriptionBackend()`
- If API backend selected but no key stored: log a warning (SettingsView will show the SecureField; we don't block here)

#### Definition of Done (DoD)
- [x] On launch, the correct backend is instantiated based on saved preference
- [x] Changing `whisperBackend` in SettingsModel hot-swaps the service without relaunch
- [x] Switching to local → `ModelManager.loadModel()` is triggered
- [x] `transcriptionService` is never `nil` — always falls back to `LocalWhisperService`

#### Test Checklist
- [x] Set `whisperBackend = "api"` → `transcriptionService` is `OpenAIWhisperService`
- [x] Set `whisperBackend = "local"` → `transcriptionService` is `LocalWhisperService`, model begins loading
- [x] Change backend in SettingsView → hot-swap occurs, next recording uses new backend
- [x] API backend with no key: app doesn't crash; error is shown only when recording is attempted

---

### E8-TASK-04 — Build full SettingsView

**Epic**: API Backend & Settings UI
**Status**: `done`
**Depends on**: E8-TASK-01, E8-TASK-03, E3-TASK-03, E6-TASK-03, E1-TASK-04
**Intersects with**: E9 (language picker and translation toggle sections are present but wired in E9)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/UI/SettingsView.swift` | created |
| `Murmur/App/AppDelegate.swift` | modified (openSettings() implementation) |
| `Murmur.xcodeproj/project.pbxproj` | modified (register SettingsView in target) |
| `todo/e8-api-settings.md` | modified (status updates) |
| `todo/roadmap.md` | modified (status updates) |

#### Description
Full SwiftUI settings window with all user-configurable options. Opened from the menu bar
"Settings…" item. Each section maps to a group of related preferences.

#### Work
Build `SettingsView` with these sections:

**Recording**
- Hotkey capture field: shows current hotkey (e.g. "⌥ Space"); a "Record" button enters capture mode where the next key combo is captured and saved to `SettingsModel.hotkeyKeyCode/Modifiers`

**Transcription**
- Backend picker: `Picker("Engine", ...)` with options "On-Device (WhisperKit)" and "OpenAI API"
  - Bound to `SettingsModel.whisperBackend`
- Model size picker (shown only when backend = local): Segmented control `tiny | base | small`
  - Bound to `SettingsModel.whisperModel`
- API Key field (shown only when backend = api): `SecureField("sk-...")` with "Save" button
  - On save: `try KeychainManager.save(apiKey: value)`; show inline success/error message

**Translation** *(placeholder section — wired in E9)*
- `Toggle("Enable Translation", isOn: $settings.translationEnabled)` — present but disabled if no API key
- Language picker: grayed out stub for now — wired in E9-TASK-05

**General**
- `Toggle("Launch at Login", isOn: $settings.launchAtLogin)`
- "Version X.Y.Z" info row

Implement `AppDelegate.openSettings()`:
- Create `NSWindow` hosting `SettingsView` via `NSHostingController`
- Use `.windowStyle(.titleBar)`, non-resizable
- Bring to front with `makeKeyAndOrderFront`

#### Definition of Done (DoD)
- [x] All sections and controls are present and functional
- [x] Backend picker changes `SettingsModel.whisperBackend` and triggers backend switch
- [x] Model picker changes `SettingsModel.whisperModel` and triggers model reload
- [x] API key SecureField saves to Keychain on "Save"
- [x] Launch at Login toggle registers/unregisters via SMAppService
- [x] Hotkey capture field works and persists the new hotkey
- [x] Translation section is present (may be stub for now)

#### Test Checklist
- [x] Open Settings from menu bar → window appears
- [x] Switch backend to "OpenAI API" → model picker hides; API key field appears
- [x] Enter a valid API key and save → `KeychainManager.load()` returns the key
- [x] Change model to "small" → `ModelManager` begins loading small model
- [x] Toggle "Launch at Login" → System Settings reflects the change
- [x] Capture a new hotkey → new combo fires `onToggle` from any app
- [x] Close and reopen Settings → all values reflect persisted state

---

### E8-TASK-05 — [TEST] API Backend & Settings UI — Integration & Testing

**Epic**: API Backend & Settings UI
**Status**: `pending`
**Depends on**: E8-TASK-01, E8-TASK-02, E8-TASK-03, E8-TASK-04
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/e8-api-settings.md` | modified |
| `todo/roadmap.md` | modified |

#### Description
End-to-end testing task for the API Backend & Settings UI epic. Validates Keychain storage,
OpenAI API transcription, backend switching, and the full SettingsView — including persistence
across restarts.

#### Work
- Review all E8 tasks are marked `done`
- Test API transcription with a real OpenAI key
- Test all SettingsView controls save and restore correctly

#### Definition of Done (DoD)
- [ ] E8-TASK-01 is `done`
- [ ] E8-TASK-02 is `done`
- [ ] E8-TASK-03 is `done`
- [ ] E8-TASK-04 is `done`
- [ ] All test cases below pass
- [ ] No regressions in E1–E7

#### Test Checklist
- [ ] E8-TASK-01: API key saved to Keychain → survives restart → can be deleted
- [ ] E8-TASK-02: API backend transcribes 10 s clip accurately; fails gracefully without key
- [ ] E8-TASK-03: Switching backend in Settings → next recording uses new backend without restart
- [ ] E8-TASK-04: All settings controls visible; all values persist across quit-and-relaunch
- [ ] Full flow with API backend: hotkey → speak → hotkey → text pasted via API transcription
- [ ] Full flow with local backend: same flow, on-device only
- [ ] Regression — E7: Core flow still works after backend-switching code added to AppDelegate
- [ ] Regression — E6: LocalWhisperService still works after OpenAIWhisperService added
- [ ] No regressions at E8/E9 intersection: translation section in SettingsView is present and ready for wiring
