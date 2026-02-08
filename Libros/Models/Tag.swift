import Foundation
import SwiftData

/// A user-defined tag for organizing and categorizing books
@Model
final class Tag {
    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// Tag name (e.g., "favorites", "to-donate", "gift")
    @Attribute(.spotlight)
    var name: String

    /// Optional color for visual distinction (stored as hex string)
    var colorHex: String?

    /// Date this tag was created
    var dateCreated: Date

    // MARK: - Relationships

    /// Books with this tag
    @Relationship(deleteRule: .nullify, inverse: \Book.tags)
    var books: [Book] = []

    // MARK: - Computed Properties

    /// Number of books with this tag
    var bookCount: Int {
        books.count
    }

    // MARK: - Initialization

    init(name: String, colorHex: String? = nil) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.dateCreated = Date()
    }
}

// MARK: - Sample Data

extension Tag {
    static var preview: Tag {
        Tag(name: "Favorites", colorHex: "#FF6B6B")
    }

    static var previews: [Tag] {
        [
            Tag(name: "Favorites", colorHex: "#FF6B6B"),
            Tag(name: "To Read Next", colorHex: "#4ECDC4"),
            Tag(name: "Book Club", colorHex: "#45B7D1"),
            Tag(name: "Reference", colorHex: "#96CEB4"),
            Tag(name: "Signed Copy", colorHex: "#FFEAA7")
        ]
    }
}
