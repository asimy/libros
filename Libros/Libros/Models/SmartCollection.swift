import SwiftUI

/// Predefined smart collections for quick access to common book groupings
enum SmartCollection: String, CaseIterable, Identifiable {
    case recentlyAdded
    case currentlyReading
    case unread
    case read
    case highestRated
    case favorites

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recentlyAdded: return "Recently Added"
        case .currentlyReading: return "Currently Reading"
        case .unread: return "Unread"
        case .read: return "Read"
        case .highestRated: return "Highest Rated"
        case .favorites: return "Favorites"
        }
    }

    var systemImage: String {
        switch self {
        case .recentlyAdded: return "clock"
        case .currentlyReading: return "book"
        case .unread: return "book.closed"
        case .read: return "checkmark.circle"
        case .highestRated: return "star.fill"
        case .favorites: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .recentlyAdded: return .blue
        case .currentlyReading: return .orange
        case .unread: return .secondary
        case .read: return .green
        case .highestRated: return .yellow
        case .favorites: return .red
        }
    }

    /// Filters books for this collection
    func matches(_ book: Book) -> Bool {
        switch self {
        case .recentlyAdded:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return book.dateAdded >= thirtyDaysAgo
        case .currentlyReading:
            return book.readStatus == .reading
        case .unread:
            return book.readStatus == .unread
        case .read:
            return book.readStatus == .read
        case .highestRated:
            return (book.rating ?? 0) >= 4
        case .favorites:
            return book.rating == 5
        }
    }
}
