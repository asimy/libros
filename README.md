# Libros

![Libros cover illustration](book_stack.png)

Libros is a personal book library management app built with SwiftUI and SwiftData. It is designed to track physical books in a home library or personal collection. The current target is iOS; multi-platform expansion is planned and tracked in `Libros/PLAN.md`.

## Features

- Scan book barcodes (ISBN-10 and ISBN-13)
- OCR scanning for printed ISBN text
- Automatic book lookup via Open Library
- Manual entry for books not found online
- Track multiple copies of the same book
- Organize by author, genre, series, tags, and location
- Rate books and track reading status
- iCloud sync across Apple devices
- Full offline support

## Project Structure

```
Libros/
├── Libros.xcodeproj
├── Libros/                # App source code
│   ├── Models/
│   ├── Services/
│   ├── Views/
│   └── Utilities/
└── PLAN.md                # Roadmap and future multi-target layout
```

## Requirements

- Xcode 15.0 or later
- iOS 17.0+ simulator or device
- Apple Developer account (for CloudKit sync)

## Build

Open `Libros/Libros.xcodeproj` in Xcode and run the `Libros` scheme.

CLI build:

```bash
xcodebuild build -scheme Libros -destination 'platform=iOS Simulator,name=iPhone 15'
```

## License

MIT. See `LICENSE.md`.
