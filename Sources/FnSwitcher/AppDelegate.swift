import AppKit
import FnSwitcherCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    let modeController = FnKeyModeController(backend: IOHIDSystemBackend())
    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar = StatusBarController(controller: modeController)
    }
}
