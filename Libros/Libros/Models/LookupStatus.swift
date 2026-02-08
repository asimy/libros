import Foundation

/// Represents the status of a pending ISBN lookup
enum LookupStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "pending"
    case inProgress = "inProgress"
    case completed = "completed"
    case failed = "failed"
    case notFound = "notFound"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: return "Queued"
        case .inProgress: return "Looking Up..."
        case .completed: return "Complete"
        case .failed: return "Failed"
        case .notFound: return "Not Found"
        }
    }

    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        case .notFound: return "questionmark.circle"
        }
    }
}
