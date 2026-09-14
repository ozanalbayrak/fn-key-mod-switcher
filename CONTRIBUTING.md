# Contributing

Thanks for helping out! FnSwitcher is intentionally small; please keep changes
focused.

## Workflow

1. Open an issue first for anything beyond a small fix, so we can agree on the
   approach.
2. Fork, branch from `main`, and make your change.
3. Run the checks locally:
   ```bash
   swift test          # unit tests
   scripts/build.sh    # builds build/FnSwitcher.app; try it from the menu bar
   ```
4. Add a line under **Unreleased** in `CHANGELOG.md` if the change is
   user-visible.
5. Open a pull request. CI must pass and the maintainer must approve before it
   can be merged; `main` does not accept direct pushes.

## Guidelines

- Keep `FnSwitcherCore` free of AppKit so it stays unit-testable.
- Code, comments and commit messages are in English.
- Match the existing style; avoid adding dependencies.
- The IOKit calls are deprecated but are the only way to change the mode
  live — see `IOHIDSystemBackend.swift` before touching them.

## Releasing (maintainer)

Move the **Unreleased** entries in `CHANGELOG.md` under a new version heading,
merge that, then push a `v*` tag. The release workflow runs the tests, builds
the app, publishes a GitHub release (with the changelog section as notes) and
bumps the Homebrew cask in
[ozanalbayrak/homebrew-tap](https://github.com/ozanalbayrak/homebrew-tap).
