# Repository Guidelines

## Project Structure & Module Organization

This repo currently hosts the SwiftUI app under `Libros/`.

- `Libros/Libros/` app sources:
  - `Models/`, `Services/`, `Views/`, `Utilities/`
  - `Assets.xcassets/` for app assets
- `Libros/Libros.xcodeproj` Xcode project
- `PLAN.md` describes the intended future layout (multi-target iOS/macOS/watchOS, plus tests).

If you add new targets, follow the structure outlined in `PLAN.md` (e.g., `LibrosIOS/`, `LibrosMac/`, `LibrosWatch/`, `LibrosTests/`).

## Build, Test, and Development Commands

Primary workflow is Xcode. CLI equivalents:

- Build:
  - `xcodebuild build -scheme Libros -destination 'platform=iOS Simulator,name=iPhone 15'`
- Test (when test targets exist):
  - `xcodebuild test -scheme Libros -destination 'platform=iOS Simulator,name=iPhone 15'`

## Coding Style & Naming Conventions

- Use Swift API Design Guidelines and SwiftUI conventions.
- Indentation: 4 spaces; braces on the same line.
- File names match primary types: `Book.swift`, `OpenLibraryService.swift`.
- Use `// MARK: -` sections for larger files (see `Libros/Libros/LibrosApp.swift`).
- Keep style consistent with existing code; no formatter is currently configured in repo.

## Testing Guidelines

- Tests are not checked in yet. Add targets if you introduce tests.
- Follow XCTest naming: `test<Behavior>()`.
- Place tests under `LibrosTests/` and UI tests under `LibrosUITests/` as described in `PLAN.md`.

## Commit & Pull Request Guidelines

- Current history uses short, imperative subjects (e.g., "Add the base app").
- Keep commits focused and descriptive.
- PRs should include:
  - Summary of user-visible changes
  - Screenshots/recordings for UI changes
  - Tested platform + OS version (e.g., iOS 17 simulator)

## Configuration & Security Notes

- CloudKit sync requires an Apple Developer account and iCloud capability setup.
- Camera usage for barcode scanning needs `NSCameraUsageDescription` in `Info.plist`.
- Open Library integration is the primary book metadata source.
