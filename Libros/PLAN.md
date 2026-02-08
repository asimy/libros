# Libros - Book Library Management System

## Overview

A cross-platform book library management system built with SwiftUI and SwiftData, starting with iOS and expanding to iPad, macOS, watchOS, and Linux.

## Current State vs. Planned

This document is both a roadmap and a living snapshot of the codebase. Sections marked as phases describe intended future work, while the data model, services, and structure sections aim to reflect what already exists in the repo. If something here looks out of date, treat the source code as the source of truth and update this plan accordingly.

---

## Technical Stack

| Component | Technology |
|-----------|------------|
| **UI Framework** | SwiftUI |
| **Data Persistence** | SwiftData |
| **Cloud Sync** | CloudKit (via SwiftData) |
| **Barcode Scanning** | AVFoundation / VisionKit |
| **Book Data API** | Open Library |
| **Minimum iOS** | 17.0 |
| **Minimum macOS** | 14.0 (Sonoma) |
| **Linux App** | Go + SQLite (Phase 6) |

---

## Data Model

### Core Entities

```
┌──────────────────┐       ┌─────────────────┐
│      Book        │──────<│     Author      │
├──────────────────┤       ├─────────────────┤
│ id               │       │ id              │
│ isbn10           │       │ name            │
│ isbn13           │       │ sortName        │
│ openLibraryWorkId│       │ openLibraryId   │
│ openLibraryEd.Id │       │ biography       │
│ title            │       └─────────────────┘
│ subtitle         │
│ publisher        │       ┌─────────────────┐
│ publishDate      │──────<│     Genre       │
│ pageCount        │       ├─────────────────┤
│ synopsis         │       │ id              │
│ language         │       │ name            │
│ coverURL         │       │ isUserCreated   │
│ coverData        │       │ parent          │──┐
│ searchableText   │       └─────────────────┘  │
│ notes            │              ▲              │
│ rating           │              └──────────────┘
│ readStatus       │
│ dateAdded        │
│ dateModified     │
└──────────────────┘
       │
       │         ┌─────────────────┐
       ├────────<│      Tag        │
       │         ├─────────────────┤
       │         │ id              │
       │         │ name            │
       │         │ colorHex        │
       │         └─────────────────┘
       │
       │         ┌─────────────────┐
       ├────────>│     Series      │
       │         ├─────────────────┤
       │         │ id              │
       │         │ name            │
       │         │ seriesDescription│
       │         │ expectedCount   │
       │         └─────────────────┘
       │
       │         ┌─────────────────┐
       └────────<│   BookCopy      │ (physical copies)
                 ├─────────────────┤
                 │ id              │
                 │ format          │ (hardcover, paperback, etc.)
                 │ condition       │
                 │ location        │────>┌──────────────────┐
                 │ dateAcquired    │     │    Location      │
                 │ purchasePriceVal│     ├──────────────────┤
                 │ purchasePriceCur│     │ id               │
                 │ notes           │     │ name             │
                 └─────────────────┘     │ locationDescription│
                                         └──────────────────┘
```

### Supporting Models

- `PendingLookup` and `LookupStatus` for queued/offline ISBN lookups
- `LibraryFilter` and `SavedFilter` for persistent search filters
- `SmartCollection` for system-generated groupings
- `CoverImageMode` for cover display preferences

### Design Rationale: Book vs BookCopy

A **Book** represents the bibliographic work (title, author, ISBN, synopsis). A **BookCopy** represents a physical copy you own. This allows:
- Tracking multiple formats (hardcover + paperback of same title)
- Different locations for different copies
- Per-copy condition and notes
- A single source of truth for book metadata

### Book Entity Details

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `isbn10` | String? | 10-digit ISBN |
| `isbn13` | String? | 13-digit ISBN (preferred) |
| `openLibraryWorkId` | String? | Open Library work identifier |
| `openLibraryEditionId` | String? | Open Library edition identifier |
| `title` | String | Required, `@Attribute(.spotlight)` indexed |
| `subtitle` | String? | Optional |
| `authors` | [Author] | Many-to-many relationship |
| `publisher` | String? | Publisher name |
| `publishDate` | Date? | Publication date |
| `pageCount` | Int? | Number of pages |
| `synopsis` | String? | Book description |
| `language` | String? | Language code (e.g., "en") |
| `coverURL` | URL? | Remote cover image URL |
| `coverData` | Data? | Cached cover image, `@Attribute(.externalStorage)` |
| `genres` | [Genre] | From API + user-assigned |
| `tags` | [Tag] | User-defined tags |
| `series` | Series? | Optional series membership |
| `seriesOrder` | Int? | Position in series (1, 2, 3...) |
| `copies` | [BookCopy] | Physical copies owned (cascade delete) |
| `notes` | String? | User notes |
| `rating` | Int? | 1-5 star rating |
| `readStatus` | ReadStatus | .unread, .reading, .read |
| `metadataSource` | MetadataSource | .openLibrary, .ocrExtraction, .quickPhoto, .manual — last non-manual source wins |
| `searchableText` | String | Denormalized search field, `@Attribute(.spotlight)` |
| `dateAdded` | Date | Auto-set on creation |
| `dateModified` | Date | Auto-updated |

### BookCopy Entity Details

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `book` | Book? | Parent book |
| `format` | BookFormat | .hardcover, .paperback, .massMarketPaperback, .ebook, .audiobook, .other |
| `condition` | BookCondition? | .new, .likeNew, .good, .fair, .poor |
| `location` | Location? | Physical location |
| `dateAcquired` | Date? | When you got this copy |
| `purchasePriceValue` | Decimal? | What you paid (optional) |
| `purchasePriceCurrency` | String? | Currency code (e.g., "USD") |
| `notes` | String? | Copy-specific notes |
| `dateAdded` | Date | Auto-set on creation |
| `dateModified` | Date | Auto-updated |

### Author Entity Details

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `name` | String | Display name, `@Attribute(.spotlight)` indexed |
| `sortName` | String | Sort name (e.g., "Asimov, Isaac"), auto-generated |
| `openLibraryId` | String? | Open Library author identifier |
| `biography` | String? | Author biography |
| `books` | [Book] | Many-to-many relationship (inverse) |
| `dateAdded` | Date | Auto-set on creation |

### Series Entity Details

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `name` | String | Series name, `@Attribute(.spotlight)` indexed |
| `seriesDescription` | String? | Optional description |
| `expectedCount` | Int? | Expected total books in series |
| `books` | [Book] | Books in this series (inverse) |
| `dateAdded` | Date | Auto-set on creation |

### Genre Entity Details

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `name` | String | Genre name, `@Attribute(.spotlight)` indexed |
| `isUserCreated` | Bool | Distinguishes imported vs user-created |
| `parent` | Genre? | Parent genre for hierarchy |
| `children` | [Genre] | Child genres (inverse) |
| `books` | [Book] | Many-to-many relationship (inverse) |
| `dateCreated` | Date | Auto-set on creation |

### Tag Entity Details

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `name` | String | Tag name, `@Attribute(.spotlight)` indexed |
| `colorHex` | String? | Color for visual distinction |
| `books` | [Book] | Many-to-many relationship (inverse) |
| `dateCreated` | Date | Auto-set on creation |

### Location Entity Details

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Primary key |
| `name` | String | Location name, `@Attribute(.spotlight)` indexed |
| `locationDescription` | String? | Optional description |
| `bookCopies` | [BookCopy] | Copies at this location (inverse) |
| `dateCreated` | Date | Auto-set on creation |

---

## Project Structure

Currently a single-target iOS app. Multi-target expansion (iPad, macOS, watchOS) is planned for later phases.

```
Libros/
├── Libros.xcodeproj
└── Libros/                          # App source code
    ├── LibrosApp.swift              # App entry point + SwiftData container
    ├── Assets.xcassets/             # App icons, accent color
    ├── Models/
    │   ├── Book.swift
    │   ├── BookCopy.swift
    │   ├── Author.swift
    │   ├── Series.swift
    │   ├── Genre.swift
    │   ├── Tag.swift
    │   ├── Location.swift
    │   ├── BookFormat.swift
    │   ├── BookCondition.swift
    │   ├── ReadStatus.swift
    │   ├── MetadataSource.swift
    │   ├── PendingLookup.swift
    │   ├── LookupStatus.swift
    │   ├── LibraryFilter.swift
    │   ├── SavedFilter.swift
    │   ├── SmartCollection.swift
    │   └── CoverImageMode.swift
    ├── Services/
    │   ├── OpenLibraryService.swift       # API client (actor) + BookLookupService protocol
    │   ├── OfflineLookupService.swift     # Processes queued ISBN lookups
    │   ├── CoverCacheService.swift        # Cover image caching
    │   ├── NetworkMonitor.swift           # Connectivity status
    │   ├── BackgroundTaskCoordinator.swift # Background scheduling
    │   ├── LibraryExportService.swift     # Export pipeline
    │   └── BookMetadataExtractor.swift    # OCR metadata extraction
    ├── Views/
    │   ├── ContentView.swift        # Main TabView container
    │   ├── Library/
    │   │   ├── LibraryView.swift    # Main book list (list + grid modes)
    │   │   ├── BookRowView.swift    # List row
    │   │   └── BookGridItemView.swift # Grid item
    │   ├── BookDetail/
    │   │   ├── BookDetailView.swift
    │   │   └── BookEditView.swift   # Add/edit form with ISBN lookup
    │   ├── Authors/
    │   │   ├── AuthorListView.swift
    │   │   └── AuthorDetailView.swift
    │   ├── Scanner/
    │   │   ├── BarcodeScannerView.swift  # Main scanner (permissions, state, orchestration)
    │   │   ├── CameraPreviewView.swift   # UIViewRepresentable + AVCaptureSession
    │   │   ├── ScanMode.swift            # Barcode vs OCR mode enum
    │   │   ├── ScanResultView.swift      # Book found / not found result sheet
    │   │   ├── GuidedOCRView.swift       # Guided OCR flow
    │   │   ├── QuickPhotoView.swift      # Quick photo flow
    │   │   ├── PendingLookupsView.swift  # Offline lookup queue
    │   │   ├── AddBookView.swift         # Unified add-book entry point
    │   │   └── ImagePicker.swift         # Shared image picker
    │   ├── Search/
    │   │   ├── LibraryFilterView.swift  # Filter sheet for library
    │   │   └── SavedFiltersView.swift   # Manage saved filters
    │   ├── Browse/
    │   │   ├── BrowseView.swift         # Browse tab with collections + organize sections
    │   │   ├── GenreListView.swift      # Genre list with hierarchy
    │   │   ├── GenreDetailView.swift
    │   │   ├── GenreEditView.swift
    │   │   ├── TagListView.swift        # Tag list with colors
    │   │   ├── TagDetailView.swift
    │   │   ├── TagEditView.swift
    │   │   ├── LocationListView.swift   # Location list
    │   │   ├── LocationDetailView.swift
    │   │   ├── LocationEditView.swift
    │   │   ├── SeriesListView.swift     # Series list with progress
    │   │   ├── SeriesDetailView.swift
    │   │   ├── SeriesEditView.swift
    │   │   ├── SmartCollectionsView.swift
    │   │   └── SmartCollectionDetailView.swift
    │   ├── Settings/
    │   │   ├── SettingsView.swift       # Full settings view
    │   │   ├── ExportView.swift         # Library export
    │   │   └── ImportView.swift         # Library import
    │   └── Components/
    │       ├── NetworkStatusBanner.swift
    │       ├── FlowLayout.swift         # Shared wrapping layout
    │       ├── GenrePickerView.swift     # Multi-select genre picker
    │       ├── TagPickerView.swift       # Multi-select tag picker
    │       ├── BookCopyEditView.swift    # Inline copy editor
    │       └── MarkdownNotesView.swift   # Markdown notes editor
    └── Utilities/
        ├── ISBNValidator.swift      # Validate check digits, convert 10↔13
        ├── ISBNParser.swift         # Extract ISBN from OCR text
        ├── ColorUtilities.swift     # Shared color helpers
        └── Extensions/             # Placeholder (not yet implemented)
```

### Future Multi-Target Structure

When additional platform targets are added, the structure will expand:

```
Libros/
├── Libros.xcodeproj
├── Libros/                      # Shared app code (current)
├── LibrosIOS/                   # iOS-specific overrides
├── LibrosMac/                   # macOS-specific
├── LibrosWatch/                 # watchOS-specific
├── LibrosTests/                 # Unit + integration tests
└── LibrosUITests/               # UI tests
```

---

## Implementation Phases

### Phase 1: iOS Foundation (MVP)

**Goal**: Scannable, searchable book library on iPhone

#### 1.1 Project Setup
- [x] Create Xcode project with iOS target
- [x] Configure SwiftData with CloudKit
- [x] Set up project structure
- [x] Add app icons and launch screen

#### 1.2 Data Layer
- [x] Define SwiftData models (Book, BookCopy, Author, Series, Genre, Tag, Location)
- [x] Implement model relationships
- [x] Add computed properties and helper methods
- [x] Create sample data for development (preview container in LibrosApp.swift)

#### 1.3 Open Library Integration
- [x] Implement Open Library API client (actor-based with rate limiting)
- [x] ISBN lookup endpoint
- [x] Search by title/author endpoint
- [x] Parse and map API responses to models
- [x] Handle API errors gracefully (ServiceError enum)
- [ ] Cache responses for offline use

#### 1.4 ISBN Capture (Barcode + OCR)
- [x] Implement camera-based barcode scanner (AVFoundation)
- [x] Support EAN-13 (ISBN-13) and UPC-A barcode formats
- [x] Implement OCR scanning for printed ISBN text (Vision framework)
- [x] ISBN validation for both 10 and 13 digit formats
- [x] Auto-convert ISBN-10 to ISBN-13 for API lookups
- [x] Add manual ISBN entry fallback (ISBN fields in BookEditView)
- [x] Handle camera permissions
- [x] Provide haptic/audio feedback on successful scan
- [x] Toggle between barcode and OCR modes in scanner UI

#### 1.5 Consolidated Add Book Flow
- [x] **Unified "Add Book" screen** accessible from Add tab and Library "+" button
  - [x] Four peer entry methods presented as clear choices:
    1. **ISBN Lookup** — scan barcode/OCR ISBN, then Open Library (existing flow)
    2. **Guided OCR** — step through physical book pages to extract metadata
    3. **Quick Photo** — cover photo + minimal form
    4. **Manual Entry** — full form with all fields (existing BookEditView)
  - [x] When ISBN Lookup fails (not found), offer to continue with methods 2–4
- [x] **Metadata source tracking**:
  - [x] `MetadataSource` enum: `.openLibrary`, `.ocrExtraction`, `.quickPhoto`, `.manual`
  - [x] `metadataSource` field on `Book` model (last non-manual source wins)
  - [x] Set automatically based on which entry method populated the data
  - [x] Display source in BookDetailView (subtle, informational)
- [x] **Guided OCR flow**:
  - [x] Step 1: Capture cover photo (saved as coverData)
  - [x] Step 2: OCR scan title page (extract title, subtitle, authors)
  - [x] Step 3: OCR scan copyright page (extract publisher, date, ISBN)
  - [x] Step 4: Optional back cover scan (extract synopsis)
  - [x] Step 5: Review/edit extracted data before saving
- [x] **Quick Photo flow**:
  - [x] Capture cover photo
  - [x] Minimal form: title + author (required), other fields optional

#### 1.6 Core Views
- [x] Library view (list and grid modes)
- [x] Book detail view
- [x] Add/edit book view (with ISBN lookup integration)
- [x] Scan flow (scan → lookup → confirm/not-found → save)
- [x] Basic search (title, author, ISBN in LibraryView)
- [x] Tab-based navigation (Library, Scan, Authors, Browse, Settings)

#### 1.7 Offline Support
- [x] Ensure all CRUD operations work offline
- [x] Cache cover images locally
- [x] Queue API lookups for when online
- [x] Show sync status indicator

### Phase 2: iOS Polish

**Goal**: Full-featured iOS app

#### 2.1 Enhanced Organization
- [x] Author list and detail views
- [x] Genre browsing with hierarchy
- [x] Tag management (create, edit, delete, assign)
- [x] Location management
- [x] Series browsing
- [x] Smart collections (recently added, currently reading, etc.)

#### 2.2 Advanced Search
- [x] Full-text search across all fields
- [x] Filter by author, genre, tag, location, read status
- [x] Sort options (title, author, date added, rating)
- [x] Save search filters

#### 2.3 Additional Features
- [x] Star rating system (interactive in BookDetailView)
- [x] Read status tracking (inline picker in BookDetailView)
- [x] Rich notes with basic formatting
- [x] Share book details
- [x] Import/export data (JSON)

### Phase 3: iPad Optimization

**Goal**: Take advantage of larger screen

- [ ] Sidebar navigation (NavigationSplitView)
- [ ] Multi-column layout
- [ ] Keyboard shortcuts
- [ ] Drag and drop for organization
- [ ] Split view for book detail
- [ ] Better grid layouts for covers

### Phase 4: macOS App

**Goal**: Full desktop experience

- [ ] Add macOS target to project
- [ ] Menu bar integration
- [ ] Keyboard-driven navigation
- [ ] Multiple window support
- [ ] Toolbar customization
- [ ] Quick Look for book covers
- [ ] Spotlight integration
- [ ] Touch Bar support (if applicable)

### Phase 5: watchOS App

**Goal**: Quick search and reference on wrist

- [ ] Add watchOS target
- [ ] Compact book list
- [ ] Search by title/author
- [ ] View book details (title, author, location)
- [ ] Complication for quick access
- [ ] Siri integration for queries

### Phase 6: Linux App

**Goal**: Desktop Linux client with sync capability

- [ ] Go application with SQLite backend
- [ ] GUI framework (Fyne, Gio, or GTK)
- [ ] Import/export JSON format compatible with iOS export
- [ ] Manual sync via file (Dropbox, USB, etc.)
- [ ] Full CRUD operations
- [ ] Search and filter
- [ ] Future: Sync server for real-time sync

---

## ISBN Handling

### Supported Formats

| Format | Pattern | Check Digit Algorithm |
|--------|---------|----------------------|
| ISBN-10 | `X-XXX-XXXXX-X` | Modulo 11 (may end in 'X') |
| ISBN-13 | `978-X-XXX-XXXXX-X` | Modulo 10 |

### Validation Logic

```swift
enum ISBNValidator {
    /// Validates ISBN-10 check digit (modulo 11)
    static func isValidISBN10(_ isbn: String) -> Bool

    /// Validates ISBN-13 check digit (modulo 10)
    static func isValidISBN13(_ isbn: String) -> Bool

    /// Converts ISBN-10 to ISBN-13
    static func toISBN13(_ isbn10: String) -> String?

    /// Converts ISBN-13 to ISBN-10 (only for 978- prefix)
    static func toISBN10(_ isbn13: String) -> String?

    /// Normalizes input (removes hyphens/spaces) and detects format
    static func parse(_ input: String) -> ISBN?

    /// Formats ISBN-13 with hyphens
    static func formatISBN13(_ isbn: String) -> String

    /// Formats ISBN-10 with hyphens
    static func formatISBN10(_ isbn: String) -> String
}
```

### OCR Text Extraction

The Vision framework returns raw text. We need to:
1. Search for patterns like `ISBN`, `ISBN-10`, `ISBN-13`
2. Extract the following number sequence
3. Remove hyphens and spaces
4. Validate the check digit
5. Handle common OCR errors (0↔O, 1↔I, 8↔B, 5↔S, 6↔G, 9↔g, 0↔D, 2↔Z)

```swift
enum ISBNParser {
    /// Extracts first valid ISBN from OCR text result
    /// Handles formats like:
    ///   "ISBN 978-0-306-40615-7"
    ///   "ISBN-13: 978-0306406157"
    ///   "ISBN: 0-306-40615-2"
    static func extractISBN(from text: String) -> ISBN?

    /// Extracts all valid ISBNs from text
    static func extractAllISBNs(from text: String) -> [ISBN]

    /// Applies OCR error corrections and retries validation
    static func correctOCRErrors(_ text: String) -> ISBN?
}
```

### Scanner Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Scanner View                          │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐   │
│  │              Camera Preview                      │   │
│  │                                                  │   │
│  │   [Barcode detection overlay]                   │   │
│  │   [OCR text recognition region]                 │   │
│  │                                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  [Barcode Mode]  [OCR Mode]  [Manual Entry]            │
│                                                         │
│  Status: "Point camera at barcode..."                  │
└─────────────────────────────────────────────────────────┘

Detection Flow:
1. AVFoundation detects EAN-13/UPC-A barcode
   OR Vision framework recognizes ISBN text
2. Extract and validate ISBN
3. Haptic feedback + visual confirmation
4. Auto-lookup via Open Library API
5. Present result for confirmation
```

---

## Book Metadata Extraction (OCR)

When a book isn't found in Open Library, we extract metadata via OCR from physical pages.

### BookMetadataExtractor Service

```swift
struct ExtractedMetadata {
    var title: String?
    var subtitle: String?
    var authors: [String]
    var publisher: String?
    var publishYear: Int?
    var isbn: String?
    var synopsis: String?
    var confidence: Float  // 0.0 - 1.0
}

class BookMetadataExtractor {
    /// Extract title and authors from title page text
    func extractFromTitlePage(_ text: String) -> ExtractedMetadata

    /// Extract publisher, date, ISBN from copyright page
    func extractFromCopyrightPage(_ text: String) -> ExtractedMetadata

    /// Extract synopsis from back cover text
    func extractFromBackCover(_ text: String) -> ExtractedMetadata

    /// Merge multiple extraction results
    func merge(_ results: [ExtractedMetadata]) -> ExtractedMetadata
}
```

### Extraction Heuristics

**Title Page:**
- Largest/boldest text is usually the title
- "by" or "By" often precedes author names
- Subtitle often follows a colon or is smaller text below title

**Copyright Page:**
- Look for "Copyright ©" or "Published by" patterns
- Year is typically 4 digits near "Copyright" or "Published"
- Publisher often follows "Published by" or precedes address
- ISBN patterns as described in ISBN Handling section

**Back Cover:**
- Continuous prose paragraphs are likely synopsis
- Ignore quotes/reviews (look for quotation marks, attribution)
- Ignore author bio (often starts with "About the Author")

### OCR Confidence Handling

- Vision framework provides per-character confidence scores
- Low confidence text shown with visual indicator in review UI
- User can tap to correct or re-scan specific fields
- Re-scanning merges with higher confidence values

---

## Open Library API Integration

### Endpoints

| Purpose | Endpoint |
|---------|----------|
| ISBN Lookup | `https://openlibrary.org/isbn/{isbn}.json` |
| Works (book info) | `https://openlibrary.org/works/{olid}.json` |
| Authors | `https://openlibrary.org/authors/{olid}.json` |
| Search | `https://openlibrary.org/search.json?q={query}` |
| Covers | `https://covers.openlibrary.org/b/isbn/{isbn}-L.jpg` |

### Response Mapping

Open Library → Libros Model:
- `title` → `Book.title`
- `subtitle` → `Book.subtitle`
- `authors[].name` → `Author.name`
- `publishers[0]` → `Book.publisher`
- `publish_date` → `Book.publishDate`
- `number_of_pages` → `Book.pageCount`
- `description` → `Book.synopsis`
- `subjects` → `Genre` (filtered/mapped)
- Cover URL constructed from ISBN

---

## UI/UX Patterns

### Navigation Structure (iOS)

```
TabView (ContentView.swift)
├── Library ✅
│   ├── All Books (list/grid toggle, sort, search)
│   ├── → Book Detail
│   │   └── → Edit Book
│   └── Add Book sheet (unified: ISBN Lookup, Guided OCR, Quick Photo, Manual)
├── Scan ✅
│   ├── ISBN scanner (barcode + OCR text mode toggle)
│   └── → Scan result → Add Book flow (on not found)
├── Authors ✅
│   ├── Author list (alphabetically grouped, searchable)
│   └── → Author detail (shows books)
├── Browse (placeholder)
│   ├── Genres (placeholder)
│   ├── Tags (placeholder)
│   ├── Locations (placeholder)
│   └── Series (placeholder)
└── Settings (placeholder)
    ├── iCloud sync status (display only)
    ├── Export/Import (placeholder)
    └── Version info
```

### Standard Components

- **Lists**: Native `List` with swipe actions (delete, edit)
- **Search**: `.searchable()` modifier
- **Forms**: `Form` for data entry
- **Sheets**: Modal presentation for add/edit
- **Alerts**: Confirmation dialogs for destructive actions
- **Navigation**: `NavigationStack` with `NavigationLink`

---

## Scalability Considerations

**Target**: Comfortable with 5,000+ books, scalable to 10,000+

### Data Layer

| Concern | Solution |
|---------|----------|
| **Query performance** | Use SwiftData `#Predicate` with indexed fields; avoid fetching all records |
| **Indexed fields** | Index `title`, `isbn13`, `dateAdded`, `readStatus` for fast queries |
| **Batch fetching** | Use `fetchLimit` and `fetchOffset` for pagination |
| **Relationships** | Use lazy loading for relationships (`@Relationship` with default settings) |
| **Sort descriptors** | Pre-define common sort orders to avoid runtime sorting |

### UI Performance

| Concern | Solution |
|---------|----------|
| **List rendering** | Use `LazyVStack` / `LazyVGrid` (SwiftUI handles this in `List` automatically) |
| **Cover images** | Lazy load with `AsyncImage`; cache to disk; use thumbnails in lists |
| **Search** | Debounce search input (300ms); search in background; show loading state |
| **Memory** | Don't cache all Book objects; let SwiftData manage faulting |
| **Scrolling** | Keep row views simple; move complex computation out of view body |

### Image Caching Strategy

```
┌─────────────────────────────────────────────────────────┐
│                    Cover Image Flow                      │
├─────────────────────────────────────────────────────────┤
│  1. Check memory cache (NSCache, ~100 images)           │
│  2. Check disk cache (FileManager, unlimited)           │
│  3. Check Book.coverData (SwiftData, full resolution)   │
│  4. Fetch from Book.coverURL (Open Library)             │
│  5. Save to disk cache + Book.coverData                 │
└─────────────────────────────────────────────────────────┘
```

- **List views**: Use small thumbnails (150px) from disk cache
- **Detail views**: Load full resolution from `coverData` or URL
- **Memory cache**: LRU cache of ~100 recently viewed thumbnails
- **Disk cache**: Store thumbnails separately from full images

### Search Architecture

```swift
// Efficient search with SwiftData
@Query(
    filter: #Predicate<Book> { book in
        book.title.localizedStandardContains(searchText) ||
        book.authors.contains { $0.name.localizedStandardContains(searchText) }
    },
    sort: \Book.title,
    fetchLimit: 50  // Paginate results
)
var searchResults: [Book]
```

- Use `localizedStandardContains` for case/diacritic insensitive search
- Debounce user input to avoid excessive queries
- Show "Load more" or infinite scroll for large result sets

### CloudKit Sync at Scale

| Concern | Solution |
|---------|----------|
| **Initial sync** | CloudKit handles this automatically; may take time for large libraries |
| **Conflict resolution** | SwiftData uses last-writer-wins; acceptable for single-user |
| **Bandwidth** | Cover images sync separately; consider optional image sync setting |
| **Offline queue** | CloudKit queues changes automatically; test with airplane mode |

### Data Model Optimizations (Implemented)

These optimizations are already in place in the current `Book` model:

```swift
@Model
final class Book {
    // Index frequently queried fields
    @Attribute(.spotlight) var title: String  // Also enables Spotlight search
    var isbn13: String?

    // Store cover as external data (not in main record)
    @Attribute(.externalStorage) var coverData: Data?

    // Denormalized search field for fast text search
    @Attribute(.spotlight) var searchableText: String  // "title author1 author2"
}
```

### Performance Testing Checklist

- [ ] Generate 5,000 sample books for testing
- [ ] Measure cold launch time with full library
- [ ] Test scroll performance in list view
- [ ] Test search latency with various query sizes
- [ ] Test memory usage during rapid scrolling
- [ ] Test CloudKit sync time for full library
- [ ] Profile with Instruments (Time Profiler, Allocations)

---

## Help System

### Design Principles

- **Progressive disclosure**: Show basic help first, details on demand
- **Context-sensitive**: Help relevant to current screen/action
- **Accessible**: Full VoiceOver support for all help content
- **Consistent**: Same patterns across all platforms

### Inline Help (In-App)

| Component | Implementation |
|-----------|----------------|
| **Onboarding** | First-launch tutorial: scan a book, explore library, key features |
| **Empty states** | Helpful prompts when lists are empty ("No books yet. Tap + to add your first book") |
| **Tooltips** | Long-press or hover (macOS) for field explanations |
| **Info buttons** | ⓘ icons next to complex features with popover explanations |
| **Contextual hints** | Subtle guidance during actions ("Tip: Hold steady for best scan results") |
| **Error guidance** | Clear error messages with actionable next steps |
| **Accessibility hints** | VoiceOver hints explaining how to interact with elements |

### Help Documentation

Each app includes a comprehensive help section accessible from Settings:

```
Help & Support
├── Getting Started
│   ├── Adding Your First Book
│   ├── Scanning Barcodes
│   ├── When Books Aren't Found
│   └── Organizing Your Library
├── Features
│   ├── Library Management
│   ├── Search & Filters
│   ├── Authors & Series
│   ├── Tags & Locations
│   ├── Notes & Ratings
│   └── Import & Export
├── Sync & Backup
│   ├── iCloud Sync
│   ├── Troubleshooting Sync
│   └── Exporting Your Data
├── Accessibility
│   ├── VoiceOver Support
│   ├── Dynamic Type
│   └── Keyboard Navigation
├── FAQ
│   └── Common questions and answers
└── Troubleshooting
    ├── Scanner Issues
    ├── Sync Problems
    └── Performance Tips
```

### Platform-Specific Documentation

| Platform | Additional Topics |
|----------|-------------------|
| **iOS** | Barcode scanning tips, widget setup, Shortcuts integration |
| **iPad** | Keyboard shortcuts, Split View, drag & drop |
| **macOS** | Menu bar commands, Quick Look, Spotlight search |
| **watchOS** | Complications, Siri queries, glanceable info |
| **Linux** | Installation, sync setup, command-line options |

### Documentation Standards

- Written in clear, concise language (no jargon)
- Step-by-step instructions with numbered lists
- Screenshots/illustrations for complex workflows
- Updated with each release
- Searchable within the app

---

## Testing Strategy

### Philosophy

- **Test pyramid**: Many unit tests, fewer integration tests, minimal E2E tests
- **Coverage target**: 80%+ line coverage for core logic (models, services, utilities)
- **Test-driven**: Write tests alongside features, not as an afterthought
- **Fast feedback**: Unit tests run in seconds, integration tests in CI

### Unit Tests

| Area | What We Test |
|------|--------------|
| **ISBN Validation** | Check digit calculation for ISBN-10 and ISBN-13, including 'X' suffix |
| **ISBN Conversion** | ISBN-10 ↔ ISBN-13 conversion, edge cases |
| **ISBN Parsing** | Extract ISBN from OCR text, various formats, error correction |
| **API Parsing** | Open Library response mapping, missing fields, malformed data |
| **Model Logic** | Computed properties, validation rules, relationship integrity |
| **Search Logic** | Query building, filter combinations, sort ordering |
| **Metadata Extraction** | Title/author extraction from OCR text, confidence scoring |
| **Image Caching** | Cache hits/misses, eviction policy, thumbnail generation |

```swift
// Example: ISBN validation tests
final class ISBNValidatorTests: XCTestCase {
    func testValidISBN10() {
        XCTAssertTrue(ISBNValidator.isValidISBN10("0306406152"))
    }

    func testValidISBN10WithX() {
        XCTAssertTrue(ISBNValidator.isValidISBN10("080442957X"))
    }

    func testInvalidISBN10CheckDigit() {
        XCTAssertFalse(ISBNValidator.isValidISBN10("0306406153"))
    }

    func testISBN10ToISBN13Conversion() {
        XCTAssertEqual(
            ISBNValidator.toISBN13("0306406152"),
            "9780306406157"
        )
    }
}
```

### Integration Tests

| Area | What We Test |
|------|--------------|
| **SwiftData CRUD** | Create, read, update, delete for all models |
| **Relationships** | Book ↔ Author, Book ↔ Series, Book ↔ BookCopy |
| **Query Performance** | Search with 5,000+ records completes in <100ms |
| **Open Library API** | Real API calls (in CI only), response handling |
| **API Mocking** | Mock responses for offline/deterministic testing |
| **Image Pipeline** | Fetch → cache → retrieve flow |
| **Import/Export** | Round-trip JSON export and import |

```swift
// Example: SwiftData integration test
final class BookStorageTests: XCTestCase {
    var container: ModelContainer!

    override func setUp() {
        container = try! ModelContainer(
            for: Book.self, Author.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func testBookAuthorRelationship() async throws {
        let context = container.mainContext
        let author = Author(name: "Isaac Asimov")
        let book = Book(title: "Foundation")
        book.authors.append(author)

        context.insert(book)
        try context.save()

        let fetchedAuthor = try context.fetch(FetchDescriptor<Author>()).first
        XCTAssertEqual(fetchedAuthor?.books.count, 1)
        XCTAssertEqual(fetchedAuthor?.books.first?.title, "Foundation")
    }
}
```

### UI Tests

| Area | What We Test |
|------|--------------|
| **Navigation** | Tab switching, push/pop, modal presentation |
| **Scan Flow** | Camera permission, scan → lookup → save |
| **CRUD Flows** | Add book, edit book, delete book with confirmation |
| **Search** | Type query, see results, clear search |
| **Filters** | Apply filters, combine filters, reset |
| **Accessibility** | VoiceOver navigation, Dynamic Type scaling |

### Snapshot Tests

Using Swift Snapshot Testing for UI consistency:

```swift
func testBookRowAppearance() {
    let book = Book.preview  // Sample book with known data
    let view = BookRowView(book: book)

    assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
}
```

- Capture baseline images for key views
- Detect unintended visual regressions
- Test light/dark mode variants
- Test Dynamic Type sizes (small, default, large, accessibility)

### Performance Tests

```swift
func testSearchPerformanceWith5000Books() {
    measure {
        let results = try! context.fetch(
            FetchDescriptor<Book>(
                predicate: #Predicate { $0.title.contains("Foundation") }
            )
        )
        XCTAssertGreaterThan(results.count, 0)
    }
}
```

- Baseline metrics for search, scroll, launch time
- Fail if performance degrades beyond threshold
- Run on CI with consistent hardware

### Accessibility Tests

- Automated accessibility audit using `accessibilityAudit()`
- Verify all interactive elements have labels
- Test VoiceOver navigation order
- Verify Dynamic Type doesn't break layouts

### Test Infrastructure

| Component | Tool/Approach |
|-----------|---------------|
| **Test runner** | XCTest (built-in) |
| **Mocking** | Protocol-based dependency injection |
| **Snapshots** | swift-snapshot-testing |
| **CI/CD** | GitHub Actions or Xcode Cloud |
| **Coverage** | Xcode coverage reports, enforce 80% minimum |
| **API mocks** | Local JSON fixtures, URLProtocol stubbing |

### Test Organization

```
LibrosTests/
├── UnitTests/
│   ├── ISBNValidatorTests.swift
│   ├── ISBNParserTests.swift
│   ├── OpenLibraryParsingTests.swift
│   ├── MetadataExtractorTests.swift
│   └── SearchLogicTests.swift
├── IntegrationTests/
│   ├── BookStorageTests.swift
│   ├── OpenLibraryServiceTests.swift
│   └── ImageCacheTests.swift
├── SnapshotTests/
│   ├── BookRowSnapshotTests.swift
│   ├── BookDetailSnapshotTests.swift
│   └── LibraryViewSnapshotTests.swift
├── PerformanceTests/
│   └── SearchPerformanceTests.swift
└── Fixtures/
    ├── SampleBooks.json
    ├── OpenLibraryResponses/
    └── TestImages/

LibrosUITests/
├── NavigationTests.swift
├── ScanFlowTests.swift
├── BookCRUDTests.swift
└── AccessibilityTests.swift
```

---

## Coding Standards & Best Practices

### Guiding Principles

1. **Clarity over cleverness**: Code should be readable by future maintainers
2. **Consistency**: Follow established patterns throughout the codebase
3. **Idiomatic code**: Use language features as intended by their designers
4. **Minimal dependencies**: Prefer standard library and first-party frameworks
5. **Documentation**: Public APIs documented, complex logic explained

### Swift Style Guide

Following [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and common community conventions:

**Naming**
```swift
// Types: UpperCamelCase
struct BookMetadata { }
enum ReadStatus { }
protocol BookSearchable { }

// Properties, methods, variables: lowerCamelCase
var pageCount: Int
func fetchBookDetails(for isbn: String) async throws -> Book

// Clarity at the call site
// Good: reads like a sentence
books.remove(at: index)
scanner.startScanning(for: .barcode)

// Avoid: unclear what parameters mean
books.remove(index)  // remove what?
scanner.start(.barcode)  // start what?
```

**Code Organization**
```swift
// MARK: - comments to organize sections
final class BookDetailView: View {
    // MARK: - Properties
    let book: Book
    @State private var isEditing = false

    // MARK: - Body
    var body: some View { ... }

    // MARK: - Private Methods
    private func saveChanges() { ... }
}

// Extensions for protocol conformance
extension Book: Identifiable { }
extension Book: Hashable { }
```

**SwiftUI Conventions**
```swift
// Small, focused views
struct BookRowView: View {
    let book: Book

    var body: some View {
        HStack {
            CoverThumbnail(book: book)  // Extract subviews
            BookInfoStack(book: book)
        }
    }
}

// Use @ViewBuilder for conditional content
@ViewBuilder
private var statusBadge: some View {
    if book.readStatus == .reading {
        Badge("Reading")
    }
}

// Prefer computed properties over methods for view content
private var formattedAuthors: String {
    book.authors.map(\.name).joined(separator: ", ")
}
```

**SwiftData Patterns**
```swift
@Model
final class Book {
    // Required properties first
    var title: String
    var dateAdded: Date

    // Optional properties
    var subtitle: String?
    var isbn13: String?

    // Relationships
    @Relationship(inverse: \Author.books)
    var authors: [Author] = []

    // Computed properties (not persisted)
    var displayTitle: String {
        if let subtitle = subtitle {
            return "\(title): \(subtitle)"
        }
        return title
    }

    // Designated initializer with sensible defaults
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.dateAdded = Date()
    }
}
```

**Error Handling**
```swift
// Define specific error types
enum ISBNError: LocalizedError {
    case invalidFormat
    case invalidCheckDigit
    case conversionFailed
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidFormat: return "ISBN format is not recognized"
        case .invalidCheckDigit: return "ISBN check digit is incorrect"
        case .conversionFailed: return "Could not convert between ISBN formats"
        case .notFound: return "No ISBN found in the provided text"
        }
    }
}

// Use Result or throws, not optionals for failures
func validate(_ isbn: String) throws -> ISBN {
    guard isValidFormat(isbn) else {
        throw ISBNError.invalidFormat
    }
    // ...
}
```

**Async/Await**
```swift
// Prefer async/await over callbacks
func lookupBook(isbn: String) async throws -> BookMetadata {
    let url = OpenLibrary.url(for: isbn)
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(BookMetadata.self, from: data)
}

// Use Task groups for parallel work
func lookupMultiple(isbns: [String]) async throws -> [BookMetadata] {
    try await withThrowingTaskGroup(of: BookMetadata.self) { group in
        for isbn in isbns {
            group.addTask { try await lookupBook(isbn: isbn) }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }
}
```

**Protocol-Oriented Design**
```swift
// Define protocols for testability
protocol BookLookupService: Sendable {
    func lookupByISBN(_ isbn: String) async throws -> BookMetadata
    func search(query: String, limit: Int) async throws -> [SearchResult]
}

// Production implementation (actor for thread safety + rate limiting)
actor OpenLibraryService: BookLookupService {
    func lookupByISBN(_ isbn: String) async throws -> BookMetadata { ... }
    func search(query: String, limit: Int) async throws -> [SearchResult] { ... }
}

// Test mock
final class MockBookLookupService: BookLookupService {
    var stubbedResult: Result<BookMetadata, Error> = .failure(TestError.notConfigured)

    func lookupByISBN(_ isbn: String) async throws -> BookMetadata {
        try stubbedResult.get()
    }
}
```

### Go Style Guide (Linux App)

Following [Effective Go](https://go.dev/doc/effective_go) and community conventions:

**Project Structure**
```
libros-linux/
├── cmd/
│   └── libros/
│       └── main.go           # Entry point
├── internal/
│   ├── models/               # Data structures
│   ├── storage/              # SQLite operations
│   ├── api/                  # Open Library client
│   └── ui/                   # GUI code
├── pkg/
│   └── isbn/                 # Reusable ISBN utilities
├── go.mod
├── go.sum
└── README.md
```

**Naming**
```go
// Exported: UpperCamelCase
type Book struct { ... }
func ValidateISBN(s string) error { ... }

// Unexported: lowerCamelCase
type bookRow struct { ... }
func parseResponse(data []byte) (*Book, error) { ... }

// Interfaces: -er suffix when single method
type Reader interface {
    Read(p []byte) (n int, err error)
}

// Acronyms: consistent case
var isbn string      // not iSBN
type HTTPClient      // not HttpClient
```

**Error Handling**
```go
// Return errors, don't panic
func LookupBook(isbn string) (*Book, error) {
    resp, err := http.Get(url)
    if err != nil {
        return nil, fmt.Errorf("lookup %s: %w", isbn, err)
    }
    // ...
}

// Check errors immediately
book, err := LookupBook(isbn)
if err != nil {
    return err
}
// use book

// Define sentinel errors for expected conditions
var ErrBookNotFound = errors.New("book not found")
```

**Interfaces**
```go
// Accept interfaces, return structs
type BookStorage interface {
    Save(ctx context.Context, book *Book) error
    FindByISBN(ctx context.Context, isbn string) (*Book, error)
}

func NewSQLiteStorage(db *sql.DB) *SQLiteStorage {
    return &SQLiteStorage{db: db}
}
```

### Documentation Standards

**Swift Documentation Comments**
```swift
/// Validates an ISBN string and returns a normalized ISBN value.
///
/// Supports both ISBN-10 and ISBN-13 formats. Hyphens and spaces
/// are automatically removed during validation.
///
/// - Parameter input: The ISBN string to validate (10 or 13 digits)
/// - Returns: A validated `ISBN` value with normalized format
/// - Throws: `ISBNError.invalidFormat` if the string is not a valid ISBN
///
/// ## Example
/// ```swift
/// let isbn = try ISBNValidator.parse("978-0-306-40615-7")
/// print(isbn.isbn13)  // "9780306406157"
/// ```
func parse(_ input: String) throws -> ISBN
```

**Go Documentation Comments**
```go
// ValidateISBN checks if the given string is a valid ISBN-10 or ISBN-13.
// It returns an error if the format is invalid or the check digit is wrong.
//
// Hyphens and spaces are automatically stripped before validation.
func ValidateISBN(s string) error {
    // ...
}
```

### Code Review Checklist

Before merging any PR, verify:

- [ ] Follows naming conventions (Swift API Guidelines / Effective Go)
- [ ] No force unwraps (`!`) without safety comment explaining why
- [ ] Error cases handled with user-friendly messages
- [ ] Async code uses structured concurrency (no detached tasks without reason)
- [ ] New public APIs have documentation comments
- [ ] Complex logic has explanatory comments
- [ ] Tests added for new functionality
- [ ] No compiler warnings
- [ ] Accessibility labels on interactive UI elements
- [ ] Strings are localized (for future i18n support)

### Linting & Formatting

| Language | Tool | Configuration |
|----------|------|---------------|
| Swift | SwiftLint | `.swiftlint.yml` with standard rules |
| Swift | swift-format | For consistent formatting |
| Go | `go fmt` | Standard formatting |
| Go | `go vet` | Static analysis |
| Go | `staticcheck` | Additional linting |

### Version Control Practices

- **Commits**: Small, focused commits with clear messages
- **Branches**: Feature branches from `main`, delete after merge
- **Messages**: Imperative mood ("Add ISBN validation" not "Added...")
- **History**: Prefer rebase for clean history, merge for collaboration

---

## Future Considerations

### Potential Enhancements
- Reading lists / wishlists
- Loan tracking (who borrowed which book)
- Purchase history / price tracking
- Multiple libraries (home, office, etc.)
- Book recommendations
- Goodreads import
- Library Thing import
- CSV import/export

### Sync Server (Future)
- Self-hosted sync server for Linux integration
- Could use Go + PostgreSQL
- REST API for CRUD operations
- WebSocket for real-time sync
- Authentication for multi-user

---

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- Apple Developer account (for CloudKit)
- CloudKit container configured

### Initial Setup Steps
1. Create new Xcode project
2. Configure CloudKit container
3. Implement data models
4. Build Open Library service
5. Create basic UI
6. Implement barcode scanner
7. Test end-to-end flow

---

## Decisions Made

| Question | Decision |
|----------|----------|
| Series tracking | Yes - Books can belong to a Series with order number |
| Multiple copies | Yes - BookCopy entity tracks physical copies with format, condition, location |
| Reading progress | Defer - Start with read status only, add progress tracking later if needed |

## Open Questions (Future)

1. **Custom fields**: Should users be able to add arbitrary metadata to books?
2. **Lending tracking**: Track who borrowed which book and when?
3. **Reading progress**: Add page/percentage tracking when needed?
4. **Library integration**: Integrate with library systems for due dates?
