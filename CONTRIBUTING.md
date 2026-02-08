# Contributing to Libros

Thanks for helping improve Libros. Contributions are welcome.

## Quick Start

1. Fork the repo and create a feature branch.
2. Make your changes with focused commits.
3. Open a pull request with a clear description and screenshots for UI changes.

## Development

- Open `Libros/Libros.xcodeproj` in Xcode.
- Run the `Libros` scheme on an iOS 17+ simulator.
- If you add tests, prefer XCTest and keep them under `LibrosTests/` as described in `Libros/PLAN.md`.

CLI build:

```bash
xcodebuild build -scheme Libros -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Code Style

- Follow Swift API Design Guidelines and SwiftUI conventions.
- Indentation is 4 spaces.
- File names should match primary types.
- Use `// MARK: -` sections in larger files.

## Pull Request Checklist

- Explain the user-visible change.
- Add screenshots or recordings for UI work.
- Note the tested platform and OS version.
- Keep scope focused to a single feature or fix.
