# Epic 1: Project Skeleton & App Foundation

## Epic 1: Project Skeleton & App Foundation

Sets up the Xcode project from scratch and establishes the core scaffolding every other epic
will build on: the app entry point, the UserDefaults-backed settings model, and launch-at-login
support. Delivers a runnable macOS menu bar–only app with no Dock icon.

### Dependencies
- **Depends on**: None
- **Intersects with**: All subsequent epics — every file in the project lives inside the Xcode
  project created here; SettingsModel is read and written by E3, E5, E6, E8, and E9.

### Affected Files
- `Murmur.xcodeproj/` — created
- `Murmur/App/MurmurApp.swift` — created
- `Murmur/App/AppDelegate.swift` — created
- `Murmur/App/Info.plist` — created
- `Murmur/App/Murmur.entitlements` — created
- `Murmur/Settings/SettingsModel.swift` — created
- `todo/e1-foundation.md` — modified (status updates)
- `todo/roadmap.md` — modified (status updates)

### Tasks
- [x] E1-TASK-01 — Create Xcode project
- [x] E1-TASK-02 — Implement MurmurApp + AppDelegate skeleton
- [x] E1-TASK-03 — Implement SettingsModel (UserDefaults wrapper)
- [x] E1-TASK-04 — LaunchAtLogin via SMAppService
- [ ] E1-TASK-05 — [TEST] Project Skeleton & App Foundation — Integration & Testing

---

### E1-TASK-01 — Create Xcode project

**Epic**: Project Skeleton & App Foundation
**Status**: `done`
**Depends on**: None
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `Murmur.xcodeproj/` | created |
| `Murmur/App/Info.plist` | created |
| `Murmur/App/Murmur.entitlements` | created |

#### Description
Bootstrap the Xcode project with the correct macOS target settings. The app must run as a
menu bar–only app (no Dock icon) and target macOS 13+.

#### Work
- Create a new macOS App project in Xcode, targeting macOS 13.0+
- Set lifecycle to **AppKit** (not SwiftUI lifecycle) so AppDelegate is the entry point
- Add `LSUIElement` = `YES` to `Info.plist` to hide the Dock icon
- Add required entitlements file (`Murmur.entitlements`): `com.apple.security.device.audio-input` for microphone access
- Configure bundle identifier (e.g. `com.murmur.app`)
- Confirm the project structure matches the file tree in `ARCHITECTURE.md §3`

#### Definition of Done (DoD)
- [x] Xcode project exists at the repo root
- [x] App targets macOS 13.0+
- [x] `LSUIElement = YES` set in `Info.plist`
- [x] Entitlements file created with microphone entitlement
- [ ] Project builds without errors or warnings

#### Test Checklist
- [ ] `cmd+B` in Xcode produces a successful build with 0 errors
- [ ] Running the app produces no Dock icon
- [x] Bundle identifier is set and non-default

---

### E1-TASK-02 — Implement MurmurApp + AppDelegate skeleton

**Epic**: Project Skeleton & App Foundation
**Status**: `done`
**Depends on**: E1-TASK-01
**Intersects with**: E2 (AppDelegate will be extended to show OnboardingView), E5 (AppDelegate will own MenuBarController)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/App/MurmurApp.swift` | created |
| `Murmur/App/AppDelegate.swift` | created |

#### Description
Create the Swift entry point. `MurmurApp` uses `@main` with `NSApplicationDelegateAdaptor`
to hand off to `AppDelegate`. `AppDelegate` will grow over time as the coordinator for all
managers; for now it is a minimal skeleton.

#### Work
- Create `MurmurApp.swift` with `@main struct MurmurApp: App` and `NSApplicationDelegateAdaptor` pointing to `AppDelegate`
- Use an empty `body: some Scene { Settings {} }` so SwiftUI doesn't create any default window
- Create `AppDelegate.swift` conforming to `NSApplicationDelegate`
- Implement `applicationDidFinishLaunching(_:)` — log a startup message for now
- Call `NSApp.setActivationPolicy(.accessory)` to hide from Dock (belt-and-suspenders alongside LSUIElement)
- Add stub properties for managers that will be added in later epics (marked `// TODO:`)

#### Definition of Done (DoD)
- [x] App compiles with `MurmurApp` as `@main`
- [x] `AppDelegate.applicationDidFinishLaunching` is called on launch
- [x] `NSApp.activationPolicy` is `.accessory`
- [ ] No Dock icon appears when the app launches

#### Test Checklist
- [ ] Build and run: no Dock icon visible
- [ ] Console shows startup log from `applicationDidFinishLaunching`
- [ ] App does not appear in Cmd+Tab switcher

---

### E1-TASK-03 — Implement SettingsModel (UserDefaults wrapper)

**Epic**: Project Skeleton & App Foundation
**Status**: `done`
**Depends on**: E1-TASK-01
**Intersects with**: E3 (hotkeyKeyCode, hotkeyModifiers), E6 (whisperBackend, whisperModel), E8 (translationEnabled, targetLanguage), E9 (targetLanguage, translationEnabled)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Settings/SettingsModel.swift` | created |

#### Description
Central model for all user preferences. Wraps `UserDefaults` with typed properties and
`@Published` so SwiftUI views and other managers can observe changes reactively.

#### Work
- Create `SettingsModel` as an `ObservableObject` (or actor-isolated singleton)
- Add `@AppStorage` or manual `@Published` + `UserDefaults` backing for every key:

| Property | Key | Type | Default |
|---|---|---|---|
| `hotkeyKeyCode` | `hotkeyKeyCode` | `Int` | `49` (Space) |
| `hotkeyModifiers` | `hotkeyModifiers` | `Int` | `0x00080000` (optionKey) |
| `translationEnabled` | `translationEnabled` | `Bool` | `false` |
| `targetLanguage` | `targetLanguage` | `String` | `"en"` |
| `whisperBackend` | `whisperBackend` | `String` | `"local"` |
| `whisperModel` | `whisperModel` | `String` | `"base"` |
| `launchAtLogin` | `launchAtLogin` | `Bool` | `false` |

- Expose a shared singleton `SettingsModel.shared`
- Write a `reset()` method that restores all defaults (useful for testing)

#### Definition of Done (DoD)
- [x] All 7 keys listed above are present with correct types and defaults
- [x] Properties are observable (SwiftUI or Combine)
- [x] Singleton is accessible via `SettingsModel.shared`
- [x] Values persist across app restarts (UserDefaults)
- [x] `reset()` restores all defaults

#### Test Checklist
- [ ] Set `whisperModel` to `"small"`, quit and relaunch — value survives restart
- [ ] Call `reset()` — all values return to their documented defaults
- [ ] Each property can be read and written without crashing

---

### E1-TASK-04 — LaunchAtLogin via SMAppService

**Epic**: Project Skeleton & App Foundation
**Status**: `done`
**Depends on**: E1-TASK-03
**Intersects with**: E8 (SettingsView toggle for launchAtLogin)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/App/AppDelegate.swift` | modified |
| `Murmur/Settings/SettingsModel.swift` | modified |

#### Description
Allow Murmur to start automatically at login using `SMAppService` (macOS 13+). The toggle
is stored in `SettingsModel.launchAtLogin` and applied both on settings change and on launch.

#### Work
- Import `ServiceManagement` in `AppDelegate`
- On `applicationDidFinishLaunching`: check `SettingsModel.shared.launchAtLogin` and call
  `SMAppService.mainApp.register()` or `.unregister()` accordingly
- Add a `didSet` observer on `SettingsModel.launchAtLogin` that calls register/unregister
  whenever the value changes
- Handle `SMAppService` errors gracefully (log, do not crash)

#### Definition of Done (DoD)
- [x] `SMAppService.mainApp.register()` is called when `launchAtLogin` is `true`
- [x] `SMAppService.mainApp.unregister()` is called when `launchAtLogin` is `false`
- [x] App survives login-item registration without crashing
- [x] `SettingsModel.launchAtLogin` is read and applied at launch

#### Test Checklist
- [ ] Toggle `launchAtLogin` to `true` → app appears in System Settings → General → Login Items
- [ ] Toggle back to `false` → app is removed from Login Items
- [ ] App launches at next login when toggle is `true`

---

### E1-TASK-05 — [TEST] Project Skeleton & App Foundation — Integration & Testing

**Epic**: Project Skeleton & App Foundation
**Status**: `pending`
**Depends on**: E1-TASK-01, E1-TASK-02, E1-TASK-03, E1-TASK-04
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/e1-foundation.md` | modified |
| `todo/roadmap.md` | modified |

#### Description
End-to-end testing task for the Project Skeleton & App Foundation epic. Validates that all
foundation pieces work correctly together: the project builds, the app runs as a menu bar–only
process, settings persist, and launch-at-login toggles correctly.

#### Work
- Review all tasks in E1 are marked `done`
- Run a clean build
- Manually verify all test cases below

#### Definition of Done (DoD)
- [ ] E1-TASK-01 is `done`
- [ ] E1-TASK-02 is `done`
- [ ] E1-TASK-03 is `done`
- [ ] E1-TASK-04 is `done`
- [ ] All test cases below pass
- [ ] No regressions in related areas

#### Test Checklist
- [ ] E1-TASK-01: Clean build succeeds with 0 errors and 0 warnings
- [ ] E1-TASK-02: App launches with no Dock icon, does not appear in Cmd+Tab
- [ ] E1-TASK-03: All 7 UserDefaults keys persist across a quit-and-relaunch cycle; `reset()` restores defaults
- [ ] E1-TASK-04: Toggling `launchAtLogin` registers/unregisters the app in System Settings → Login Items
- [ ] Full flow: fresh install (delete app container), launch, all defaults are applied correctly
