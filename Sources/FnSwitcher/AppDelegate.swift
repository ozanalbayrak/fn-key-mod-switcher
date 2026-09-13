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
