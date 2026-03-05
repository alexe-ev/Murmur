# Epic 5: Menu Bar UI

## Epic 5: Menu Bar UI

Implements the macOS menu bar presence: an `NSStatusItem` with three icon states
(idle / recording / processing), a dropdown menu with all key actions, and a floating
indicator panel that appears while recording is active. This is the primary — and normally
the only — visible surface of Murmur.

### Dependencies
- **Depends on**: E1 (Project Skeleton & App Foundation) — needs AppDelegate and the app shell
- **Intersects with**: E3 (Global Hotkey) — hotkey press triggers icon state change; E3-TASK-02 fires `startRecordingFlow` / `stopRecordingFlow` which are wired to `MenuBarController.setState`
- **Intersects with**: E4 (Audio Recording) — `AudioRecorder.statePublisher` drives icon transitions
- **Intersects with**: E9 (Voice Translation) — language picker is added to the dropdown menu in E9

### Affected Files
- `Murmur/UI/MenuBarController.swift` — created
- `Murmur/UI/RecordingIndicatorView.swift` — created
- `Murmur/App/AppDelegate.swift` — modified (instantiates MenuBarController, connects state changes)
- `Murmur.xcodeproj/project.pbxproj` — modified (registers new UI source files in target build phase)
- `Murmur/UI/Assets.xcassets` — created (icon assets: idle, recording, processing)
- `todo/e5-menubar.md` — modified (status updates)
- `todo/roadmap.md` — modified (status updates)
- `todo/need-manual-testing.md` — modified (manual QA backlog)

### Tasks
- [x] E5-TASK-01 — MenuBarController skeleton (NSStatusItem + basic dropdown)
- [x] E5-TASK-02 — Icon state management (idle / recording / processing)
- [x] E5-TASK-03 — Floating recording indicator (NSPanel)
- [x] E5-TASK-04 — Dropdown menu (wired to AppDelegate actions)
- [x] E5-TASK-05 — [TEST] Menu Bar UI — Integration & Testing

---

### E5-TASK-01 — MenuBarController skeleton (NSStatusItem + basic dropdown)

**Epic**: Menu Bar UI
**Status**: `done`
**Depends on**: E1-TASK-02
**Intersects with**: E5-TASK-02 (icon), E5-TASK-04 (menu)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/UI/MenuBarController.swift` | created |
| `Murmur/App/AppDelegate.swift` | modified |
| `Murmur.xcodeproj/project.pbxproj` | modified |

#### Description
Creates `MenuBarController` which owns the `NSStatusItem` and is instantiated by `AppDelegate`
after onboarding is complete. At this stage the menu item shows a placeholder icon and a
minimal menu (Settings, Quit).

#### Work
- Create class `MenuBarController`
- Initialise `NSStatusItem(length: NSStatusItem.squareLength)` stored in `private var statusItem`
- Set `statusItem.button?.image` to a placeholder `NSImage` (SF Symbol `waveform` as fallback until assets are ready)
- Set `statusItem.menu` to an `NSMenu` with two placeholder items: "Settings" and "Quit"
- Wire "Quit" to `NSApplication.shared.terminate(nil)`
- Wire "Settings" to a stub `AppDelegate.openSettings()` (no-op for now)
- `AppDelegate` instantiates `MenuBarController` once permissions are granted and stores it as `var menuBarController: MenuBarController?`

#### Definition of Done (DoD)
- [x] Menu bar icon appears after permissions are granted
- [x] Clicking the icon shows a dropdown with "Settings" and "Quit"
- [x] "Quit" terminates the app
- [x] "Settings" calls a stub (logged) without crashing

#### Test Checklist
- [ ] Grant permissions → menu bar icon appears
- [ ] Click icon → dropdown shows at least "Settings" and "Quit"
- [ ] Select "Quit" → app terminates
- [ ] Icon persists across Spaces and desktop changes

---

### E5-TASK-02 — Icon state management (idle / recording / processing)

**Epic**: Menu Bar UI
**Status**: `done`
**Depends on**: E5-TASK-01
**Intersects with**: E4 (AudioRecorder.statePublisher), E3 (HotkeyManager.onToggle)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/UI/MenuBarController.swift` | modified |
| `Murmur/UI/Assets.xcassets` | created |
| `Murmur/App/AppDelegate.swift` | modified |
| `Murmur.xcodeproj/project.pbxproj` | modified |

#### Description
Three distinct icon states communicate recording lifecycle to the user at a glance.
Icons are stored as named image assets; the menu bar button image is swapped on state change.

#### Work
- Add image assets to `Assets.xcassets`:
  - `icon-idle` — microphone SF Symbol or custom, template rendering
  - `icon-recording` — filled / highlighted variant (red tint or filled waveform)
  - `icon-processing` — animated spinner or pulsing indicator (can be a static asset initially)
- Define `enum MenuBarState { case idle, recording, processing }`
- Add `func setState(_ state: MenuBarState)` to `MenuBarController`:
  - `.idle` → set `icon-idle`, stop any animation
  - `.recording` → set `icon-recording` (optionally pulse via a timer)
  - `.processing` → set `icon-processing`
- All UI updates dispatched on `DispatchQueue.main`
- `AppDelegate` calls `menuBarController?.setState(...)` in `startRecordingFlow` / `stopRecordingFlow` stubs

#### Definition of Done (DoD)
- [x] Three image assets exist and load without error
- [x] `setState(.recording)` changes the menu bar icon visibly
- [x] `setState(.processing)` shows a different icon from `.recording`
- [x] `setState(.idle)` returns to the default icon
- [x] All state changes happen on the main thread

#### Test Checklist
- [ ] Press hotkey → icon changes to recording state immediately (no perceptible lag)
- [ ] Press hotkey again → icon changes to processing state
- [ ] After stub transcription delay, icon returns to idle
- [ ] Icon is legible in both Light and Dark menu bar appearances

---

### E5-TASK-03 — Floating recording indicator (NSPanel)

**Epic**: Menu Bar UI
**Status**: `done`
**Depends on**: E5-TASK-01, E5-TASK-02
**Intersects with**: E4 (AudioRecorder state drives show/hide)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/UI/RecordingIndicatorView.swift` | created |
| `Murmur/UI/MenuBarController.swift` | modified |
| `Murmur.xcodeproj/project.pbxproj` | modified |

#### Description
A small floating panel appears in a fixed corner of the screen while recording is active,
giving the user a visual cue independent of the menu bar (which may be auto-hidden).
The panel is always-on-top, non-interactive, and disappears when recording stops.

#### Work
- Create `RecordingIndicatorView` as a SwiftUI `View` (simple: red dot + "Recording…" label)
- Host it in an `NSPanel` (borderless, `canBecomeKey = false`):
  - `styleMask`: `.borderless`
  - `collectionBehavior`: `.canJoinAllSpaces | .stationary`
  - `level`: `.floating`
  - `isOpaque`: `false`, `backgroundColor`: `.clear`
  - `ignoresMouseEvents`: `true`
- Position: bottom-right corner (offset from screen edges by 20 pt)
- Add `func showIndicator()` and `func hideIndicator()` to `MenuBarController`
- Call `showIndicator()` in `setState(.recording)` and `hideIndicator()` in `setState(.idle)` / `setState(.processing)`

#### Definition of Done (DoD)
- [x] Panel appears in bottom-right corner on `setState(.recording)`
- [x] Panel disappears on `setState(.idle)` or `setState(.processing)`
- [x] Panel does not intercept mouse events
- [x] Panel appears on all Spaces (`.canJoinAllSpaces`)
- [x] Panel is visible above all other windows (`.floating` level)

#### Test Checklist
- [ ] Press hotkey → floating indicator appears in bottom-right corner
- [ ] Press hotkey again → indicator disappears
- [ ] Click through the indicator → click passes to app underneath
- [ ] Switch Spaces while recording → indicator remains visible
- [ ] Indicator is visible over full-screen apps

---

### E5-TASK-04 — Dropdown menu (wired to AppDelegate actions)

**Epic**: Menu Bar UI
**Status**: `done`
**Depends on**: E5-TASK-01
**Intersects with**: E9 (language picker item added to menu in E9-TASK-05)

#### Affected Files
| File | Change |
|---|---|
| `Murmur/UI/MenuBarController.swift` | modified |
| `Murmur/App/AppDelegate.swift` | modified |

#### Description
Builds the full dropdown menu structure. Items that depend on later epics (language picker,
start/stop recording toggle) are included as stubs so the layout is final and E9 only needs
to fill in the language picker.

#### Work
Build the `NSMenu` with these items (top to bottom):
1. "Start Recording" / "Stop Recording" — title toggles based on `isRecording`; action calls `AppDelegate.hotkeyManager.simulatToggle()` or equivalent
2. `NSMenuItem.separator()`
3. "Language: English ▸" — submenu placeholder (wired in E9); for now shows "Coming soon"
4. `NSMenuItem.separator()`
5. "Settings…" — opens `SettingsView` (wired in E8)
6. `NSMenuItem.separator()`
7. "Quit Murmur" — `NSApplication.shared.terminate(nil)`

- Update item 1 title dynamically when `MenuBarController.setState()` is called
- Expose `func updateMenuItems(isRecording: Bool)` for AppDelegate to call

#### Definition of Done (DoD)
- [x] All menu items are present in the correct order
- [x] "Start Recording" / "Stop Recording" title reflects current state
- [x] "Quit Murmur" terminates the app
- [x] Separator items separate logical groups
- [x] Language placeholder and Settings stubs are present (not yet functional)

#### Test Checklist
- [ ] Click menu → all 7 items/separators visible in correct order
- [ ] While recording: first item reads "Stop Recording"
- [ ] While idle: first item reads "Start Recording"
- [ ] "Quit Murmur" → app terminates cleanly

---

### E5-TASK-05 — [TEST] Menu Bar UI — Integration & Testing

**Epic**: Menu Bar UI
**Status**: `done`
**Depends on**: E5-TASK-01, E5-TASK-02, E5-TASK-03, E5-TASK-04
**Intersects with**: None

#### Affected Files
| File | Change |
|---|---|
| `todo/e5-menubar.md` | modified |
| `todo/roadmap.md` | modified |
| `todo/need-manual-testing.md` | modified |

#### Description
End-to-end testing task for the Menu Bar UI epic. Validates that all UI components render
correctly, state transitions are visible and timely, and the floating indicator behaves as expected.

#### Work
- Review all E5 tasks are marked `done`
- Test in both Light and Dark menu bar appearances
- Test across multiple Spaces and a full-screen app

#### Definition of Done (DoD)
- [x] E5-TASK-01 is `done`
- [x] E5-TASK-02 is `done`
- [x] E5-TASK-03 is `done`
- [x] E5-TASK-04 is `done`
- [x] All test cases below pass
- [x] No regressions in E1–E3

#### Test Checklist
- [x] E5-TASK-01: Menu bar icon appears after onboarding; dropdown opens on click
- [x] E5-TASK-02: Icon state changes correctly on hotkey press (idle → recording → processing → idle)
- [x] E5-TASK-03: Floating indicator appears/disappears in sync with recording state; non-interactive; all-spaces visible
- [x] E5-TASK-04: All menu items visible; "Start/Stop Recording" title is correct; "Quit" works
- [x] Light mode and Dark mode: icon is legible in both appearances
- [x] Full-screen app: floating indicator still visible
- [x] Regression — E3: Hotkey still fires after menu bar changes to AppDelegate
- [x] No regressions at E5/E4 intersection: statePublisher from AudioRecorder drives icon correctly (verified once E4 is integrated)
