import Foundation
import SwiftData

/// Processes the PendingLookup queue and creates Books from successful lookups
actor OfflineLookupService {
    static let maxRetries = 3

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Processes all pending lookups
    func processPendingLookups() async {
        let context = ModelContext(modelContainer)

        let pending = LookupStatus.pending
        let descriptor = FetchDescriptor<PendingLookup>(
            predicate: #Predicate<PendingLookup> { $0.status == pending },
            sortBy: [SortDescriptor(\.dateQueued)]
        )

        guard let lookups = try? context.fetch(descriptor) else { return }

        for lookup in lookups {
            lookup.status = .inProgress
            try? context.save()

            await processLookup(lookup, context: context)
        }
    }

    // MARK: - Private

    private func processLookup(_ lookup: PendingLookup, context: ModelContext) async {
        do {
            let service = OpenLibraryService()
            let metadata = try await service.lookupByISBN(lookup.isbn)

            // Fetch existing authors for deduplication
            let existingAuthors = (try? context.fetch(FetchDescriptor<Author>())) ?? []

            let book = Book(title: metadata.title, metadataSource: .openLibrary)
            book.subtitle = metadata.subtitle
            book.isbn13 = metadata.isbn13
            book.isbn10 = metadata.isbn10
            book.publisher = metadata.publisher
            book.pageCount = metadata.pageCount
            book.synopsis = metadata.synopsis
            book.coverURL = metadata.coverURL
            book.openLibraryWorkId = metadata.openLibraryWorkId
            book.openLibraryEditionId = metadata.openLibraryEditionId

            // Parse publish date
            if let dateStr = metadata.publishDate {
                let pattern = #"\b(1[0-9]{3}|20[0-9]{2})\b"#
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: dateStr, range: NSRange(dateStr.startIndex..., in: dateStr)),
                   let range = Range(match.range, in: dateStr),
                   let year = Int(String(dateStr[range])) {
                    var components = DateComponents()
                    components.year = year
                    components.month = 1
                    components.day = 1
                    book.publishDate = Calendar.current.date(from: components)
                }
            }

            // Handle authors
            var authors: [Author] = []
            for authorInfo in metadata.authors {
                if let existing = existingAuthors.first(where: { $0.name == authorInfo.name }) {
                    authors.append(existing)
                } else {
                    let newAuthor = Author(
                        name: authorInfo.name,
                        openLibraryId: authorInfo.openLibraryId
                    )
                    context.insert(newAuthor)
                    authors.append(newAuthor)
                }
            }
            book.authors = authors

            book.updateSearchableText()
            context.insert(book)

            lookup.status = .completed
            try context.save()

        } catch let error as OpenLibraryService.ServiceError where error == .notFound {
            lookup.status = .notFound
            lookup.lastError = "Book not found in Open Library"
            try? context.save()

        } catch {
            lookup.retryCount += 1
            lookup.lastError = error.localizedDescription

            if lookup.retryCount >= Self.maxRetries {
                lookup.status = .failed
            } else {
                lookup.status = .pending
            }
            try? context.save()
        }
    }
}
