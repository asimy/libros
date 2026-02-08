import Foundation
import SwiftData

/// Represents an author of one or more books
@Model
final class Author {
    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// Author's display name (e.g., "Isaac Asimov", "J.R.R. Tolkien")
    @Attribute(.spotlight)
    var name: String

    /// Name used for sorting (e.g., "Asimov, Isaac", "Tolkien, J.R.R.")
    var sortName: String

    /// Open Library author ID for linking to external data
    var openLibraryId: String?

    /// Brief biography or notes about the author
    var biography: String?

    /// Date this author was added to the database
    var dateAdded: Date

    // MARK: - Relationships

    /// Books written by this author
    @Relationship(deleteRule: .nullify, inverse: \Book.authors)
    var books: [Book] = []

    // MARK: - Computed Properties

    /// Number of books by this author in the library
    var bookCount: Int {
        books.count
    }

    /// First letter of sort name for section indexing
    var sortLetter: String {
        String(sortName.prefix(1)).uppercased()
    }

    // MARK: - Initialization

    init(name: String, sortName: String? = nil, openLibraryId: String? = nil) {
        self.id = UUID()
        self.name = name
        self.sortName = sortName ?? Author.generateSortName(from: name)
        self.openLibraryId = openLibraryId
        self.dateAdded = Date()
    }

    // MARK: - Helper Methods

    /// Generates a sort name from a display name
    /// e.g., "Isaac Asimov" → "Asimov, Isaac"
    static func generateSortName(from name: String) -> String {
        let components = name.split(separator: " ").map(String.init)

        guard components.count > 1 else {
            return name
        }

        let lastName = components.last!
        let firstNames = components.dropLast().joined(separator: " ")

        return "\(lastName), \(firstNames)"
    }
}

// MARK: - Sample Data

extension Author {
    static var preview: Author {
        Author(name: "Isaac Asimov", openLibraryId: "OL34221A")
    }

    static var previews: [Author] {
        [
            Author(name: "Isaac Asimov", openLibraryId: "OL34221A"),
            Author(name: "J.R.R. Tolkien", openLibraryId: "OL26320A"),
            Author(name: "Ursula K. Le Guin", openLibraryId: "OL24529A"),
            Author(name: "Frank Herbert", openLibraryId: "OL20187A"),
            Author(name: "Terry Pratchett", openLibraryId: "OL25712A")
        ]
    }
}
