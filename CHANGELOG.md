# Changelog

All notable changes to FnSwitcher are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

The release workflow copies the section for the tagged version into the
GitHub release notes, so keep entries user-facing.

## [Unreleased]

## [0.2.0] - 2026-09-15

### Added
- App icon: a lit keycap on a midnight squircle, shown in Finder, Login Items
  and the About panel.
- Custom menu bar glyphs (keycap with **F** / keycap with sun) replacing the
  generic SF Symbols. Both states share the same frame, so toggling no longer
  shifts the menu bar.
- `design/` holds the SVG sources and the review board for the visual identity.

### Changed
- README now opens with the FnSwitcher banner.

## [0.1.1] - 2026-09-13

### Added
- Homebrew tap: `brew install --cask ozanalbayrak/tap/fnswitcher`. Releases
  bump the cask automatically.
- Open-source project files: contributing guide, security policy, issue and
  pull request templates, Dependabot.

No functional changes to the app.

## [0.1.0] - 2026-09-13

Initial release.

- Toggle the F1–F12 row between standard function keys and media keys with a
  global shortcut (default ⌃⌥F), changeable in Settings…
- Menu bar icon shows the current mode and follows changes made in System
  Settings.
- Launch at Login.
- No Accessibility or Input Monitoring permission required.

[Unreleased]: https://github.com/ozanalbayrak/fn-key-mod-switcher/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/ozanalbayrak/fn-key-mod-switcher/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/ozanalbayrak/fn-key-mod-switcher/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/ozanalbayrak/fn-key-mod-switcher/releases/tag/v0.1.0
