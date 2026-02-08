import Foundation

/// Represents the reading status of a book
enum ReadStatus: String, Codable, CaseIterable, Identifiable {
    case unread = "unread"
    case reading = "reading"
    case read = "read"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unread: return "Unread"
        case .reading: return "Reading"
        case .read: return "Read"
        }
    }

    var systemImage: String {
        switch self {
        case .unread: return "book.closed"
        case .reading: return "book"
        case .read: return "checkmark.circle"
        }
    }
}
