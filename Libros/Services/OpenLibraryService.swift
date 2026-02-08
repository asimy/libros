import Foundation

/// Service for interacting with the Open Library API
actor OpenLibraryService {

    // MARK: - Types

    /// Metadata retrieved from Open Library
    struct BookMetadata: Sendable {
        let title: String
        let subtitle: String?
        let authors: [AuthorInfo]
        let publisher: String?
        let publishDate: String?
        let pageCount: Int?
        let synopsis: String?
        let subjects: [String]
        let isbn10: String?
        let isbn13: String?
        let coverURL: URL?
        let openLibraryWorkId: String?
        let openLibraryEditionId: String?

        struct AuthorInfo: Sendable {
            let name: String
            let openLibraryId: String?
        }
    }

    /// Search result from Open Library
    struct SearchResult: Sendable {
        let title: String
        let authors: [String]
        let firstPublishYear: Int?
        let isbn: [String]
        let openLibraryWorkId: String?
        let coverEditionKey: String?

        var coverURL: URL? {
            guard let key = coverEditionKey else { return nil }
            return URL(string: "https://covers.openlibrary.org/b/olid/\(key)-M.jpg")
        }
    }

    // MARK: - Errors

    enum ServiceError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case notFound
        case invalidResponse
        case decodingError(Error)
        case rateLimited

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL configuration"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .notFound:
                return "Book not found in Open Library"
            case .invalidResponse:
                return "Invalid response from Open Library"
            case .decodingError(let error):
                return "Failed to parse response: \(error.localizedDescription)"
            case .rateLimited:
                return "Too many requests. Please wait a moment and try again."
            }
        }
    }

    // MARK: - Properties

    private let session: URLSession
    private let baseURL = "https://openlibrary.org"
    private let coversURL = "https://covers.openlibrary.org"

    // Simple rate limiting
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 0.1  // 100ms between requests

    // MARK: - Initialization

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API

    /// Looks up a book by ISBN
    /// - Parameter isbn: The ISBN-10 or ISBN-13
    /// - Returns: Book metadata from Open Library
    func lookupByISBN(_ isbn: String) async throws -> BookMetadata {
        await respectRateLimit()

        let normalizedISBN = isbn.replacingOccurrences(of: "-", with: "")
                                  .replacingOccurrences(of: " ", with: "")

        guard let url = URL(string: "\(baseURL)/isbn/\(normalizedISBN).json") else {
            throw ServiceError.invalidURL
        }

        let editionData = try await fetchJSON(from: url)

        // Parse the edition response
        return try await parseEditionResponse(editionData, isbn: normalizedISBN)
    }

    /// Searches for books by query
    /// - Parameters:
    ///   - query: Search query (title, author, or combined)
    ///   - limit: Maximum number of results
    /// - Returns: Array of search results
    func search(query: String, limit: Int = 20) async throws -> [SearchResult] {
        await respectRateLimit()

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/search.json?q=\(encodedQuery)&limit=\(limit)") else {
            throw ServiceError.invalidURL
        }

        let data = try await fetchJSON(from: url)
        return try parseSearchResponse(data)
    }

    /// Searches for books by title
    /// - Parameters:
    ///   - title: Book title to search for
    ///   - limit: Maximum number of results
    func searchByTitle(_ title: String, limit: Int = 20) async throws -> [SearchResult] {
        await respectRateLimit()

        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        guard let url = URL(string: "\(baseURL)/search.json?title=\(encodedTitle)&limit=\(limit)") else {
            throw ServiceError.invalidURL
        }

        let data = try await fetchJSON(from: url)
        return try parseSearchResponse(data)
    }

    /// Searches for books by author
    /// - Parameters:
    ///   - author: Author name to search for
    ///   - limit: Maximum number of results
    func searchByAuthor(_ author: String, limit: Int = 20) async throws -> [SearchResult] {
        await respectRateLimit()

        let encodedAuthor = author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? author
        guard let url = URL(string: "\(baseURL)/search.json?author=\(encodedAuthor)&limit=\(limit)") else {
            throw ServiceError.invalidURL
        }

        let data = try await fetchJSON(from: url)
        return try parseSearchResponse(data)
    }

    /// Gets the cover image URL for an ISBN
    /// - Parameters:
    ///   - isbn: The ISBN
    ///   - size: Size of the cover (S, M, or L)
    /// - Returns: URL to the cover image
    func coverURL(for isbn: String, size: CoverSize = .large) -> URL? {
        let normalizedISBN = isbn.replacingOccurrences(of: "-", with: "")
                                  .replacingOccurrences(of: " ", with: "")
        return URL(string: "\(coversURL)/b/isbn/\(normalizedISBN)-\(size.rawValue).jpg")
    }

    enum CoverSize: String {
        case small = "S"
        case medium = "M"
        case large = "L"
    }

    // MARK: - Private Methods

    private func respectRateLimit() async {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumRequestInterval {
                try? await Task.sleep(nanoseconds: UInt64((minimumRequestInterval - elapsed) * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }

    private func fetchJSON(from url: URL) async throws -> [String: Any] {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 404:
            throw ServiceError.notFound
        case 429:
            throw ServiceError.rateLimited
        default:
            throw ServiceError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ServiceError.invalidResponse
        }

        return json
    }

    private func parseEditionResponse(_ json: [String: Any], isbn: String) async throws -> BookMetadata {
        guard let title = json["title"] as? String else {
            throw ServiceError.invalidResponse
        }

        let subtitle = json["subtitle"] as? String

        // Parse authors (may need additional API calls)
        var authors: [BookMetadata.AuthorInfo] = []
        if let authorRefs = json["authors"] as? [[String: Any]] {
            for ref in authorRefs {
                if let key = ref["key"] as? String {
                    if let authorInfo = try? await fetchAuthor(key: key) {
                        authors.append(authorInfo)
                    }
                }
            }
        }

        // Parse other fields
        let publishers = json["publishers"] as? [String]
        let publisher = publishers?.first

        let publishDate = json["publish_date"] as? String
        let pageCount = json["number_of_pages"] as? Int

        // Description can be a string or an object with "value" key
        var synopsis: String?
        if let desc = json["description"] as? String {
            synopsis = desc
        } else if let descObj = json["description"] as? [String: Any],
                  let value = descObj["value"] as? String {
            synopsis = value
        }

        let subjects = json["subjects"] as? [String] ?? []

        // ISBNs
        let isbn10s = json["isbn_10"] as? [String]
        let isbn13s = json["isbn_13"] as? [String]

        // Determine which ISBN we have
        let isbn10 = isbn10s?.first ?? (isbn.count == 10 ? isbn : nil)
        let isbn13 = isbn13s?.first ?? (isbn.count == 13 ? isbn : nil)

        // Cover URL
        let coverURL = self.coverURL(for: isbn)

        // Open Library IDs
        let editionKey = json["key"] as? String
        let workRefs = json["works"] as? [[String: Any]]
        let workKey = workRefs?.first?["key"] as? String

        return BookMetadata(
            title: title,
            subtitle: subtitle,
            authors: authors,
            publisher: publisher,
            publishDate: publishDate,
            pageCount: pageCount,
            synopsis: synopsis,
            subjects: subjects,
            isbn10: isbn10,
            isbn13: isbn13,
            coverURL: coverURL,
            openLibraryWorkId: workKey?.replacingOccurrences(of: "/works/", with: ""),
            openLibraryEditionId: editionKey?.replacingOccurrences(of: "/books/", with: "")
        )
    }

    private func fetchAuthor(key: String) async throws -> BookMetadata.AuthorInfo {
        await respectRateLimit()

        guard let url = URL(string: "\(baseURL)\(key).json") else {
            throw ServiceError.invalidURL
        }

        let json = try await fetchJSON(from: url)

        guard let name = json["name"] as? String else {
            throw ServiceError.invalidResponse
        }

        let authorId = key.replacingOccurrences(of: "/authors/", with: "")

        return BookMetadata.AuthorInfo(name: name, openLibraryId: authorId)
    }

    private func parseSearchResponse(_ json: [String: Any]) throws -> [SearchResult] {
        guard let docs = json["docs"] as? [[String: Any]] else {
            return []
        }

        return docs.compactMap { doc -> SearchResult? in
            guard let title = doc["title"] as? String else { return nil }

            let authors = doc["author_name"] as? [String] ?? []
            let firstPublishYear = doc["first_publish_year"] as? Int
            let isbns = doc["isbn"] as? [String] ?? []
            let workKey = doc["key"] as? String
            let coverEditionKey = doc["cover_edition_key"] as? String

            return SearchResult(
                title: title,
                authors: authors,
                firstPublishYear: firstPublishYear,
                isbn: isbns,
                openLibraryWorkId: workKey?.replacingOccurrences(of: "/works/", with: ""),
                coverEditionKey: coverEditionKey
            )
        }
    }
}

// MARK: - Protocol for Testability

protocol BookLookupService: Sendable {
    func lookupByISBN(_ isbn: String) async throws -> OpenLibraryService.BookMetadata
    func search(query: String, limit: Int) async throws -> [OpenLibraryService.SearchResult]
}

extension OpenLibraryService: BookLookupService {}
