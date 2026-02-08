import Foundation

/// Represents the physical condition of a book copy
enum BookCondition: String, Codable, CaseIterable, Identifiable {
    case new = "new"
    case likeNew = "like_new"
    case good = "good"
    case fair = "fair"
    case poor = "poor"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .new: return "New"
        case .likeNew: return "Like New"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }

    var description: String {
        switch self {
        case .new: return "Unread, no signs of wear"
        case .likeNew: return "Minimal wear, like new condition"
        case .good: return "Some wear, all pages intact"
        case .fair: return "Noticeable wear, still readable"
        case .poor: return "Heavy wear, may have damage"
        }
    }
}
