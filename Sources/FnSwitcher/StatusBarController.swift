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
