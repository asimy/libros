import Foundation
import SwiftData

/// Represents a queued ISBN lookup that will be processed when online
@Model
final class PendingLookup {
    var id: UUID
    var isbn: String
    var dateQueued: Date
    var status: LookupStatus
    var retryCount: Int
    var lastError: String?
    var source: MetadataSource

    init(isbn: String, source: MetadataSource = .openLibrary) {
        self.id = UUID()
        self.isbn = isbn
        self.dateQueued = Date()
        self.status = .pending
        self.retryCount = 0
        self.lastError = nil
        self.source = source
    }
}
