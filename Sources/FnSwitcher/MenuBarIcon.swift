import AppKit
import FnSwitcherCore

/// Template images for the status item. The mode icons are bundled 18×18 pt
/// PDFs from the design handoff (`design/`); both states share the same
/// keycap frame so toggling never shifts the menu bar.
enum MenuBarIcon {
    static let pointSize = NSSize(width: 18, height: 18)

    static func image(for mode: FnKeyMode) -> NSImage? {
        bundled(mode.menuBarImageName) ?? symbol(fallbackSymbolName(for: mode))
    }

    static var unavailable: NSImage? {
        symbol("exclamationmark.triangle")
    }

    private static func bundled(_ name: String) -> NSImage? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "pdf"),
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        image.size = pointSize
        return image
    }

    private static func symbol(_ name: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }

    /// Used only if a bundled PDF is missing, e.g. in a broken build.
    private static func fallbackSymbolName(for mode: FnKeyMode) -> String {
        switch mode {
        case .functionKeys: "keyboard"
        case .mediaKeys: "sun.max"
        }
    }
}
