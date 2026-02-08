import Foundation
import SwiftData

/// Represents a genre or category for books, with optional hierarchy
@Model
final class Genre {
    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// Genre name (e.g., "Science Fiction", "Space Opera")
    @Attribute(.spotlight)
    var name: String

    /// Whether this genre was imported from an API or user-created
    var isUserCreated: Bool

    /// Date this genre was created
    var dateCreated: Date

    // MARK: - Relationships

    /// Parent genre for hierarchical organization (e.g., "Space Opera" → "Science Fiction")
    var parent: Genre?

    /// Child genres
    @Relationship(deleteRule: .nullify, inverse: \Genre.parent)
    var children: [Genre] = []

    /// Books in this genre
    @Relationship(deleteRule: .nullify, inverse: \Book.genres)
    var books: [Book] = []

    // MARK: - Computed Properties

    /// Number of books in this genre (not including child genres)
    var directBookCount: Int {
        books.count
    }

    /// Total books including all child genres
    var totalBookCount: Int {
        books.count + children.reduce(0) { $0 + $1.totalBookCount }
    }

    /// Full path from root to this genre (e.g., "Fiction > Science Fiction > Space Opera")
    var fullPath: String {
        if let parent = parent {
            return "\(parent.fullPath) > \(name)"
        }
        return name
    }

    /// Depth in the hierarchy (0 for root genres)
    var depth: Int {
        if let parent = parent {
            return parent.depth + 1
        }
        return 0
    }

    /// Whether this is a root-level genre (no parent)
    var isRoot: Bool {
        parent == nil
    }

    // MARK: - Initialization

    init(name: String, parent: Genre? = nil, isUserCreated: Bool = true) {
        self.id = UUID()
        self.name = name
        self.parent = parent
        self.isUserCreated = isUserCreated
        self.dateCreated = Date()
    }
}

// MARK: - Sample Data

extension Genre {
    static var preview: Genre {
        Genre(name: "Science Fiction")
    }

    static func createPreviewHierarchy() -> [Genre] {
        let fiction = Genre(name: "Fiction", isUserCreated: false)
        let nonFiction = Genre(name: "Non-Fiction", isUserCreated: false)

        let sciFi = Genre(name: "Science Fiction", parent: fiction, isUserCreated: false)
        let fantasy = Genre(name: "Fantasy", parent: fiction, isUserCreated: false)
        let mystery = Genre(name: "Mystery", parent: fiction, isUserCreated: false)

        let spaceOpera = Genre(name: "Space Opera", parent: sciFi, isUserCreated: false)
        let cyberpunk = Genre(name: "Cyberpunk", parent: sciFi, isUserCreated: false)

        let history = Genre(name: "History", parent: nonFiction, isUserCreated: false)
        let science = Genre(name: "Science", parent: nonFiction, isUserCreated: false)
        let biography = Genre(name: "Biography", parent: nonFiction, isUserCreated: false)

        return [fiction, nonFiction, sciFi, fantasy, mystery, spaceOpera, cyberpunk, history, science, biography]
    }
}
