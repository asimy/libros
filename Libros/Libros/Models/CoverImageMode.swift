import Foundation

/// Controls how cover images are handled for offline and sync
enum CoverImageMode: String, CaseIterable, Identifiable {
    /// Cover data is stored in SwiftData and syncs via CloudKit (default)
    case syncWithCloudKit = "sync"

    /// Covers are downloaded to a local cache but not synced via CloudKit
    case downloadOnly = "download"

    /// No cover images are downloaded; placeholder images are shown
    case placeholderOnly = "placeholder"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .syncWithCloudKit: return "Sync via iCloud"
        case .downloadOnly: return "Download Only"
        case .placeholderOnly: return "Placeholders Only"
        }
    }

    var description: String {
        switch self {
        case .syncWithCloudKit:
            return "Covers are stored and synced across devices via iCloud."
        case .downloadOnly:
            return "Covers are downloaded when online but not synced to other devices."
        case .placeholderOnly:
            return "No covers are downloaded. Saves bandwidth and storage."
        }
    }

    var systemImage: String {
        switch self {
        case .syncWithCloudKit: return "icloud.and.arrow.down"
        case .downloadOnly: return "arrow.down.circle"
        case .placeholderOnly: return "photo"
        }
    }
}
