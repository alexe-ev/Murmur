# Epic 3: Global Hotkey

## Epic 3: Global Hotkey

Implements the system-wide hotkey (default: Option+Space) that starts and stops recording from
any application without Murmur needing to be in the foreground. The hotkey is user-configurable,
persisted in `SettingsModel`, and re-registered automatically when changed.

### Dependencies
- **Depends on**: E1 (Project Skeleton & App Foundation) — needs SettingsModel for keyCode/modifiers
- **Intersects with**: E5 (Menu Bar UI) — hotkey press triggers icon state change (idle → recording)
- **Intersects with**: E7 (Paste & Core Flow) — hotkey toggle fires the start/stop recording callbacks wired in AppDelegate

### Affected Files
- `Murmur/Core/HotkeyManager.swift` — created
- `Murmur.xcodeproj/project.pbxproj` — modified
- `Murmur/Settings/SettingsModel.swift` — modified (didSet observer for hotkey keys)
- `Murmur/App/AppDelegate.swift` — modified (registers HotkeyManager, sets toggle callback)
- `todo/e3-hotkey.md` — modified (status updates)
- `todo/roadmap.md` — modified (status updates)

### Tasks
- [x] E3-TASK-01 — Implement HotkeyManager core
- [ ] E3-TASK-02 — Wire toggle callback to AppDelegate
- [ ] E3-TASK-03 — Configurable hotkey (persist and re-register on change)
- [ ] E3-TASK-04 — [TEST] Global Hotkey — Integration & Testing

---

### E3-TASK-01 — Implement HotkeyManager core

**Epic**: Global Hotkey
**Status**: `done`
**Depends on**: E1-TASK-01
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Core/HotkeyManager.swift` | created |
| `Murmur.xcodeproj/project.pbxproj` | modified |

#### Description
`HotkeyManager` registers a system-wide hotkey using the Carbon `RegisterEventHotKey` API and
fires a callback on each press. It manages toggle state internally (first press = start,
second press = stop) and exposes `isRecording: Bool`.

#### Work
- Import `Carbon.HIToolbox`
- Create class `HotkeyManager`
- `func register(keyCode: UInt32, modifiers: UInt32)` — calls `RegisterEventHotKey`, installs a Carbon event handler
- `func unregister()` — calls `UnregisterEventHotKey`
- Internal toggle state: `private(set) var isRecording = false`
- On each hotkey event: flip `isRecording`, call `onToggle?(isRecording)`
- `var onToggle: ((Bool) -> Void)?` — callback; `true` = started recording, `false` = stopped
- Handle registration failure gracefully (log error, surface via `var lastError: Error?`)

#### Definition of Done (DoD)
- [x] `register()` successfully registers the hotkey system-wide
- [x] `unregister()` cleanly removes the registration
- [x] First press → `isRecording` = `true`, `onToggle(true)` called
- [x] Second press → `isRecording` = `false`, `onToggle(false)` called
- [x] Registration errors are captured and logged

#### Test Checklist
- [ ] Call `register(keyCode: 49, modifiers: optionKey)` → Option+Space fires `onToggle` from any app
- [ ] Press twice → `isRecording` toggles correctly each time
- [ ] Call `unregister()` → hotkey no longer fires
- [ ] Attempt to register an already-used system hotkey → error is logged, app does not crash

---

### E3-TASK-02 — Wire toggle callback to AppDelegate

**Epic**: Global Hotkey
**Status**: `pending`
**Depends on**: E3-TASK-01
**Intersects with**: E5 (MenuBarController.setState called here), E7 (AudioRecorder start/stop called here)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/App/AppDelegate.swift` | modified |

#### Description
`AppDelegate` owns `HotkeyManager` and sets its `onToggle` callback. For now, the callback
logs the event and calls stub methods `startRecordingFlow()` / `stopRecordingFlow()` that will
be filled in by E4 (audio) and E7 (core flow).

#### Work
- In `AppDelegate`, add `let hotkeyManager = HotkeyManager()`
- After onboarding is complete (all permissions granted), call `hotkeyManager.register(...)` using `SettingsModel.shared` values
- Set `hotkeyManager.onToggle`:
  ```swift
  hotkeyManager.onToggle = { [weak self] isRecording in
      if isRecording { self?.startRecordingFlow() }
      else            { self?.stopRecordingFlow()  }
  }
  ```
- Implement `startRecordingFlow()` and `stopRecordingFlow()` as empty stubs with log output
- Ensure `HotkeyManager` is only registered after permissions are confirmed (avoids registering before onboarding is complete)

#### Definition of Done (DoD)
- [ ] `AppDelegate` owns `HotkeyManager` and registers it after onboarding
- [ ] `onToggle` callback is set before registration
- [ ] `startRecordingFlow()` and `stopRecordingFlow()` stubs are called on toggle
- [ ] Console logs confirm callback fires

#### Test Checklist
- [ ] Grant permissions → press Option+Space → console shows "startRecordingFlow"
- [ ] Press Option+Space again → console shows "stopRecordingFlow"
- [ ] Before onboarding completes: hotkey is not yet registered (pressing does nothing)

---

### E3-TASK-03 — Configurable hotkey (persist and re-register on change)

**Epic**: Global Hotkey
**Status**: `pending`
**Depends on**: E3-TASK-01, E3-TASK-02
**Intersects with**: E8 (SettingsView hotkey capture field reads/writes these values)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/Settings/SettingsModel.swift` | modified |
| `Murmur/App/AppDelegate.swift` | modified |

#### Description
When the user changes the hotkey in Settings (E8), `SettingsModel` properties update,
`HotkeyManager` must unregister the old hotkey and register the new one automatically.

#### Work
- Add `didSet` observers on `SettingsModel.hotkeyKeyCode` and `SettingsModel.hotkeyModifiers`:
  - Observers call `AppDelegate.shared?.reregisterHotkey()`
- Implement `AppDelegate.reregisterHotkey()`:
  - Calls `hotkeyManager.unregister()`
  - Calls `hotkeyManager.register(keyCode:modifiers:)` with updated values from `SettingsModel`
- Add `static weak var shared: AppDelegate?` to AppDelegate for callback access (set in `applicationDidFinishLaunching`)
- Validate that the new hotkey is not a reserved system shortcut (log a warning if suspicious)

#### Definition of Done (DoD)
- [ ] Changing `hotkeyKeyCode` in SettingsModel triggers re-registration
- [ ] Changing `hotkeyModifiers` in SettingsModel triggers re-registration
- [ ] Old hotkey stops working after re-registration
- [ ] New hotkey works immediately after re-registration

#### Test Checklist
- [ ] Change `hotkeyKeyCode` to keyCode 5 (G) with optionKey modifier → Option+G fires the toggle
- [ ] Old hotkey (Option+Space) no longer fires after change
- [ ] Change back to Space → Option+Space works again
- [ ] Quit and relaunch → new hotkey persists (read from UserDefaults)

---

### E3-TASK-04 — [TEST] Global Hotkey — Integration & Testing

**Epic**: Global Hotkey
**Status**: `pending`
**Depends on**: E3-TASK-01, E3-TASK-02, E3-TASK-03
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/e3-hotkey.md` | modified |
| `todo/roadmap.md` | modified |

#### Description
End-to-end testing task for the Global Hotkey epic. Validates the full hotkey lifecycle:
registration, toggle behaviour, callback firing, user configuration, persistence, and re-registration.

#### Work
- Review all E3 tasks are marked `done`
- Test from multiple apps (Safari, Notes, Terminal) to confirm system-wide operation
- Test hotkey configuration and persistence

#### Definition of Done (DoD)
- [ ] E3-TASK-01 is `done`
- [ ] E3-TASK-02 is `done`
- [ ] E3-TASK-03 is `done`
- [ ] All test cases below pass
- [ ] No regressions in E1 or E2

#### Test Checklist
- [ ] E3-TASK-01: Option+Space fires callback from Safari, Notes, and Terminal (system-wide)
- [ ] E3-TASK-01: Toggle state is correct — odd presses = start, even presses = stop
- [ ] E3-TASK-02: `startRecordingFlow()` / `stopRecordingFlow()` are called by the correct toggle
- [ ] E3-TASK-02: Hotkey not active before permissions are granted
- [ ] E3-TASK-03: Changing hotkey in SettingsModel re-registers immediately; old hotkey dead
- [ ] E3-TASK-03: Hotkey configuration survives app restart
- [ ] Regression — E2: Permission check still works; onboarding still shows when needed
- [ ] No regressions at E3/E5 intersection: icon state will change correctly (verified once E5 is done)
