# Epic 9: Voice Translation

## Epic 9: Voice Translation

Adds the voice translation feature: the user selects a target language, speaks in any language,
and the pasted output is delivered in the chosen target language — speech-to-translated-text in
one step. Translation always requires the OpenAI API (no local translation in v1). This epic
wires the translation pipeline into the existing core flow and adds the language picker to both
the menu bar dropdown and SettingsView.

### Dependencies
- **Depends on**: E8 (API Backend & Settings UI) — OpenAI API client (`OpenAIWhisperService`) and `KeychainManager` must exist; SettingsView translation section must be present
- **Intersects with**: E7 (Paste & Core Flow) — translation is inserted between transcription and paste inside `stopRecordingFlow()`; this epic modifies that flow
- **Intersects with**: E5 (Menu Bar UI) — language picker is added to the dropdown menu (E9-TASK-05)

### Affected Files
- `Murmur/Translation/TranslationConfig.swift` — created
- `Murmur/Transcription/OpenAIWhisperService.swift` — modified (translation endpoints)
- `Murmur/App/AppDelegate.swift` — modified (translation step in stopRecordingFlow, auto-backend enforcement)
- `Murmur/UI/MenuBarController.swift` — modified (language picker submenu)
- `Murmur/UI/SettingsView.swift` — modified (translation toggle and language picker wired)
- `todo/e9-translation.md` — modified (status updates)
- `todo/roadmap.md` — modified (status updates)

### Tasks
- [ ] E9-TASK-01 — Implement TranslationConfig
- [ ] E9-TASK-02 — English target translation via /v1/audio/translations
- [ ] E9-TASK-03 — Non-English target translation via Chat Completions chaining
- [ ] E9-TASK-04 — Auto-backend enforcement
- [ ] E9-TASK-05 — Language picker in menu bar and SettingsView
- [ ] E9-TASK-06 — [TEST] Voice Translation — Integration & Testing

---

### E9-TASK-01 — Implement TranslationConfig

**Epic**: Voice Translation
**Status**: `pending`
**Depends on**: E1-TASK-03, E8-TASK-04
**Intersects with**: E9-TASK-04 (TranslationConfig drives enforcement logic)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Translation/TranslationConfig.swift` | created |

#### Description
`TranslationConfig` is a thin observer around the two relevant `SettingsModel` properties
(`translationEnabled` and `targetLanguage`). It provides a clean API for the rest of the app
to check whether translation is active and what the target language is, rather than reaching
into `SettingsModel` directly.

#### Work
- Create `class TranslationConfig: ObservableObject` (singleton: `TranslationConfig.shared`)
- `@Published var isEnabled: Bool` — mirrors `SettingsModel.shared.translationEnabled`
- `@Published var targetLanguage: String` — mirrors `SettingsModel.shared.targetLanguage` (BCP-47 code, e.g. `"es"`, `"fr"`, `"en"`)
- Computed `var requiresAPI: Bool` — `true` when `isEnabled == true` (all translation in v1 requires API)
- Computed `var targetIsEnglish: Bool` — `true` when `targetLanguage == "en"`
- On init: subscribe to `SettingsModel.shared` publishers and keep `isEnabled` / `targetLanguage` in sync
- Expose a convenience list of supported languages:
  ```swift
  static let supportedLanguages: [(code: String, name: String)] = [
      ("en", "English"), ("es", "Spanish"), ("fr", "French"),
      ("de", "German"), ("it", "Italian"), ("pt", "Portuguese"),
      ("zh", "Chinese"), ("ja", "Japanese"), ("ko", "Korean"),
      ("ru", "Russian"), ("ar", "Arabic"), ("hi", "Hindi")
  ]
  ```

#### Definition of Done (DoD)
- [ ] `isEnabled` and `targetLanguage` mirror `SettingsModel` values and update reactively
- [ ] `requiresAPI` is `true` whenever translation is enabled
- [ ] `targetIsEnglish` is correct for all supported languages
- [ ] `supportedLanguages` list is present with at least 10 entries

#### Test Checklist
- [ ] Set `SettingsModel.shared.translationEnabled = true` → `TranslationConfig.shared.isEnabled` becomes `true`
- [ ] Set `targetLanguage = "es"` → `TranslationConfig.shared.targetLanguage == "es"`, `targetIsEnglish == false`
- [ ] Set `targetLanguage = "en"` → `targetIsEnglish == true`
- [ ] `requiresAPI` is `true` whenever `isEnabled` is `true`

---

### E9-TASK-02 — English target translation via /v1/audio/translations

**Epic**: Voice Translation
**Status**: `pending`
**Depends on**: E8-TASK-02, E9-TASK-01
**Intersects with**: E9-TASK-03 (non-English path; these two share the same flow entry point)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Transcription/OpenAIWhisperService.swift` | modified |

#### Description
When the user selects English as the target language with translation enabled, Murmur calls
`/v1/audio/translations` — the OpenAI endpoint that accepts audio in any language and returns
an English transcript. This is the simpler translation path.

#### Work
- Extend `OpenAIWhisperService.transcribe(audioURL:targetLanguage:)`:
  - If `targetLanguage == "en"` (and translation mode is enabled): call `/v1/audio/translations` instead of `/v1/audio/transcriptions`
  - `/v1/audio/translations` request body: `file`, `model` ("whisper-1"), `response_format` ("text") — no `language` field (endpoint always outputs English)
  - Return the English transcript
- Add a private helper `func buildTranslationRequest(audioURL: URL, apiKey: String) throws -> URLRequest` that encapsulates the multipart form for the translations endpoint

#### Definition of Done (DoD)
- [ ] When `targetLanguage = "en"` and translation enabled: `/v1/audio/translations` is called
- [ ] Speaking Spanish and selecting English target → pasted text is in English
- [ ] HTTP errors handled as `TranscriptionError.apiError`
- [ ] Temp file deleted after use

#### Test Checklist
- [ ] Enable translation, select English target, speak Spanish → pasted text is English
- [ ] Enable translation, select English target, speak French → pasted text is English
- [ ] Translation disabled, speak Spanish → pasted text is Spanish (transcription mode)
- [ ] `/v1/audio/translations` is called (verify with Charles proxy or logging)

---

### E9-TASK-03 — Non-English target translation via Chat Completions chaining

**Epic**: Voice Translation
**Status**: `pending`
**Depends on**: E9-TASK-02
**Intersects with**: E9-TASK-04 (API backend enforced before this path runs)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Transcription/OpenAIWhisperService.swift` | modified |

#### Description
When the target language is not English, Murmur chains two API calls:
1. `/v1/audio/transcriptions` — transcribe speech to text in its original language
2. `/v1/chat/completions` — translate the transcribed text to the target language

This produces translated text in any language the OpenAI API supports.

#### Work
- In `OpenAIWhisperService.transcribe(audioURL:targetLanguage:)`:
  - If `targetLanguage != nil && targetLanguage != "en"` (and translation enabled):
    1. Call `/v1/audio/transcriptions` with the audio file → get intermediate text
    2. Build a Chat Completions request:
       - Model: `"gpt-4o-mini"` (cheap, fast)
       - System prompt: `"You are a translator. Translate the user's text to \(targetLanguageName). Return only the translated text, no explanation."`
       - User message: the transcribed text
    3. Parse the `choices[0].message.content` field
    4. Return the translated String
  - Add `private func chatTranslate(_ text: String, to targetLanguage: String, apiKey: String) async throws -> String` helper
  - Delete temp file after the full chain completes

#### Definition of Done (DoD)
- [ ] Non-English target → two API calls are made (transcription + chat)
- [ ] Speaking English, Spanish selected → pasted text is in Spanish
- [ ] Speaking any language, French selected → pasted text is in French
- [ ] Chat Completions errors are caught and re-thrown as `TranscriptionError.apiError`
- [ ] Temp file deleted after chain completes

#### Test Checklist
- [ ] Enable translation, select Spanish, speak English → pasted text is correct Spanish
- [ ] Enable translation, select Japanese, speak English → pasted text is correct Japanese
- [ ] Chat Completions API returns an error → `apiError` is thrown; notification shown; no stuck state
- [ ] Verify two separate HTTP requests are made (via logging or proxy)

---

### E9-TASK-04 — Auto-backend enforcement

**Epic**: Voice Translation
**Status**: `pending`
**Depends on**: E9-TASK-01, E8-TASK-03
**Intersects with**: E8 (backend switching logic in AppDelegate)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/App/AppDelegate.swift` | modified |

#### Description
Translation always requires the OpenAI API. When the user enables translation mode (or selects
a non-English target language), the app must ensure the API backend is active and that an API
key is present. If no key is stored, the user is prompted to open Settings.

#### Work
- Add `func enforceBackendForCurrentConfig()` to `AppDelegate`:
  - If `TranslationConfig.shared.requiresAPI`:
    - If `SettingsModel.shared.whisperBackend != "api"`: switch to API backend (call `applyTranscriptionBackend()`)
    - If `KeychainManager.load() == nil`: show `NSAlert` — "Translation requires an OpenAI API key. Open Settings?" with "Open Settings" and "Cancel" buttons; "Open Settings" calls `openSettings()`
  - Otherwise: do nothing (backend stays as configured)
- Observe `TranslationConfig.shared.isEnabled` and `TranslationConfig.shared.targetLanguage` changes → call `enforceBackendForCurrentConfig()`
- Also call `enforceBackendForCurrentConfig()` at the start of `stopRecordingFlow()` as a last-minute guard

#### Definition of Done (DoD)
- [ ] Enabling translation with local backend selected → backend switches to API automatically
- [ ] Enabling translation with no API key stored → alert shown directing user to Settings
- [ ] Disabling translation → backend reverts to whatever `SettingsModel.whisperBackend` says
- [ ] Guard at `stopRecordingFlow()` entry prevents translation attempt if API key is missing

#### Test Checklist
- [ ] Local backend active, enable translation → backend auto-switches to API
- [ ] Enable translation with no API key → alert shown with "Open Settings" and "Cancel"
- [ ] Press "Open Settings" in alert → SettingsView opens
- [ ] Disable translation → backend returns to local (if that was the prior setting)

---

### E9-TASK-05 — Language picker in menu bar and SettingsView

**Epic**: Voice Translation
**Status**: `pending`
**Depends on**: E9-TASK-01, E5-TASK-04, E8-TASK-04
**Intersects with**: E5 (MenuBarController.swift modified), E8 (SettingsView.swift modified)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/UI/MenuBarController.swift` | modified |
| `Murmur/UI/SettingsView.swift` | modified |

#### Description
Adds the language picker to both surfaces so users can switch languages without opening the
full settings window. Both pickers are bound to `SettingsModel.targetLanguage` (single source
of truth).

#### Work
**Menu Bar Dropdown (MenuBarController)**
- Replace the "Language: English ▸" placeholder (from E5-TASK-04) with a real `NSMenu` submenu
- Submenu title: current target language name (e.g. "Language: Spanish ▸")
- Submenu items: one per `TranslationConfig.supportedLanguages` entry
  - Each item sets `SettingsModel.shared.targetLanguage = code` on action
  - Checkmark on the currently selected language
- Update submenu title whenever `targetLanguage` changes (observe via Combine)
- Also show/hide a "Translation On" indicator in the submenu header

**SettingsView (Translation section)**
- Wire `Toggle("Enable Translation", isOn: $settings.translationEnabled)` — now functional
- Below toggle: `Picker("Target Language", selection: $settings.targetLanguage)` listing all `TranslationConfig.supportedLanguages`
  - Disabled (grayed out) when `translationEnabled == false`

#### Definition of Done (DoD)
- [ ] Dropdown submenu shows all supported languages; checkmark on selected
- [ ] Selecting a language from dropdown updates `SettingsModel.targetLanguage`
- [ ] SettingsView language picker is bound to the same value
- [ ] Changing language in one surface reflects immediately in the other
- [ ] Translation toggle enables/disables the language picker in SettingsView

#### Test Checklist
- [ ] Click menu bar icon → "Language" submenu shows all languages with checkmark on current
- [ ] Select "Spanish" from submenu → checkmark moves; `SettingsModel.targetLanguage == "es"`
- [ ] Open Settings → language picker shows "Spanish" already selected
- [ ] Change language in Settings → menu bar submenu title updates
- [ ] Disable translation in Settings → language picker grayed out in SettingsView

---

### E9-TASK-06 — [TEST] Voice Translation — Integration & Testing

**Epic**: Voice Translation
**Status**: `pending`
**Depends on**: E9-TASK-01, E9-TASK-02, E9-TASK-03, E9-TASK-04, E9-TASK-05
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/e9-translation.md` | modified |
| `todo/roadmap.md` | modified |

#### Description
End-to-end testing task for the Voice Translation epic. Validates the complete translation
feature: configuration, language selection, both API paths (English and non-English targets),
auto-backend enforcement, and UI consistency.

#### Work
- Review all E9 tasks are marked `done`
- Test all supported target languages with at least two source languages
- Test edge cases: no API key, local backend, translation disabled

#### Definition of Done (DoD)
- [ ] E9-TASK-01 is `done`
- [ ] E9-TASK-02 is `done`
- [ ] E9-TASK-03 is `done`
- [ ] E9-TASK-04 is `done`
- [ ] E9-TASK-05 is `done`
- [ ] All test cases below pass
- [ ] No regressions in E1–E8

#### Test Checklist
- [ ] E9-TASK-01: `TranslationConfig` mirrors SettingsModel values; `requiresAPI` correct
- [ ] E9-TASK-02: English target — speak Spanish → pasted text is English; `/v1/audio/translations` used
- [ ] E9-TASK-03: Spanish target — speak English → pasted text is Spanish; two API calls made
- [ ] E9-TASK-04: Enable translation with local backend → API backend auto-selected; no key alert shown if key missing
- [ ] E9-TASK-05: Language picker in menu bar and Settings are in sync; checkmark moves correctly
- [ ] Full v1 user story: select Spanish, press hotkey, speak English, press hotkey → Spanish text pasted into Safari
- [ ] Translation disabled: full local transcription flow still works as before (E7 regression)
- [ ] Regression — E8: API key stored in Keychain; backend switching still functional
- [ ] Regression — E7: Core paste flow unaffected when translation is disabled
- [ ] Regression — E5: Menu bar icon states and floating indicator unaffected by E9 changes
