# FnSwitcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A macOS menu bar app that toggles the F1–F12 key mode (standard function keys ⇄ media keys) with a user-configurable global shortcut and shows the current mode as a menu bar icon.

**Architecture:** Swift Package with a pure-logic library target (`FnSwitcherCore`: mode enum, backend protocol, controller) and an AppKit executable target (`FnSwitcher`: status item, settings window, launch-at-login). The real backend talks to `IOHIDSystem` via `IOHIDSetParameter`. A shell script wraps the built binary into a `.app` bundle.

**Tech Stack:** Swift 6 (tools 6.2), AppKit, SwiftUI (settings view only), IOKit.hidsystem, ServiceManagement, [KeyboardShortcuts 3.x](https://github.com/sindresorhus/KeyboardShortcuts), XCTest.

**Spec:** `docs/superpowers/specs/2026-09-13-fn-key-mode-switcher-design.md`

## Global Constraints

- Platform floor: `macOS 13` (needed for `SMAppService`).
- Single third-party dependency: `KeyboardShortcuts` `from: "3.1.0"`.
- Bundle identifier: `com.ozanalbayrak.FnSwitcher`; executable/product name: `FnSwitcher`.
- `LSUIElement = true` (no Dock icon).
- HID value mapping: `HIDFKeyMode` **1 = standard function keys**, **0 = media keys** (verified on macOS 26.6.2).
- All code, comments, docs and commit messages in English.
- Menu bar icons: `keyboard` (function keys), `sun.max` (media keys), `exclamationmark.triangle` (error) — SF Symbols, template images.
- Default shortcut: ⌃⌥F. KeyboardShortcuts name: `toggleFnMode`.
- Deviation from the spec layout: core logic lives in a separate library target `FnSwitcherCore` so tests don't need to link the executable. File responsibilities are unchanged.

---

### Task 1: Package scaffold + `FnKeyMode`

**Files:**
- Create: `Package.swift`
- Create: `.gitignore`
- Create: `Sources/FnSwitcherCore/FnKeyMode.swift`
- Create: `Sources/FnSwitcher/main.swift` (placeholder so the package builds)
- Test: `Tests/FnSwitcherCoreTests/FnKeyModeTests.swift`

**Interfaces:**
- Produces: `public enum FnKeyMode: Sendable, Equatable { case functionKeys, mediaKeys }` with `init(hidValue: UInt32)`, `var hidValue: UInt32`, `var toggled: FnKeyMode`, `var title: String`, `var switchActionTitle: String`, `var menuBarSymbolName: String`.

- [ ] **Step 1: Create `Package.swift` and `.gitignore`**

```swift
// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "FnSwitcher",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "3.1.0"),
    ],
    targets: [
        .target(
            name: "FnSwitcherCore",
            path: "Sources/FnSwitcherCore"
        ),
        .executableTarget(
            name: "FnSwitcher",
            dependencies: [
                "FnSwitcherCore",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "Sources/FnSwitcher",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "FnSwitcherCoreTests",
            dependencies: ["FnSwitcherCore"],
            path: "Tests/FnSwitcherCoreTests"
        ),
    ]
)
```

`.gitignore`:
```
.build/
build/
*.xcodeproj
.swiftpm/
.DS_Store
```

- [ ] **Step 2: Placeholder executable**

`Sources/FnSwitcher/main.swift`:
```swift
import AppKit

// Replaced in Task 4.
print("FnSwitcher")
```

- [ ] **Step 3: Write the failing test**

`Tests/FnSwitcherCoreTests/FnKeyModeTests.swift`:
```swift
import XCTest
@testable import FnSwitcherCore

final class FnKeyModeTests: XCTestCase {
    func testHidValueRoundTrip() {
        XCTAssertEqual(FnKeyMode.functionKeys.hidValue, 1)
        XCTAssertEqual(FnKeyMode.mediaKeys.hidValue, 0)
        XCTAssertEqual(FnKeyMode(hidValue: 1), .functionKeys)
        XCTAssertEqual(FnKeyMode(hidValue: 0), .mediaKeys)
    }

    func testUnknownHidValueFallsBackToMediaKeys() {
        XCTAssertEqual(FnKeyMode(hidValue: 42), .mediaKeys)
    }

    func testToggled() {
        XCTAssertEqual(FnKeyMode.functionKeys.toggled, .mediaKeys)
        XCTAssertEqual(FnKeyMode.mediaKeys.toggled, .functionKeys)
    }

    func testTitlesAndSymbols() {
        XCTAssertEqual(FnKeyMode.functionKeys.title, "Standard F1–F12")
        XCTAssertEqual(FnKeyMode.mediaKeys.title, "Media Keys")
        XCTAssertEqual(FnKeyMode.functionKeys.switchActionTitle, "Switch to Media Keys")
        XCTAssertEqual(FnKeyMode.mediaKeys.switchActionTitle, "Switch to Standard F1–F12")
        XCTAssertEqual(FnKeyMode.functionKeys.menuBarSymbolName, "keyboard")
        XCTAssertEqual(FnKeyMode.mediaKeys.menuBarSymbolName, "sun.max")
    }
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `swift test 2>&1 | tail -20`
Expected: compile error — `FnKeyMode` not found.

- [ ] **Step 5: Implement `FnKeyMode`**

`Sources/FnSwitcherCore/FnKeyMode.swift`:
```swift
/// The two behaviours of the F1–F12 row on Apple keyboards.
public enum FnKeyMode: Sendable, Equatable, CaseIterable {
    /// F1–F12 act as standard function keys; media actions need the Fn key.
    case functionKeys
    /// F1–F12 perform brightness/volume/etc.; function keys need the Fn key.
    case mediaKeys

    /// Value of the `HIDFKeyMode` IOHIDSystem parameter. 1 = function keys, 0 = media keys.
    public var hidValue: UInt32 {
        switch self {
        case .functionKeys: 1
        case .mediaKeys: 0
        }
    }

    public init(hidValue: UInt32) {
        self = hidValue == 1 ? .functionKeys : .mediaKeys
    }

    public var toggled: FnKeyMode {
        self == .functionKeys ? .mediaKeys : .functionKeys
    }

    /// Human-readable name of this mode.
    public var title: String {
        switch self {
        case .functionKeys: "Standard F1–F12"
        case .mediaKeys: "Media Keys"
        }
    }

    /// Menu item title for switching *away* from this mode.
    public var switchActionTitle: String {
        "Switch to \(toggled.title)"
    }

    /// SF Symbol shown in the menu bar while this mode is active.
    public var menuBarSymbolName: String {
        switch self {
        case .functionKeys: "keyboard"
        case .mediaKeys: "sun.max"
        }
    }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `swift test 2>&1 | tail -5`
Expected: `Executed 4 tests, with 0 failures`.

- [ ] **Step 7: Commit**

```bash
git add Package.swift Package.resolved .gitignore Sources Tests
git commit -m "Scaffold package and add FnKeyMode"
```

---

### Task 2: `FnKeyModeBackend` protocol + `FnKeyModeController`

**Files:**
- Create: `Sources/FnSwitcherCore/FnKeyModeBackend.swift`
- Create: `Sources/FnSwitcherCore/FnKeyModeController.swift`
- Test: `Tests/FnSwitcherCoreTests/FnKeyModeControllerTests.swift`

**Interfaces:**
- Consumes: `FnKeyMode` from Task 1.
- Produces:
  ```swift
  public protocol FnKeyModeBackend: Sendable {
      func readMode() throws -> FnKeyMode
      func writeMode(_ mode: FnKeyMode) throws
  }
  public enum FnKeyModeError: Error, Equatable {
      case hidSystemUnavailable(kern_return_t)
      case readFailed(kern_return_t)
      case writeFailed(kern_return_t)
  }
  public extension Notification.Name {
      static let fnStateDidChange: Notification.Name   // "com.apple.keyboard.fnstatedidchange"
  }
  @MainActor public final class FnKeyModeController {
      public enum State: Equatable { case mode(FnKeyMode); case unavailable(String) }
      public private(set) var state: State
      public var onStateChange: ((State) -> Void)?
      public init(backend: FnKeyModeBackend, notificationCenter: NotificationCenter = DistributedNotificationCenter.default())
      public func refresh()
      public func set(_ mode: FnKeyMode)
      public func toggle()
  }
  ```

- [ ] **Step 1: Write the failing tests**

`Tests/FnSwitcherCoreTests/FnKeyModeControllerTests.swift`:
```swift
import XCTest
@testable import FnSwitcherCore

/// In-memory backend. `failure` makes every call throw.
final class FakeBackend: FnKeyModeBackend, @unchecked Sendable {
    var mode: FnKeyMode = .mediaKeys
    var failure: FnKeyModeError?
    var writes: [FnKeyMode] = []

    func readMode() throws -> FnKeyMode {
        if let failure { throw failure }
        return mode
    }

    func writeMode(_ mode: FnKeyMode) throws {
        if let failure { throw failure }
        writes.append(mode)
        self.mode = mode
    }
}

@MainActor
final class FnKeyModeControllerTests: XCTestCase {
    private var backend: FakeBackend!
    private var center: NotificationCenter!
    private var controller: FnKeyModeController!
    private var observed: [FnKeyModeController.State] = []

    override func setUp() {
        super.setUp()
        backend = FakeBackend()
        center = NotificationCenter()
        controller = FnKeyModeController(backend: backend, notificationCenter: center)
        observed = []
        controller.onStateChange = { [unowned self] in observed.append($0) }
    }

    func testInitialStateReadsBackend() {
        XCTAssertEqual(controller.state, .mode(.mediaKeys))
    }

    func testSetWritesBackendAndUpdatesState() {
        controller.set(.functionKeys)
        XCTAssertEqual(backend.writes, [.functionKeys])
        XCTAssertEqual(controller.state, .mode(.functionKeys))
        XCTAssertEqual(observed, [.mode(.functionKeys)])
    }

    func testToggleFlipsMode() {
        controller.toggle()
        XCTAssertEqual(controller.state, .mode(.functionKeys))
        controller.toggle()
        XCTAssertEqual(controller.state, .mode(.mediaKeys))
        XCTAssertEqual(backend.writes, [.functionKeys, .mediaKeys])
    }

    func testToggleWhileUnavailableRetriesReadFirst() {
        backend.failure = .readFailed(-1)
        controller.refresh()
        XCTAssertEqual(controller.state, .unavailable("Could not read the Fn key mode (error -1)."))

        backend.failure = nil
        backend.mode = .functionKeys
        controller.toggle()
        XCTAssertEqual(backend.writes, [.mediaKeys])
        XCTAssertEqual(controller.state, .mode(.mediaKeys))
    }

    func testWriteFailureBecomesUnavailable() {
        backend.failure = .writeFailed(-5)
        controller.set(.functionKeys)
        XCTAssertEqual(controller.state, .unavailable("Could not change the Fn key mode (error -5)."))
    }

    func testExternalChangeNotificationRefreshesState() {
        backend.mode = .functionKeys
        center.post(name: .fnStateDidChange, object: nil)
        XCTAssertEqual(controller.state, .mode(.functionKeys))
        XCTAssertEqual(observed, [.mode(.functionKeys)])
    }

    func testUnchangedRefreshDoesNotNotify() {
        controller.refresh()
        XCTAssertEqual(observed, [])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test 2>&1 | grep -E "error:" | head`
Expected: compile errors — `FnKeyModeBackend`, `FnKeyModeController` not found.

- [ ] **Step 3: Implement the backend protocol and error**

`Sources/FnSwitcherCore/FnKeyModeBackend.swift`:
```swift
import Foundation

/// Reads and writes the system-wide Fn key mode.
public protocol FnKeyModeBackend: Sendable {
    func readMode() throws -> FnKeyMode
    func writeMode(_ mode: FnKeyMode) throws
}

public enum FnKeyModeError: Error, Equatable {
    case hidSystemUnavailable(kern_return_t)
    case readFailed(kern_return_t)
    case writeFailed(kern_return_t)
}

public extension Notification.Name {
    /// Posted (distributed) by System Settings and by us whenever the Fn key mode changes.
    static let fnStateDidChange = Notification.Name("com.apple.keyboard.fnstatedidchange")
}
```

- [ ] **Step 4: Implement the controller**

`Sources/FnSwitcherCore/FnKeyModeController.swift`:
```swift
import Foundation

/// Owns the current Fn key mode, applies changes through a backend and
/// follows changes made elsewhere (e.g. System Settings).
@MainActor
public final class FnKeyModeController {
    public enum State: Equatable {
        case mode(FnKeyMode)
        /// The backend failed; the associated value is a user-facing message.
        case unavailable(String)
    }

    public private(set) var state: State {
        didSet {
            guard state != oldValue else { return }
            onStateChange?(state)
        }
    }

    /// Called on the main actor whenever `state` changes.
    public var onStateChange: ((State) -> Void)?

    private let backend: FnKeyModeBackend
    private let notificationCenter: NotificationCenter
    private var observer: NSObjectProtocol?

    public init(
        backend: FnKeyModeBackend,
        notificationCenter: NotificationCenter = DistributedNotificationCenter.default()
    ) {
        self.backend = backend
        self.notificationCenter = notificationCenter
        self.state = Self.read(from: backend)

        observer = notificationCenter.addObserver(
            forName: .fnStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    deinit {
        if let observer {
            notificationCenter.removeObserver(observer)
        }
    }

    /// Re-reads the mode from the backend.
    public func refresh() {
        state = Self.read(from: backend)
    }

    public func set(_ mode: FnKeyMode) {
        do {
            try backend.writeMode(mode)
            state = .mode(mode)
        } catch {
            state = .unavailable(Self.message(for: error, action: "change"))
        }
    }

    /// Flips the mode. If the last read failed, reads again first so a
    /// transient error doesn't leave the shortcut dead.
    public func toggle() {
        if case .unavailable = state {
            refresh()
        }
        guard case .mode(let current) = state else { return }
        set(current.toggled)
    }

    private static func read(from backend: FnKeyModeBackend) -> State {
        do {
            return .mode(try backend.readMode())
        } catch {
            return .unavailable(message(for: error, action: "read"))
        }
    }

    private static func message(for error: Error, action: String) -> String {
        switch error {
        case FnKeyModeError.hidSystemUnavailable(let code):
            "Could not connect to the keyboard system (error \(code))."
        case FnKeyModeError.readFailed(let code), FnKeyModeError.writeFailed(let code):
            "Could not \(action) the Fn key mode (error \(code))."
        default:
            "Could not \(action) the Fn key mode: \(error.localizedDescription)"
        }
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `swift test 2>&1 | tail -5`
Expected: `Executed 11 tests, with 0 failures`.

- [ ] **Step 6: Commit**

```bash
git add Sources/FnSwitcherCore Tests
git commit -m "Add FnKeyModeController with pluggable backend"
```

---

### Task 3: `IOHIDSystemBackend` (real IOKit implementation)

**Files:**
- Create: `Sources/FnSwitcherCore/IOHIDSystemBackend.swift`
- Create: `Sources/FnSwitcher/main.swift` (temporary CLI to exercise the backend; replaced in Task 4)

**Interfaces:**
- Consumes: `FnKeyModeBackend`, `FnKeyModeError`, `Notification.Name.fnStateDidChange`.
- Produces: `public struct IOHIDSystemBackend: FnKeyModeBackend { public init() }`.

No unit test — this touches real hardware state. Verified manually below.

- [ ] **Step 1: Implement the backend**

`Sources/FnSwitcherCore/IOHIDSystemBackend.swift`:
```swift
import Foundation
import IOKit
import IOKit.hidsystem

/// Talks to the `IOHIDSystem` kernel service. `IOHIDGetParameter` /
/// `IOHIDSetParameter` are deprecated since 10.12 but still work (verified on
/// macOS 26.6) and need no TCC permission. Writing the user default and posting
/// the distributed notification keeps System Settings in sync; on their own
/// they do *not* change the live mode.
public struct IOHIDSystemBackend: FnKeyModeBackend {
    private static let fnStateDefaultsKey = "com.apple.keyboard.fnState" as CFString

    public init() {}

    public func readMode() throws -> FnKeyMode {
        let connection = try openConnection()
        defer { IOServiceClose(connection) }

        var value: UInt32 = 0
        var actualSize: IOByteCount = 0
        let result = IOHIDGetParameter(
            connection,
            kIOHIDFKeyModeKey as CFString,
            IOByteCount(MemoryLayout<UInt32>.size),
            &value,
            &actualSize
        )
        guard result == KERN_SUCCESS else { throw FnKeyModeError.readFailed(result) }
        return FnKeyMode(hidValue: value)
    }

    public func writeMode(_ mode: FnKeyMode) throws {
        let connection = try openConnection()
        defer { IOServiceClose(connection) }

        var value = mode.hidValue
        let result = IOHIDSetParameter(
            connection,
            kIOHIDFKeyModeKey as CFString,
            &value,
            IOByteCount(MemoryLayout<UInt32>.size)
        )
        guard result == KERN_SUCCESS else { throw FnKeyModeError.writeFailed(result) }

        CFPreferencesSetValue(
            Self.fnStateDefaultsKey,
            (mode == .functionKeys) as CFBoolean,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
        CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)

        DistributedNotificationCenter.default().postNotificationName(
            .fnStateDidChange,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    private func openConnection() throws -> io_connect_t {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
        guard service != IO_OBJECT_NULL else { throw FnKeyModeError.hidSystemUnavailable(KERN_FAILURE) }
        defer { IOObjectRelease(service) }

        var connection: io_connect_t = IO_OBJECT_NULL
        let result = IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connection)
        guard result == KERN_SUCCESS else { throw FnKeyModeError.hidSystemUnavailable(result) }
        return connection
    }
}
```

- [ ] **Step 2: Temporary CLI to exercise it**

Replace `Sources/FnSwitcher/main.swift`:
```swift
import Foundation
import FnSwitcherCore

// Temporary CLI (replaced in Task 4): `FnSwitcher [toggle]`
let backend = IOHIDSystemBackend()
let before = try backend.readMode()
print("before:", before)
if CommandLine.arguments.contains("toggle") {
    try backend.writeMode(before.toggled)
    print("after:", try backend.readMode())
}
```

- [ ] **Step 3: Build and verify manually**

Run:
```bash
swift build 2>&1 | grep -E "error" ; \
ORIG=$(defaults read -g com.apple.keyboard.fnState 2>/dev/null || echo 0); echo "orig fnState=$ORIG"; \
.build/debug/FnSwitcher toggle && ioreg -l -w0 | grep -o '"HIDFKeyMode"=[0-9]' | sort | uniq -c && defaults read -g com.apple.keyboard.fnState; \
.build/debug/FnSwitcher toggle && ioreg -l -w0 | grep -o '"HIDFKeyMode"=[0-9]' | sort | uniq -c && defaults read -g com.apple.keyboard.fnState
```
Expected: no errors (deprecation *warnings* for `IOHIDGetParameter`/`IOHIDSetParameter` are fine); first toggle flips `HIDFKeyMode` on every service and `fnState` to the opposite of `orig`; second toggle restores both to `orig`.

- [ ] **Step 4: Run the test suite (must still pass)**

Run: `swift test 2>&1 | tail -3`
Expected: `Executed 11 tests, with 0 failures`.

- [ ] **Step 5: Commit**

```bash
git add Sources
git commit -m "Add IOHIDSystem backend for reading and writing the Fn key mode"
```

---

### Task 4: Menu bar app (status item, menu, bundle build script)

**Files:**
- Replace: `Sources/FnSwitcher/main.swift`
- Create: `Sources/FnSwitcher/AppDelegate.swift`
- Create: `Sources/FnSwitcher/StatusBarController.swift`
- Create: `Resources/Info.plist`
- Create: `scripts/build.sh`

**Interfaces:**
- Consumes: `FnKeyModeController`, `IOHIDSystemBackend`, `FnKeyMode` (Tasks 1–3).
- Produces: `final class StatusBarController { init(controller: FnKeyModeController); var onOpenSettings: (() -> Void)?; var launchAtLoginProvider: (() -> Bool)?; var onToggleLaunchAtLogin: (() -> Void)? }` — the last three are wired in Tasks 5 and 6; `AppDelegate` with `let modeController`, `var statusBar`.

The `FnSwitcher` target has `defaultIsolation(MainActor.self)`, so nothing in it needs explicit `@MainActor`.

- [ ] **Step 1: `main.swift`**

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
```

- [ ] **Step 2: `AppDelegate.swift`**

```swift
import AppKit
import FnSwitcherCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    let modeController = FnKeyModeController(backend: IOHIDSystemBackend())
    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar = StatusBarController(controller: modeController)
    }
}
```

- [ ] **Step 3: `StatusBarController.swift`**

```swift
import AppKit
import FnSwitcherCore

/// Owns the NSStatusItem and its menu; mirrors `FnKeyModeController.state`.
final class StatusBarController: NSObject, NSMenuDelegate {
    private let controller: FnKeyModeController
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    private let modeItem = NSMenuItem()
    private let toggleItem = NSMenuItem()
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")
    private let settingsItem = NSMenuItem(title: "Settings…", action: nil, keyEquivalent: ",")

    /// Wired by the app delegate (Task 5).
    var onOpenSettings: (() -> Void)?
    /// Wired by the app delegate (Task 6). Nil hides the menu item.
    var launchAtLoginProvider: (() -> Bool)?
    var onToggleLaunchAtLogin: (() -> Void)?

    init(controller: FnKeyModeController) {
        self.controller = controller
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        buildMenu()
        statusItem.menu = menu
        controller.onStateChange = { [weak self] _ in self?.render() }
        render()
    }

    private func buildMenu() {
        menu.delegate = self

        modeItem.isEnabled = false
        menu.addItem(modeItem)

        toggleItem.target = self
        toggleItem.action = #selector(toggleMode)
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin)
        menu.addItem(launchAtLoginItem)

        settingsItem.target = self
        settingsItem.action = #selector(openSettings)
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit FnSwitcher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    /// Updates icon and menu titles from the controller state.
    private func render() {
        switch controller.state {
        case .mode(let mode):
            setIcon(symbolName: mode.menuBarSymbolName, description: mode.title)
            modeItem.title = "Mode: \(mode.title)"
            toggleItem.title = mode.switchActionTitle
            toggleItem.isEnabled = true
        case .unavailable(let message):
            setIcon(symbolName: "exclamationmark.triangle", description: "Fn key mode unavailable")
            modeItem.title = message
            toggleItem.title = "Retry"
            toggleItem.isEnabled = true
        }

        if let launchAtLoginProvider {
            launchAtLoginItem.isHidden = false
            launchAtLoginItem.state = launchAtLoginProvider() ? .on : .off
        } else {
            launchAtLoginItem.isHidden = true
        }
    }

    private func setIcon(symbolName: String, description: String) {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = "FnSwitcher — \(description)"
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        // Re-read in case a change notification was missed.
        controller.refresh()
        render()
    }

    // MARK: - Actions

    @objc private func toggleMode() {
        controller.toggle()
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func toggleLaunchAtLogin() {
        onToggleLaunchAtLogin?()
        render()
    }
}
```

- [ ] **Step 4: `Resources/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>FnSwitcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.ozanalbayrak.FnSwitcher</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>FnSwitcher</string>
    <key>CFBundleDisplayName</key>
    <string>FnSwitcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key>
    <string>MIT License</string>
</dict>
</plist>
```

- [ ] **Step 5: `scripts/build.sh`**

```bash
#!/usr/bin/env bash
# Builds FnSwitcher.app into ./build. Pass --install to copy it to /Applications.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP="build/FnSwitcher.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/FnSwitcher "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"

# SwiftPM resource bundles (KeyboardShortcuts localizations).
for bundle in .build/release/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    rm -rf /Applications/FnSwitcher.app
    cp -R "$APP" /Applications/
    echo "Installed /Applications/FnSwitcher.app"
fi
```
Then: `chmod +x scripts/build.sh`.

- [ ] **Step 6: Build the bundle and verify manually**

Run: `scripts/build.sh && open build/FnSwitcher.app`
Expected: an icon (`keyboard` or `sun.max`) appears in the menu bar, no Dock icon. Click it: "Mode: …", "Switch to …", "Settings…", "Quit FnSwitcher" (Launch at Login is hidden for now). Click "Switch to …": icon flips; `ioreg -l -w0 | grep -o '"HIDFKeyMode"=[0-9]' | sort | uniq -c` shows the new value. Open System Settings → Keyboard → Keyboard Shortcuts… → Function Keys, flip the toggle: the menu bar icon follows within a second. Restore the original mode. Quit via the menu.

- [ ] **Step 7: Run tests, commit**

Run: `swift test 2>&1 | tail -3` → `0 failures`.
```bash
git add Sources Resources scripts
git commit -m "Add menu bar app with mode indicator and app bundle build script"
```

---

### Task 5: Global shortcut + settings window

**Files:**
- Create: `Sources/FnSwitcher/ShortcutNames.swift`
- Create: `Sources/FnSwitcher/SettingsWindowController.swift`
- Modify: `Sources/FnSwitcher/AppDelegate.swift`
- Modify: `Sources/FnSwitcher/StatusBarController.swift`

**Interfaces:**
- Consumes: `StatusBarController.onOpenSettings`, `toggleItem` (Task 4); `FnKeyModeController.toggle()`.
- Produces: `extension KeyboardShortcuts.Name { static let toggleFnMode }`; `final class SettingsWindowController { init(); func show() }`.

- [ ] **Step 1: Shortcut name with default ⌃⌥F**

`Sources/FnSwitcher/ShortcutNames.swift`:
```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Toggles between standard function keys and media keys. Default ⌃⌥F.
    static let toggleFnMode = Self("toggleFnMode", initial: .init(.f, modifiers: [.control, .option]))
}
```

- [ ] **Step 2: Settings window**

`Sources/FnSwitcher/SettingsWindowController.swift`:
```swift
import AppKit
import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Toggle Fn key mode:", name: .toggleFnMode)
        }
        .padding(20)
        .frame(width: 360)
    }
}

/// Lazily creates a single settings window and brings it to front.
final class SettingsWindowController {
    private var window: NSWindow?

    func show() {
        if window == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            window.title = "FnSwitcher Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        // We're an accessory app, so activate explicitly or the window opens behind others.
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
```

- [ ] **Step 3: Wire shortcut and settings in `AppDelegate`**

Replace `Sources/FnSwitcher/AppDelegate.swift`:
```swift
import AppKit
import FnSwitcherCore
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    let modeController = FnKeyModeController(backend: IOHIDSystemBackend())
    private let settings = SettingsWindowController()
    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusBar = StatusBarController(controller: modeController)
        statusBar.onOpenSettings = { [settings] in settings.show() }
        self.statusBar = statusBar

        KeyboardShortcuts.onKeyUp(for: .toggleFnMode) { [modeController] in
            modeController.toggle()
        }
    }
}
```

- [ ] **Step 4: Show the shortcut in the menu and pause it while the menu is open**

In `StatusBarController.swift`:

Add `import KeyboardShortcuts` at the top.

In `buildMenu()`, after `toggleItem.action = #selector(toggleMode)` add:
```swift
        toggleItem.setShortcut(for: .toggleFnMode)
```

Replace the `NSMenuDelegate` section with:
```swift
    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        // NSMenu tracking buffers global hotkey events; pause them so they don't fire on close.
        KeyboardShortcuts.disable(.toggleFnMode)
        // Re-read in case a change notification was missed.
        controller.refresh()
        render()
    }

    func menuDidClose(_ menu: NSMenu) {
        KeyboardShortcuts.enable(.toggleFnMode)
    }
```

- [ ] **Step 5: Build and verify manually**

Run: `scripts/build.sh && open build/FnSwitcher.app`
Expected:
1. Press ⌃⌥F anywhere: icon flips, `ioreg … HIDFKeyMode` flips.
2. Menu shows `⌃⌥F` next to "Switch to …".
3. "Settings…" opens a window in front with a recorder; record a new shortcut (e.g. ⌃⌥⌘F). Menu now shows the new shortcut; old one does nothing; new one toggles.
4. Quit and reopen the app: the custom shortcut still works (persisted in UserDefaults).
5. Restore the original mode; quit.

- [ ] **Step 6: Run tests, commit**

Run: `swift test 2>&1 | tail -3` → `0 failures`.
```bash
git add Sources
git commit -m "Add configurable global shortcut and settings window"
```

---

### Task 6: Launch at Login

**Files:**
- Create: `Sources/FnSwitcher/LaunchAtLogin.swift`
- Modify: `Sources/FnSwitcher/AppDelegate.swift`

**Interfaces:**
- Consumes: `StatusBarController.launchAtLoginProvider`, `onToggleLaunchAtLogin` (Task 4).
- Produces: `enum LaunchAtLogin { static var isEnabled: Bool; static func setEnabled(_:) throws }`.

- [ ] **Step 1: `LaunchAtLogin.swift`**

```swift
import ServiceManagement

/// Thin wrapper over SMAppService. Only works when running from a real .app bundle.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
```

- [ ] **Step 2: Wire it in `AppDelegate.applicationDidFinishLaunching`**

After `statusBar.onOpenSettings = …` add:
```swift
        statusBar.launchAtLoginProvider = { LaunchAtLogin.isEnabled }
        statusBar.onToggleLaunchAtLogin = {
            do {
                try LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Could not update Launch at Login"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
```

- [ ] **Step 3: Build and verify manually**

Run: `scripts/build.sh --install && open /Applications/FnSwitcher.app`
Expected: "Launch at Login" is visible and unchecked. Click it → checked; System Settings → General → Login Items lists FnSwitcher. Click again → unchecked and removed from Login Items. (Running from `build/` instead of `/Applications` also works, but the login item then points at the build directory.)

- [ ] **Step 4: Run tests, commit**

Run: `swift test 2>&1 | tail -3` → `0 failures`.
```bash
git add Sources
git commit -m "Add Launch at Login menu item"
```

---

### Task 7: README and license

**Files:**
- Create: `README.md`
- Create: `LICENSE`

- [ ] **Step 1: `README.md`**

````markdown
# FnSwitcher

A tiny macOS menu bar app that toggles the F1–F12 keys between
**standard function keys** and **media keys** (brightness, volume, …) with a
global keyboard shortcut — no more digging through System Settings.

- Menu bar icon shows the current mode (`⌨` = standard F1–F12, `☀` = media keys)
- Configurable global shortcut (default **⌃⌥F**)
- Launch at Login
- No Accessibility / Input Monitoring permission required

## Install

Requires macOS 13+ and Xcode 15+ command line tools.

```bash
git clone https://github.com/ozanalbayrak/fn-key-mod-switcher.git
cd fn-key-mod-switcher
scripts/build.sh --install
open /Applications/FnSwitcher.app
```

`scripts/build.sh` without `--install` leaves the bundle at `build/FnSwitcher.app`.
The app is ad-hoc signed; on first launch you may need to allow it in
System Settings → Privacy & Security.

## Usage

Press the shortcut (default ⌃⌥F) to toggle. Click the menu bar icon to see the
mode, toggle, change the shortcut (**Settings…**), or enable **Launch at Login**.

## How it works

The mode is the `HIDFKeyMode` parameter of the `IOHIDSystem` service. FnSwitcher
sets it via `IOHIDSetParameter`, mirrors it into the
`com.apple.keyboard.fnState` user default and posts
`com.apple.keyboard.fnstatedidchange` so System Settings stays in sync. It also
listens for that notification, so changes made in System Settings show up in
the menu bar immediately.

## Development

```bash
swift test            # unit tests (pure logic, fake HID backend)
swift build           # debug build
open Package.swift    # open in Xcode
```

## License

MIT
````

- [ ] **Step 2: `LICENSE`** — standard MIT text, `Copyright (c) 2026 Ozan Albayrak`.

- [ ] **Step 3: Commit**

```bash
git add README.md LICENSE
git commit -m "Add README and MIT license"
```
