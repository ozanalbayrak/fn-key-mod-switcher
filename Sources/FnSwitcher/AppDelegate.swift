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
        self.statusBar = statusBar

        KeyboardShortcuts.onKeyUp(for: .toggleFnMode) { [modeController] in
            modeController.toggle()
        }
    }
}
