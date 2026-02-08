import Foundation

/// Observable filter state for the library view
@Observable
class LibraryFilter {
    var authorIDs: Set<UUID> = []
    var genreIDs: Set<UUID> = []
    var tagIDs: Set<UUID> = []
    var locationIDs: Set<UUID> = []
    var readStatuses: Set<ReadStatus> = []
    var minimumRating: Int?

    /// Whether any filter is currently active
    var isActive: Bool {
        !authorIDs.isEmpty ||
        !genreIDs.isEmpty ||
        !tagIDs.isEmpty ||
        !locationIDs.isEmpty ||
        !readStatuses.isEmpty ||
        minimumRating != nil
    }

    /// Number of active filter dimensions
    var activeCount: Int {
        var count = 0
        if !authorIDs.isEmpty { count += 1 }
        if !genreIDs.isEmpty { count += 1 }
        if !tagIDs.isEmpty { count += 1 }
        if !locationIDs.isEmpty { count += 1 }
        if !readStatuses.isEmpty { count += 1 }
        if minimumRating != nil { count += 1 }
        return count
    }

    /// Resets all filters
    func reset() {
        authorIDs = []
        genreIDs = []
        tagIDs = []
        locationIDs = []
        readStatuses = []
        minimumRating = nil
    }

    /// Returns whether a book matches all active filters
    func matches(_ book: Book) -> Bool {
        if !authorIDs.isEmpty {
            guard book.authors.contains(where: { authorIDs.contains($0.id) }) else { return false }
        }

        if !genreIDs.isEmpty {
            guard book.genres.contains(where: { genreIDs.contains($0.id) }) else { return false }
        }

        if !tagIDs.isEmpty {
            guard book.tags.contains(where: { tagIDs.contains($0.id) }) else { return false }
        }

        if !locationIDs.isEmpty {
            guard book.copies.contains(where: { copy in
                if let location = copy.location {
                    return locationIDs.contains(location.id)
                }
                return false
            }) else { return false }
        }

        if !readStatuses.isEmpty {
            guard readStatuses.contains(book.readStatus) else { return false }
        }

        if let minRating = minimumRating {
            guard (book.rating ?? 0) >= minRating else { return false }
        }

        return true
    }
}
