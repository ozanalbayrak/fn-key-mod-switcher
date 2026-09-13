# FnSwitcher — Design

**Date:** 2026-09-13
**Status:** Approved

## Problem

macOS has no keyboard shortcut to switch the F1–F12 keys between
"standard function keys" and "special keys" (brightness, volume, …).
Changing the mode requires opening System Settings → Keyboard → Function
Keys every time. The user wants:

1. A configurable global shortcut that toggles the mode.
2. A menu bar icon that always shows the current mode.
3. Launch at login.

## Feasibility (verified 2026-09-13 on macOS 26.6.2)

`IOHIDSetParameter(connect, kIOHIDFKeyModeKey, …)` on an `IOHIDSystem`
connection opened with `kIOHIDParamConnectType` changes the mode
immediately, system-wide, with no TCC permission. `ioreg` confirmed
`HIDFKeyMode` flipped on every keyboard service. The function is
deprecated since 10.12 but still works. Writing
`com.apple.keyboard.fnState` and posting
`com.apple.keyboard.fnstatedidchange` alone does **not** apply the change;
both are still done so System Settings stays in sync.

## Approach

Swift Package (executable) + [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
+ AppKit menu bar app. A shell script assembles the `.app` bundle.

Rejected alternatives: hand-rolled Carbon hotkey + recorder (200–300
extra lines for no benefit); hand-written `.xcodeproj` (fragile without
xcodegen/tuist — the package can be opened in Xcode directly).

## Layout

```
Package.swift                     # macOS 13+, target "FnSwitcher", dep: KeyboardShortcuts
Sources/FnSwitcher/
  main.swift                      # NSApplication bootstrap
  AppDelegate.swift               # wires components together
  FnKeyMode.swift                 # enum: .functionKeys / .mediaKeys (+ icon name, title)
  FnKeyModeController.swift       # read/write mode via IOHIDSystem, defaults, notifications
  StatusBarController.swift       # NSStatusItem + NSMenu, icon updates
  SettingsWindow.swift            # SwiftUI: KeyboardShortcuts.Recorder
  LaunchAtLogin.swift             # SMAppService wrapper
Resources/Info.plist              # LSUIElement=1, bundle id com.ozanalbayrak.FnSwitcher
scripts/build.sh                  # swift build -c release → FnSwitcher.app (ad-hoc signed)
Tests/FnSwitcherTests/            # pure logic tests with a fake HID backend
```

## Components

### FnKeyMode
`enum FnKeyMode { case functionKeys, mediaKeys }` with `hidValue`
(1 = function keys, 0 = media keys — matches `HIDFKeyMode`), `toggled`,
`title`, `menuBarSymbolName`.

### FnKeyModeController
- `var current: FnKeyMode` → `IOHIDGetParameter(kIOHIDFKeyModeKey)`.
- `set(_ mode:)` → `IOHIDSetParameter`, then
  `CFPreferencesSetValue("com.apple.keyboard.fnState", …)` +
  `CFPreferencesSynchronize`, then post
  `com.apple.keyboard.fnstatedidchange` via `DistributedNotificationCenter`.
- `toggle()` → `set(current.toggled)`.
- Observes `com.apple.keyboard.fnstatedidchange` so changes made in
  System Settings update the icon. The menu also re-reads the mode when
  opened, in case a notification was missed.
- The IOKit calls sit behind a `FnKeyModeBackend` protocol so the
  controller's logic is testable with a fake.

### StatusBarController
- Icon: `.functionKeys` → SF Symbol `keyboard`; `.mediaKeys` → `sun.max`.
  Template images so they adapt to light/dark menu bars.
- Menu:
  ```
  Mode: Standard F1–F12          (disabled)
  Switch to Media Keys     ⌃⌥F
  ────────────────────────────
  Launch at Login          ✓
  Settings…
  ────────────────────────────
  Quit FnSwitcher
  ```
- Shortcut: `KeyboardShortcuts.Name("toggleFnMode")`, default ⌃⌥F,
  `onKeyUp` → `toggle()`.

### SettingsWindow
Single small SwiftUI window: "Toggle shortcut: [Recorder]". The value is
persisted by KeyboardShortcuts in UserDefaults and survives restarts.

### LaunchAtLogin
Thin wrapper over `SMAppService.mainApp` (`register`/`unregister`,
`status`). Requires the app to run from a real `.app` bundle.

## Error handling
- If `IOHIDSystem` cannot be opened or `set` fails: icon becomes
  `exclamationmark.triangle`, the menu shows an error line, the app keeps
  running.
- `SMAppService` errors: menu item reflects actual status; a short
  `NSAlert` explains the failure.

## Testing
- Unit (XCTest): `FnKeyMode` toggle/title/symbol; `FnKeyModeController`
  with a fake backend (set/get/toggle, notification-driven refresh,
  failure paths).
- Manual: `scripts/build.sh`, run the app, toggle via shortcut, verify
  with `ioreg -l -w0 | grep -o '"HIDFKeyMode"=[0-9]' | sort | uniq -c`,
  change the mode in System Settings and confirm the icon follows.
