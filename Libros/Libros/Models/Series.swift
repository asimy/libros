import Foundation
import SwiftData

/// Represents a book series (e.g., "Foundation", "The Lord of the Rings")
@Model
final class Series {
    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// Series name (e.g., "Foundation", "Discworld")
    @Attribute(.spotlight)
    var name: String

    /// Optional description of the series
    var seriesDescription: String?

    /// Expected total number of books in the series (nil if ongoing/unknown)
    var expectedCount: Int?

    /// Date this series was added
    var dateAdded: Date

    // MARK: - Relationships

    /// Books in this series
    @Relationship(deleteRule: .nullify, inverse: \Book.series)
    var books: [Book] = []

    // MARK: - Computed Properties

    /// Number of books from this series in the library
    var bookCount: Int {
        books.count
    }

    /// Books sorted by their order in the series
    var sortedBooks: [Book] {
        books.sorted { ($0.seriesOrder ?? Int.max) < ($1.seriesOrder ?? Int.max) }
    }

    /// Whether the library has all books in the series (if expected count is known)
    var isComplete: Bool? {
        guard let expected = expectedCount else { return nil }
        return bookCount >= expected
    }

    /// Formatted progress string (e.g., "3 of 7 books")
    var progressDescription: String {
        if let expected = expectedCount {
            return "\(bookCount) of \(expected) books"
        }
        return "\(bookCount) book\(bookCount == 1 ? "" : "s")"
    }

    // MARK: - Initialization

    init(name: String, description: String? = nil, expectedCount: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.seriesDescription = description
        self.expectedCount = expectedCount
        self.dateAdded = Date()
    }
}

// MARK: - Sample Data

extension Series {
    static var preview: Series {
        Series(name: "Foundation", description: "Isaac Asimov's classic science fiction series", expectedCount: 7)
    }

    static var previews: [Series] {
        [
            Series(name: "Foundation", description: "Isaac Asimov's classic science fiction series", expectedCount: 7),
            Series(name: "Discworld", description: "Terry Pratchett's satirical fantasy series", expectedCount: 41),
            Series(name: "The Lord of the Rings", expectedCount: 3),
            Series(name: "Dune", expectedCount: 6),
            Series(name: "Earthsea", expectedCount: 6)
        ]
    }
}
