# Libros

A personal book library management app for iOS, iPadOS, macOS, watchOS, and Linux.

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

1. Open Xcode and create a new project:
   - Select **Multiplatform > App**
   - Product Name: `Libros`
   - Organization Identifier: Your identifier (e.g., `com.yourname`)
   - Interface: **SwiftUI**
   - Storage: **SwiftData**

2. Delete the generated `ContentView.swift` and `LibrosApp.swift` files

3. Copy the contents of `LibrosApp/` into your Xcode project:
   - Drag the `Models`, `Services`, `Views`, and `Utilities` folders into Xcode
   - Copy `LibrosApp.swift` and `Views/ContentView.swift` to replace the defaults

4. Configure CloudKit:
   - Select your project in the navigator
   - Go to **Signing & Capabilities**
   - Click **+ Capability** and add **iCloud**
   - Check **CloudKit**
   - Create a new CloudKit container or select an existing one

5. Configure camera permissions:
   - Open `Info.plist`
   - Add `NSCameraUsageDescription` with value: "Libros needs camera access to scan book barcodes"

6. Build and run!

### Project Structure

```
Libros/
├── LibrosApp/
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
