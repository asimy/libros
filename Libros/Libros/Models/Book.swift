import Foundation
import SwiftData

/// Represents a book (bibliographic work) in the library
@Model
final class Book {
    // MARK: - Identifiers

    /// Unique identifier
    var id: UUID

    /// 10-digit ISBN (legacy format)
    var isbn10: String?

    /// 13-digit ISBN (preferred format)
    var isbn13: String?

    /// Open Library work ID for linking to external data
    var openLibraryWorkId: String?

    /// Open Library edition ID
    var openLibraryEditionId: String?

    // MARK: - Core Metadata

    /// Book title
    @Attribute(.spotlight)
    var title: String

    /// Book subtitle
    var subtitle: String?

    /// Publisher name
    var publisher: String?

    /// Publication date
    var publishDate: Date?

    /// Number of pages
    var pageCount: Int?

    /// Book description or synopsis
    var synopsis: String?

    /// Language code (e.g., "en", "es", "fr")
    var language: String?

    // MARK: - Cover Image

    /// URL to cover image (from Open Library or other source)
    var coverURL: URL?

    /// Cached cover image data (stored externally to keep main record small)
    @Attribute(.externalStorage)
    var coverData: Data?

    // MARK: - User Data

    /// User's personal notes about this book
    var notes: String?

    /// User's rating (1-5 stars)
    var rating: Int?

    /// Current reading status
    var readStatus: ReadStatus

    /// How this book's metadata was originally obtained
    var metadataSource: MetadataSource = MetadataSource.manual

    // MARK: - Series Information

    /// Position in series (1, 2, 3, etc.)
    var seriesOrder: Int?

    // MARK: - Timestamps

    /// When this book was added to the library
    var dateAdded: Date

    /// When this book was last modified
    var dateModified: Date

    // MARK: - Searchable Text (Denormalized)

    /// Combined searchable text for efficient full-text search
    /// Contains: title, subtitle, author names, ISBN
    @Attribute(.spotlight)
    var searchableText: String

    // MARK: - Relationships

    /// Authors of this book
    var authors: [Author] = []

    /// Genres/categories
    var genres: [Genre] = []

    /// User-defined tags
    var tags: [Tag] = []

    /// Series this book belongs to
    var series: Series?

    /// Physical copies of this book
    @Relationship(deleteRule: .cascade, inverse: \BookCopy.book)
    var copies: [BookCopy] = []

    // MARK: - Computed Properties

    /// Primary ISBN (prefers ISBN-13)
    var primaryISBN: String? {
        isbn13 ?? isbn10
    }

    /// Formatted author string (e.g., "Isaac Asimov" or "Isaac Asimov, Robert Silverberg")
    var authorNames: String {
        guard !authors.isEmpty else { return "Unknown Author" }
        return authors.map(\.name).joined(separator: ", ")
    }

    /// Display title including subtitle if present
    var fullTitle: String {
        if let subtitle = subtitle, !subtitle.isEmpty {
            return "\(title): \(subtitle)"
        }
        return title
    }

    /// Formatted series information (e.g., "Foundation #3")
    var seriesInfo: String? {
        guard let series = series else { return nil }
        if let order = seriesOrder {
            return "\(series.name) #\(order)"
        }
        return series.name
    }

    /// Number of physical copies owned
    var copyCount: Int {
        copies.count
    }

    /// Whether user has at least one copy
    var isOwned: Bool {
        !copies.isEmpty
    }

    /// Cover image URL for Open Library (constructed from ISBN)
    var openLibraryCoverURL: URL? {
        guard let isbn = primaryISBN else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg")
    }

    /// Formatted publication year
    var publishYear: String? {
        guard let date = publishDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Initialization

    init(
        title: String,
        subtitle: String? = nil,
        isbn10: String? = nil,
        isbn13: String? = nil,
        readStatus: ReadStatus = .unread,
        metadataSource: MetadataSource = .manual
    ) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.isbn10 = isbn10
        self.isbn13 = isbn13
        self.readStatus = readStatus
        self.metadataSource = metadataSource
        self.dateAdded = Date()
        self.dateModified = Date()
        self.searchableText = title
    }

    // MARK: - Methods

    /// Updates the searchable text field based on current data
    func updateSearchableText() {
        var components = [title]

        if let subtitle = subtitle {
            components.append(subtitle)
        }

        components.append(contentsOf: authors.map(\.name))

        if let isbn10 = isbn10 {
            components.append(isbn10)
        }

        if let isbn13 = isbn13 {
            components.append(isbn13)
        }

        if let publisher = publisher {
            components.append(publisher)
        }

        if let synopsis = synopsis {
            components.append(synopsis)
        }

        components.append(contentsOf: genres.map(\.name))
        components.append(contentsOf: tags.map(\.name))

        if let notes = notes {
            components.append(notes)
        }

        searchableText = components.joined(separator: " ")
        dateModified = Date()
    }

    /// Formatted text for sharing
    var shareText: String {
        var lines: [String] = []
        lines.append(fullTitle)
        lines.append("by \(authorNames)")

        if let seriesInfo = seriesInfo {
            lines.append("Series: \(seriesInfo)")
        }

        if let rating = rating {
            let stars = String(repeating: "\u{2B50}", count: rating)
            lines.append("Rating: \(stars)")
        }

        if let isbn = primaryISBN {
            lines.append("ISBN: \(isbn)")
        }

        return lines.joined(separator: "\n")
    }

    /// Sets the rating, clamping to valid range
    func setRating(_ value: Int?) {
        if let value = value {
            rating = max(1, min(5, value))
        } else {
            rating = nil
        }
        dateModified = Date()
    }
}

// MARK: - Sample Data

extension Book {
    static var preview: Book {
        let book = Book(
            title: "Foundation",
            isbn13: "9780553293357"
        )
        book.subtitle = "The greatest science fiction series of all time"
        book.publisher = "Bantam Spectra"
        book.pageCount = 296
        book.synopsis = "For twelve thousand years the Galactic Empire has ruled supreme. Now it is dying."
        book.rating = 5
        book.readStatus = .read
        return book
    }

    static var previews: [Book] {
        [
            {
                let book = Book(title: "Foundation", isbn13: "9780553293357")
                book.rating = 5
                book.readStatus = .read
                return book
            }(),
            {
                let book = Book(title: "Dune", isbn13: "9780441172719")
                book.rating = 5
                book.readStatus = .read
                return book
            }(),
            {
                let book = Book(title: "Neuromancer", isbn13: "9780441569595")
                book.rating = 4
                book.readStatus = .reading
                return book
            }(),
            {
                let book = Book(title: "The Left Hand of Darkness", isbn13: "9780441478125")
                book.readStatus = .unread
                return book
            }()
        ]
    }
}
