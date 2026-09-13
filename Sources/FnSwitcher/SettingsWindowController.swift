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
