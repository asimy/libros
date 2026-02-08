import Foundation
import SwiftData

/// Downloads and persists cover images to book.coverData
actor CoverCacheService {
    private let modelContainer: ModelContainer

    /// Minimum valid cover size — Open Library returns tiny 1x1 GIF for missing covers
    private let minimumCoverSize = 1000

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Downloads covers for all books with a coverURL but no coverData.
    /// Respects the user's cover image mode setting.
    func cacheUncachedCovers() async {
        let mode = CoverImageMode(rawValue: UserDefaults.standard.string(forKey: "coverImageMode") ?? "") ?? .syncWithCloudKit
        guard mode != .placeholderOnly else { return }

        let context = ModelContext(modelContainer)

        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.coverURL != nil && $0.coverData == nil }
        )

        guard let books = try? context.fetch(descriptor) else { return }

        for book in books {
            await cacheCover(for: book, context: context)
        }
    }

    /// Downloads cover for a single book by ID
    func cacheCover(for bookID: UUID) async {
        let context = ModelContext(modelContainer)

        var descriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.id == bookID }
        )
        descriptor.fetchLimit = 1

        guard let book = try? context.fetch(descriptor).first else { return }
        await cacheCover(for: book, context: context)
    }

    // MARK: - Private

    private func cacheCover(for book: Book, context: ModelContext) async {
        guard let url = book.coverURL ?? book.openLibraryCoverURL else { return }
        guard book.coverData == nil else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  data.count > minimumCoverSize else {
                return
            }

            book.coverData = data
            try context.save()
        } catch {
            // Individual failures don't block other downloads
        }
    }
}
