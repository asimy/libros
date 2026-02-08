import Foundation
import SwiftData

/// A saved filter configuration that can be reloaded
@Model
final class SavedFilter {
    var id: UUID
    var name: String
    var dateSaved: Date

    // Stored as JSON-encoded arrays of UUID strings
    var authorIDsData: Data?
    var genreIDsData: Data?
    var tagIDsData: Data?
    var locationIDsData: Data?
    var readStatusesData: Data?
    var minimumRating: Int?

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.dateSaved = Date()
    }

    /// Creates a SavedFilter from a LibraryFilter
    static func fromFilter(_ filter: LibraryFilter, name: String) -> SavedFilter {
        let saved = SavedFilter(name: name)
        let encoder = JSONEncoder()

        saved.authorIDsData = try? encoder.encode(Array(filter.authorIDs))
        saved.genreIDsData = try? encoder.encode(Array(filter.genreIDs))
        saved.tagIDsData = try? encoder.encode(Array(filter.tagIDs))
        saved.locationIDsData = try? encoder.encode(Array(filter.locationIDs))
        saved.readStatusesData = try? encoder.encode(Array(filter.readStatuses.map(\.rawValue)))
        saved.minimumRating = filter.minimumRating

        return saved
    }

    /// Converts this SavedFilter to a LibraryFilter
    func toFilter() -> LibraryFilter {
        var filter = LibraryFilter()
        let decoder = JSONDecoder()

        if let data = authorIDsData,
           let ids = try? decoder.decode([UUID].self, from: data) {
            filter.authorIDs = Set(ids)
        }

        if let data = genreIDsData,
           let ids = try? decoder.decode([UUID].self, from: data) {
            filter.genreIDs = Set(ids)
        }

        if let data = tagIDsData,
           let ids = try? decoder.decode([UUID].self, from: data) {
            filter.tagIDs = Set(ids)
        }

        if let data = locationIDsData,
           let ids = try? decoder.decode([UUID].self, from: data) {
            filter.locationIDs = Set(ids)
        }

        if let data = readStatusesData,
           let rawValues = try? decoder.decode([String].self, from: data) {
            filter.readStatuses = Set(rawValues.compactMap { ReadStatus(rawValue: $0) })
        }

        filter.minimumRating = minimumRating

        return filter
    }
}
