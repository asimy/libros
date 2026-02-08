# Libros

A personal book library management app for tracking physical books in a home library or personal collection. The current target is iOS; multi-platform expansion is planned.

## Features

- Scan book barcodes (ISBN-10 and ISBN-13)
- OCR scanning for printed ISBN text
- Automatic book lookup via Open Library API
- Manual entry for books not found online
- Track multiple copies of the same book
- Organize by author, genre, series, tags, and location
- Rate books and track reading status
- iCloud sync across Apple devices
- Full offline support

## Requirements

- Xcode 15.0 or later
- iOS 17.0+ / macOS 14.0+
- Apple Developer account (for CloudKit sync)

## Project Setup

### Creating the Xcode Project

1. Open Xcode and create a new project. Use Multiplatform > App with `Libros`, SwiftUI, and SwiftData.
2. Delete the generated `ContentView.swift` and `LibrosApp.swift` files.
3. Copy the contents of `Libros/Libros/` into your Xcode project: add `Models`, `Services`, `Views`, `Utilities`, and replace `LibrosApp.swift` and `Views/ContentView.swift`.
4. Configure CloudKit in Signing & Capabilities by adding iCloud and enabling CloudKit, then select a container.
5. Configure camera permissions by adding `NSCameraUsageDescription` to `Info.plist` with a description of camera access for barcode scanning.
6. Build and run.

### Project Structure

```
Libros/
├── Libros/
│   ├── Models/           # SwiftData models
│   ├── Services/         # API and business logic
│   ├── Views/            # SwiftUI views
│   └── Utilities/        # Helper functions
├── LibrosTests/          # Unit and integration tests
└── LibrosUITests/        # UI tests
```

## Architecture

### Data Model

- **Book**: Bibliographic information (title, ISBN, authors, etc.)
- **BookCopy**: Physical copies with format, condition, location
- **Author**: Author information linked to books
- **Series**: Book series with ordering
- **Genre**: Hierarchical categories
- **Tag**: User-defined labels
- **Location**: Physical storage locations

### Key Services

- **OpenLibraryService**: Fetches book metadata from Open Library API
- **ISBNValidator**: Validates and converts ISBN-10/ISBN-13
- **ISBNParser**: Extracts ISBNs from OCR text

## Testing

Run tests from Xcode or command line:

```bash
xcodebuild test -scheme Libros -destination 'platform=iOS Simulator,name=iPhone 15'
```

## License

This project is open source. See LICENSE for details.
