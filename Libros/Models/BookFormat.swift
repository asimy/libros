import Foundation

/// Represents the physical format of a book copy
enum BookFormat: String, Codable, CaseIterable, Identifiable {
    case hardcover = "hardcover"
    case paperback = "paperback"
    case massMarketPaperback = "mass_market_paperback"
    case ebook = "ebook"
    case audiobook = "audiobook"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hardcover: return "Hardcover"
        case .paperback: return "Paperback"
        case .massMarketPaperback: return "Mass Market Paperback"
        case .ebook: return "eBook"
        case .audiobook: return "Audiobook"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .hardcover: return "book.closed.fill"
        case .paperback: return "book.closed"
        case .massMarketPaperback: return "book.closed"
        case .ebook: return "ipad"
        case .audiobook: return "headphones"
        case .other: return "questionmark.square"
        }
    }
}
