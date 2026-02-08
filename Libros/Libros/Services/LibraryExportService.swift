import Foundation
import SwiftData

/// Service for exporting and importing library data as JSON
actor LibraryExportService {

    // MARK: - DTOs

    struct LibraryExport: Codable {
        let version: Int
        let exportDate: String
        let books: [BookDTO]
        let authors: [AuthorDTO]
        let genres: [GenreDTO]
        let tags: [TagDTO]
        let locations: [LocationDTO]
        let series: [SeriesDTO]
    }

    struct BookDTO: Codable {
        let id: String
        let title: String
        let subtitle: String?
        let isbn10: String?
        let isbn13: String?
        let publisher: String?
        let publishDate: String?
        let pageCount: Int?
        let synopsis: String?
        let language: String?
        let notes: String?
        let rating: Int?
        let readStatus: String
        let seriesOrder: Int?
        let dateAdded: String
        let dateModified: String
        let authorIDs: [String]
        let genreIDs: [String]
        let tagIDs: [String]
        let seriesID: String?
        let copies: [BookCopyDTO]
    }

    struct AuthorDTO: Codable {
        let id: String
        let name: String
        let biography: String?
        let openLibraryId: String?
    }

    struct GenreDTO: Codable {
        let id: String
        let name: String
        let isUserCreated: Bool
        let parentID: String?
    }

    struct TagDTO: Codable {
        let id: String
        let name: String
        let colorHex: String?
    }

    struct LocationDTO: Codable {
        let id: String
        let name: String
        let description: String?
    }

    struct SeriesDTO: Codable {
        let id: String
        let name: String
        let description: String?
        let expectedCount: Int?
    }

    struct BookCopyDTO: Codable {
        let id: String
        let format: String
        let condition: String?
        let locationID: String?
        let dateAcquired: String?
        let priceValue: String?
        let priceCurrency: String?
        let notes: String?
    }

    struct ImportResult {
        let booksImported: Int
        let authorsImported: Int
        let genresImported: Int
        let tagsImported: Int
        let locationsImported: Int
        let seriesImported: Int
        let booksSkipped: Int
    }

    enum ImportStrategy {
        case merge
        case replace
    }

    // MARK: - Export

    @MainActor
    func exportLibrary(context: ModelContext) throws -> Data {
        let iso8601 = ISO8601DateFormatter()

        // Fetch all entities
        let books = try context.fetch(FetchDescriptor<Book>())
        let authors = try context.fetch(FetchDescriptor<Author>())
        let genres = try context.fetch(FetchDescriptor<Genre>())
        let tags = try context.fetch(FetchDescriptor<Tag>())
        let locations = try context.fetch(FetchDescriptor<Location>())
        let allSeries = try context.fetch(FetchDescriptor<Series>())

        // Map to DTOs
        let authorDTOs = authors.map { author in
            AuthorDTO(
                id: author.id.uuidString,
                name: author.name,
                biography: author.biography,
                openLibraryId: author.openLibraryId
            )
        }

        let genreDTOs = genres.map { genre in
            GenreDTO(
                id: genre.id.uuidString,
                name: genre.name,
                isUserCreated: genre.isUserCreated,
                parentID: genre.parent?.id.uuidString
            )
        }

        let tagDTOs = tags.map { tag in
            TagDTO(
                id: tag.id.uuidString,
                name: tag.name,
                colorHex: tag.colorHex
            )
        }

        let locationDTOs = locations.map { location in
            LocationDTO(
                id: location.id.uuidString,
                name: location.name,
                description: location.locationDescription
            )
        }

        let seriesDTOs = allSeries.map { series in
            SeriesDTO(
                id: series.id.uuidString,
                name: series.name,
                description: series.seriesDescription,
                expectedCount: series.expectedCount
            )
        }

        let bookDTOs = books.map { book in
            let copyDTOs = book.copies.map { copy in
                BookCopyDTO(
                    id: copy.id.uuidString,
                    format: copy.format.rawValue,
                    condition: copy.condition?.rawValue,
                    locationID: copy.location?.id.uuidString,
                    dateAcquired: copy.dateAcquired.map { iso8601.string(from: $0) },
                    priceValue: copy.purchasePriceValue.map { "\($0)" },
                    priceCurrency: copy.purchasePriceCurrency,
                    notes: copy.notes
                )
            }

            return BookDTO(
                id: book.id.uuidString,
                title: book.title,
                subtitle: book.subtitle,
                isbn10: book.isbn10,
                isbn13: book.isbn13,
                publisher: book.publisher,
                publishDate: book.publishDate.map { iso8601.string(from: $0) },
                pageCount: book.pageCount,
                synopsis: book.synopsis,
                language: book.language,
                notes: book.notes,
                rating: book.rating,
                readStatus: book.readStatus.rawValue,
                seriesOrder: book.seriesOrder,
                dateAdded: iso8601.string(from: book.dateAdded),
                dateModified: iso8601.string(from: book.dateModified),
                authorIDs: book.authors.map { $0.id.uuidString },
                genreIDs: book.genres.map { $0.id.uuidString },
                tagIDs: book.tags.map { $0.id.uuidString },
                seriesID: book.series?.id.uuidString,
                copies: copyDTOs
            )
        }

        let export = LibraryExport(
            version: 1,
            exportDate: iso8601.string(from: Date()),
            books: bookDTOs,
            authors: authorDTOs,
            genres: genreDTOs,
            tags: tagDTOs,
            locations: locationDTOs,
            series: seriesDTOs
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(export)
    }

    // MARK: - Import

    @MainActor
    func importLibrary(from data: Data, context: ModelContext, strategy: ImportStrategy) throws -> ImportResult {
        let decoder = JSONDecoder()
        let export = try decoder.decode(LibraryExport.self, from: data)
        let iso8601 = ISO8601DateFormatter()

        if strategy == .replace {
            // Clear existing data
            try context.delete(model: BookCopy.self)
            try context.delete(model: Book.self)
            try context.delete(model: Author.self)
            try context.delete(model: Genre.self)
            try context.delete(model: Tag.self)
            try context.delete(model: Location.self)
            try context.delete(model: Series.self)
        }

        var authorsImported = 0
        var genresImported = 0
        var tagsImported = 0
        var locationsImported = 0
        var seriesImported = 0
        var booksImported = 0
        var booksSkipped = 0

        // ID maps for resolving relationships
        var authorMap: [String: Author] = [:]
        var genreMap: [String: Genre] = [:]
        var tagMap: [String: Tag] = [:]
        var locationMap: [String: Location] = [:]
        var seriesMap: [String: Series] = [:]

        // Import authors
        for dto in export.authors {
            if strategy == .merge {
                let existing = try context.fetch(FetchDescriptor<Author>())
                if existing.contains(where: { $0.name == dto.name }) {
                    if let match = existing.first(where: { $0.name == dto.name }) {
                        authorMap[dto.id] = match
                    }
                    continue
                }
            }
            let author = Author(name: dto.name, openLibraryId: dto.openLibraryId)
            author.biography = dto.biography
            context.insert(author)
            authorMap[dto.id] = author
            authorsImported += 1
        }

        // Import locations
        for dto in export.locations {
            if strategy == .merge {
                let existing = try context.fetch(FetchDescriptor<Location>())
                if let match = existing.first(where: { $0.name == dto.name }) {
                    locationMap[dto.id] = match
                    continue
                }
            }
            let location = Location(name: dto.name, description: dto.description)
            context.insert(location)
            locationMap[dto.id] = location
            locationsImported += 1
        }

        // Import series
        for dto in export.series {
            if strategy == .merge {
                let existing = try context.fetch(FetchDescriptor<Series>())
                if let match = existing.first(where: { $0.name == dto.name }) {
                    seriesMap[dto.id] = match
                    continue
                }
            }
            let series = Series(name: dto.name, description: dto.description, expectedCount: dto.expectedCount)
            context.insert(series)
            seriesMap[dto.id] = series
            seriesImported += 1
        }

        // Import genres (two-pass for hierarchy)
        for dto in export.genres {
            if strategy == .merge {
                let existing = try context.fetch(FetchDescriptor<Genre>())
                if let match = existing.first(where: { $0.name == dto.name }) {
                    genreMap[dto.id] = match
                    continue
                }
            }
            let genre = Genre(name: dto.name, isUserCreated: dto.isUserCreated)
            context.insert(genre)
            genreMap[dto.id] = genre
            genresImported += 1
        }

        // Second pass: set parent relationships
        for dto in export.genres {
            if let parentID = dto.parentID, let parent = genreMap[parentID], let genre = genreMap[dto.id] {
                genre.parent = parent
            }
        }

        // Import tags
        for dto in export.tags {
            if strategy == .merge {
                let existing = try context.fetch(FetchDescriptor<Tag>())
                if let match = existing.first(where: { $0.name == dto.name }) {
                    tagMap[dto.id] = match
                    continue
                }
            }
            let tag = Tag(name: dto.name, colorHex: dto.colorHex)
            context.insert(tag)
            tagMap[dto.id] = tag
            tagsImported += 1
        }

        // Import books
        for dto in export.books {
            if strategy == .merge {
                // Skip duplicates by ISBN
                if let isbn = dto.isbn13 ?? dto.isbn10 {
                    let existing = try context.fetch(FetchDescriptor<Book>())
                    if existing.contains(where: { $0.isbn13 == isbn || $0.isbn10 == isbn }) {
                        booksSkipped += 1
                        continue
                    }
                }
            }

            let book = Book(
                title: dto.title,
                subtitle: dto.subtitle,
                isbn10: dto.isbn10,
                isbn13: dto.isbn13,
                readStatus: ReadStatus(rawValue: dto.readStatus) ?? .unread
            )
            book.publisher = dto.publisher
            book.pageCount = dto.pageCount
            book.synopsis = dto.synopsis
            book.language = dto.language
            book.notes = dto.notes
            book.rating = dto.rating
            book.seriesOrder = dto.seriesOrder
            book.dateAdded = iso8601.date(from: dto.dateAdded) ?? Date()
            book.dateModified = iso8601.date(from: dto.dateModified) ?? Date()
            if let publishDateStr = dto.publishDate {
                book.publishDate = iso8601.date(from: publishDateStr)
            }

            // Relationships
            book.authors = dto.authorIDs.compactMap { authorMap[$0] }
            book.genres = dto.genreIDs.compactMap { genreMap[$0] }
            book.tags = dto.tagIDs.compactMap { tagMap[$0] }

            if let seriesID = dto.seriesID {
                book.series = seriesMap[seriesID]
            }

            context.insert(book)

            // Import copies
            for copyDTO in dto.copies {
                let copy = BookCopy(
                    format: BookFormat(rawValue: copyDTO.format) ?? .paperback,
                    condition: copyDTO.condition.flatMap { BookCondition(rawValue: $0) },
                    location: copyDTO.locationID.flatMap { locationMap[$0] },
                    dateAcquired: copyDTO.dateAcquired.flatMap { iso8601.date(from: $0) }
                )
                if let priceStr = copyDTO.priceValue, let price = Decimal(string: priceStr) {
                    copy.setPrice(price, currency: copyDTO.priceCurrency ?? "USD")
                }
                copy.notes = copyDTO.notes
                copy.book = book
                context.insert(copy)
            }

            book.updateSearchableText()
            booksImported += 1
        }

        try context.save()

        return ImportResult(
            booksImported: booksImported,
            authorsImported: authorsImported,
            genresImported: genresImported,
            tagsImported: tagsImported,
            locationsImported: locationsImported,
            seriesImported: seriesImported,
            booksSkipped: booksSkipped
        )
    }
}
