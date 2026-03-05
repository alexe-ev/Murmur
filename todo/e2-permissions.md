# Epic 2: Permissions & Onboarding

## Epic 2: Permissions & Onboarding

Handles the two system permissions Murmur requires — Microphone and Accessibility — and presents
a first-launch onboarding screen that explains why each permission is needed before requesting it.
Without both permissions the app's core flow cannot function; this epic ensures users are guided
clearly and that the app checks permission state on every foreground event.

### Dependencies
- **Depends on**: E1 (Project Skeleton & App Foundation) — needs AppDelegate and the runnable app shell
- **Intersects with**: E4 (Audio Recording) — mic permission gates `AudioRecorder.startRecording()`; if denied, recording must not be attempted
- **Intersects with**: E7 (Paste & Core Flow) — Accessibility permission gates `PasteController`; if denied, paste cannot be performed

### Affected Files
- `Murmur/Core/PermissionsManager.swift` — created
- `Murmur/UI/OnboardingView.swift` — created
- `Murmur/App/AppDelegate.swift` — modified
- `todo/e2-permissions.md` — modified (status updates)
- `todo/roadmap.md` — modified (status updates)

### Tasks
- [ ] E2-TASK-01 — Implement PermissionsManager
- [ ] E2-TASK-02 — Build OnboardingView
- [ ] E2-TASK-03 — Integrate onboarding into launch flow
- [ ] E2-TASK-04 — [TEST] Permissions & Onboarding — Integration & Testing

---

### E2-TASK-01 — Implement PermissionsManager

**Epic**: Permissions & Onboarding
**Status**: `pending`
**Depends on**: E1-TASK-01
**Intersects with**: E4 (AudioRecorder calls `PermissionsManager.microphoneGranted` before recording), E7 (PasteController calls `PermissionsManager.accessibilityGranted` before pasting)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Core/PermissionsManager.swift` | created |

#### Description
Centralised service for checking and requesting the two permissions Murmur needs.
Published properties allow the UI and other managers to react when status changes.

#### Work
- Create `PermissionsManager` as an `ObservableObject` (singleton: `PermissionsManager.shared`)
- **Microphone**:
  - `@Published var microphoneStatus: AVAuthorizationStatus` — reflects `AVCaptureDevice.authorizationStatus(for: .audio)`
  - `func requestMicrophone() async` — calls `AVCaptureDevice.requestAccess(for: .audio)` and updates `microphoneStatus`
  - Computed `var microphoneGranted: Bool`
- **Accessibility**:
  - `@Published var accessibilityGranted: Bool` — wraps `AXIsProcessTrusted()`
  - `func checkAccessibility()` — refreshes `accessibilityGranted`
  - `func openAccessibilitySettings()` — opens `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility` via `NSWorkspace`
- `var allGranted: Bool` — `true` only when both permissions are granted
- Add a periodic timer (every 2 s) that re-checks `AXIsProcessTrusted()` while the onboarding window is open, so the UI updates as soon as the user grants Accessibility in System Settings

#### Definition of Done (DoD)
- [ ] `microphoneStatus` reflects the true system state
- [ ] `requestMicrophone()` triggers the native macOS permission dialog
- [ ] `accessibilityGranted` reflects `AXIsProcessTrusted()` result
- [ ] `openAccessibilitySettings()` opens the correct System Settings pane
- [ ] `allGranted` is `true` only when both permissions are granted
- [ ] Polling timer refreshes Accessibility status while active

#### Test Checklist
- [ ] Fresh app (permissions not granted): `microphoneGranted` = `false`, `accessibilityGranted` = `false`
- [ ] Call `requestMicrophone()` → system dialog appears; after granting, `microphoneGranted` = `true`
- [ ] Call `openAccessibilitySettings()` → correct pane opens in System Settings
- [ ] Grant Accessibility in System Settings → `accessibilityGranted` becomes `true` within 2 s (poll)

---

### E2-TASK-02 — Build OnboardingView

**Epic**: Permissions & Onboarding
**Status**: `pending`
**Depends on**: E2-TASK-01
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `Murmur/UI/OnboardingView.swift` | created |

#### Description
SwiftUI onboarding screen shown on first launch (or any time a required permission is missing).
Explains each permission in plain language, shows its current status, and provides action buttons.
The screen dismisses automatically once `PermissionsManager.shared.allGranted` becomes `true`.

#### Work
- Create `OnboardingView: View` observing `PermissionsManager.shared`
- Two permission rows, each with:
  - Icon + title + one-sentence explanation
  - Status badge: "Granted ✓" (green) or "Required" (orange)
  - Action button: "Grant Access" (mic) or "Open Settings" (accessibility)
- Mic row button calls `PermissionsManager.shared.requestMicrophone()`
- Accessibility row button calls `PermissionsManager.shared.openAccessibilitySettings()`
- When `allGranted` becomes `true`, call a dismiss closure provided by the parent
- App icon + title at the top of the screen
- Minimal, clean layout consistent with macOS HIG

#### Definition of Done (DoD)
- [ ] Both permission rows are visible with correct explanations
- [ ] Status badges update reactively when permissions change
- [ ] Mic grant button triggers the system dialog
- [ ] Accessibility button opens System Settings
- [ ] View auto-dismisses when `allGranted` flips to `true`

#### Test Checklist
- [ ] Launch with no permissions → both rows show "Required"
- [ ] Grant mic → mic row updates to "Granted ✓" without relaunch
- [ ] Tap "Open Settings" for Accessibility → correct pane opens
- [ ] Grant Accessibility in System Settings → view dismisses within 2 s

---

### E2-TASK-03 — Integrate onboarding into launch flow

**Epic**: Permissions & Onboarding
**Status**: `pending`
**Depends on**: E2-TASK-01, E2-TASK-02
**Intersects with**: E5 (MenuBarController is set up in AppDelegate — ensure onboarding doesn't conflict with menu bar init), E1 (AppDelegate is modified here)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/App/AppDelegate.swift` | modified |

#### Description
Wire `PermissionsManager` into `AppDelegate` so that the onboarding window is shown on launch
if any permission is missing, and re-checked whenever the app comes to the foreground.

#### Work
- In `applicationDidFinishLaunching`: check `PermissionsManager.shared.allGranted`
  - If `false` → present `OnboardingView` in an `NSWindow` (centered, non-resizable, closable only when `allGranted`)
- In `applicationDidBecomeActive`: call `PermissionsManager.shared.checkAccessibility()` to refresh state
- The onboarding `NSWindow` should not have a standard close button when permissions are still missing
  (use `styleMask` without `.closable`, or disable the close button)
- Once all permissions are granted, close the onboarding window and proceed with normal startup
  (MenuBarController setup, HotkeyManager registration, etc.)

#### Definition of Done (DoD)
- [ ] Onboarding window appears on first launch when permissions are missing
- [ ] Onboarding window cannot be closed while permissions are incomplete
- [ ] `applicationDidBecomeActive` triggers an Accessibility re-check
- [ ] Onboarding window closes automatically when all permissions granted
- [ ] Normal app flow (menu bar setup) continues after onboarding is dismissed

#### Test Checklist
- [ ] Fresh launch (no permissions): onboarding window appears immediately
- [ ] Attempt to close window while permissions missing → window stays open
- [ ] Grant both permissions → window closes and menu bar icon appears
- [ ] Quit and relaunch with permissions already granted → no onboarding window shown

---

### E2-TASK-04 — [TEST] Permissions & Onboarding — Integration & Testing

**Epic**: Permissions & Onboarding
**Status**: `pending`
**Depends on**: E2-TASK-01, E2-TASK-02, E2-TASK-03
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/e2-permissions.md` | modified |
| `todo/roadmap.md` | modified |

#### Description
End-to-end testing task for the Permissions & Onboarding epic. Validates the full permission
flow from a fresh install through both permission grants to the app entering its normal operating
state, and verifies the flow on subsequent launches.

#### Work
- Review all tasks in E2 are marked `done`
- Delete app container to simulate fresh install: `rm -rf ~/Library/Containers/com.murmur.app`
- Run through the full permission flow manually
- Verify subsequent launch behaviour

#### Definition of Done (DoD)
- [ ] E2-TASK-01 is `done`
- [ ] E2-TASK-02 is `done`
- [ ] E2-TASK-03 is `done`
- [ ] All test cases below pass
- [ ] No regressions in E1 (app still launches with no Dock icon, settings still persist)

#### Test Checklist
- [ ] E2-TASK-01: `PermissionsManager` correctly reports both permissions as not granted on a fresh install
- [ ] E2-TASK-02: OnboardingView renders with both rows in "Required" state; status badges update live
- [ ] E2-TASK-03: Onboarding window is shown on launch when permissions are missing; cannot be dismissed early
- [ ] Full flow: grant mic → row updates; open Accessibility settings → grant → view dismisses → menu bar icon appears
- [ ] Subsequent launch with all permissions granted: no onboarding window, app enters normal state immediately
- [ ] Regression — E1: No Dock icon, settings defaults still apply after onboarding changes to AppDelegate
- [ ] Verify `PermissionsManager.allGranted` is the single source of truth (no duplicate permission checks elsewhere)
