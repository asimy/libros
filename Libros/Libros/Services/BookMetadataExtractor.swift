import Foundation

/// Metadata extracted from OCR text of physical book pages
struct ExtractedMetadata {
    var title: String?
    var subtitle: String?
    var authors: [String]
    var publisher: String?
    var publishYear: Int?
    var isbn: String?
    var synopsis: String?

    static var empty: ExtractedMetadata {
        ExtractedMetadata(authors: [])
    }

    /// Merges with another result, preferring non-nil values from `other`
    func merging(with other: ExtractedMetadata) -> ExtractedMetadata {
        ExtractedMetadata(
            title: other.title ?? title,
            subtitle: other.subtitle ?? subtitle,
            authors: other.authors.isEmpty ? authors : other.authors,
            publisher: other.publisher ?? publisher,
            publishYear: other.publishYear ?? publishYear,
            isbn: other.isbn ?? isbn,
            synopsis: other.synopsis ?? synopsis
        )
    }
}

/// Pure logic service for extracting book metadata from OCR text
enum BookMetadataExtractor {

    // MARK: - Public API

    /// Extract title and authors from title page text
    static func extractFromTitlePage(_ text: String) -> ExtractedMetadata {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var result = ExtractedMetadata.empty

        // Filter noise lines
        let noisePatterns = ["a novel", "fiction", "nonfiction", "non-fiction",
                             "a memoir", "a thriller", "a mystery", "a romance"]
        let substantialLines = lines.filter { line in
            let lower = line.lowercased()
            return !noisePatterns.contains(where: { lower == $0 })
        }

        guard !substantialLines.isEmpty else { return result }

        // Find "by" keyword to split title from authors
        var titleLines: [String] = []
        var authorLines: [String] = []
        var foundBy = false

        for line in substantialLines {
            let lower = line.lowercased().trimmingCharacters(in: .whitespaces)
            if lower == "by" || lower.hasPrefix("by ") {
                foundBy = true
                let afterBy = String(line.dropFirst(lower.hasPrefix("by ") ? 3 : 2))
                    .trimmingCharacters(in: .whitespaces)
                if !afterBy.isEmpty {
                    authorLines.append(afterBy)
                }
            } else if foundBy {
                authorLines.append(line)
            } else {
                titleLines.append(line)
            }
        }

        // Title: first substantial line
        if let firstTitle = titleLines.first {
            if firstTitle.contains(":") {
                let parts = firstTitle.components(separatedBy: ":")
                result.title = parts[0].trimmingCharacters(in: .whitespaces)
                if parts.count > 1 {
                    let sub = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    if !sub.isEmpty {
                        result.subtitle = sub
                    }
                }
            } else {
                result.title = firstTitle
            }
        }

        // Authors
        if !authorLines.isEmpty {
            result.authors = parseAuthorNames(authorLines.joined(separator: " "))
        } else if !foundBy {
            // No "by" found — look for proper name lines (2+ capitalized words)
            for line in substantialLines.dropFirst() {
                if looksLikeAuthorName(line) {
                    result.authors = parseAuthorNames(line)
                    break
                }
            }
        }

        return result
    }

    /// Extract publisher, date, ISBN from copyright page text
    static func extractFromCopyrightPage(_ text: String) -> ExtractedMetadata {
        var result = ExtractedMetadata.empty

        // ISBN: delegate to ISBNParser
        if let isbn = ISBNParser.extractISBN(from: text) {
            result.isbn = isbn.isbn13
        }

        // Publisher patterns
        let publisherPatterns = [
            #"[Pp]ublished\s+by\s+(.+?)(?:\.|,|$)"#,
            #"(.+?)\s+Press(?:\s|,|\.|$)"#,
            #"(.+?)\s+Publishing(?:\s|,|\.|$)"#,
            #"(.+?)\s+Books(?:\s|,|\.|$)"#
        ]

        for pattern in publisherPatterns {
            if let match = firstCaptureGroup(pattern: pattern, in: text) {
                let trimmed = match.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty && trimmed.count < 80 {
                    result.publisher = trimmed
                    break
                }
            }
        }

        // Year patterns
        let yearPatterns = [
            #"(?:[Cc]opyright|©)\s*(?:\([Cc]\))?\s*(\d{4})"#,
            #"[Ff]irst\s+(?:published|edition)\s*(?:in)?\s*(\d{4})"#
        ]

        for pattern in yearPatterns {
            if let match = firstCaptureGroup(pattern: pattern, in: text),
               let year = Int(match), year >= 1400 && year <= 2100 {
                result.publishYear = year
                break
            }
        }

        // Fallback: first plausible year
        if result.publishYear == nil {
            let fallbackPattern = #"((?:19|20)\d{2})"#
            if let match = firstCaptureGroup(pattern: fallbackPattern, in: text),
               let year = Int(match), year >= 1900 && year <= 2100 {
                result.publishYear = year
            }
        }

        return result
    }

    /// Extract synopsis from back cover text
    static func extractFromBackCover(_ text: String) -> ExtractedMetadata {
        var result = ExtractedMetadata.empty

        let paragraphs = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let proseParas = paragraphs.filter { para in
            // Skip review quotes
            if para.hasPrefix("\"") || para.hasPrefix("\u{201C}") { return false }
            // Skip "About the Author" sections
            if para.lowercased().hasPrefix("about the author") { return false }
            // Skip price patterns
            if para.range(of: #"\$\d+\.\d{2}"#, options: .regularExpression) != nil { return false }
            // Skip ISBN lines
            if para.range(of: #"ISBN"#, options: .caseInsensitive) != nil { return false }
            // Skip very short lines
            if para.count < 20 { return false }
            return true
        }

        if !proseParas.isEmpty {
            result.synopsis = proseParas.joined(separator: "\n\n")
        }

        return result
    }

    // MARK: - Private Helpers

    /// Checks if a line looks like an author name (2+ capitalized words)
    private static func looksLikeAuthorName(_ text: String) -> Bool {
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard words.count >= 2 else { return false }
        let capitalizedWords = words.filter { word in
            guard let first = word.first else { return false }
            return first.isUppercase
        }
        return capitalizedWords.count >= 2
    }

    /// Parses author names from a string, splitting on " and ", " & ", ", "
    private static func parseAuthorNames(_ text: String) -> [String] {
        // First split on " and " or " & "
        var parts = text.components(separatedBy: " and ")
            .flatMap { $0.components(separatedBy: " & ") }

        // Then split on commas (but only if we don't already have multiple authors)
        if parts.count == 1 {
            parts = parts[0].components(separatedBy: ",")
        }

        return parts
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Returns the first capture group from a regex match
    private static func firstCaptureGroup(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[captureRange])
    }
}
