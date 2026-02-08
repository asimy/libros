import Foundation
import SwiftData

/// Represents a physical location where books are stored
@Model
final class Location {
    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// Name of the location (e.g., "Living Room Bookshelf", "Office", "Storage Box 1")
    @Attribute(.spotlight)
    var name: String

    /// Optional description or notes about this location
    var locationDescription: String?

    /// Date this location was created
    var dateCreated: Date

    // MARK: - Relationships

    /// Book copies stored at this location
    @Relationship(deleteRule: .nullify, inverse: \BookCopy.location)
    var bookCopies: [BookCopy] = []

    // MARK: - Computed Properties

    /// Number of book copies at this location
    var copyCount: Int {
        bookCopies.count
    }

    // MARK: - Initialization

    init(name: String, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.locationDescription = description
        self.dateCreated = Date()
    }
}

// MARK: - Sample Data

extension Location {
    static var preview: Location {
        Location(name: "Living Room Bookshelf", description: "Main bookshelf in the living room")
    }

    static var previews: [Location] {
        [
            Location(name: "Living Room Bookshelf", description: "Main bookshelf in the living room"),
            Location(name: "Office", description: "Home office shelves"),
            Location(name: "Bedroom Nightstand"),
            Location(name: "Storage Box 1", description: "In the garage")
        ]
    }
}
