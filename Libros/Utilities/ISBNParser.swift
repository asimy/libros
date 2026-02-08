import Foundation

/// Extracts ISBN numbers from text (e.g., OCR output)
enum ISBNParser {

    // MARK: - Public API

    /// Extracts an ISBN from text, such as OCR output from a book
    /// - Parameter text: The text to search for an ISBN
    /// - Returns: A validated ISBN, or `nil` if none found
    static func extractISBN(from text: String) -> ISBN? {
        // Try explicit ISBN patterns first (most reliable)
        if let isbn = extractExplicitISBN(from: text) {
            return isbn
        }

        // Fall back to finding any valid ISBN-like number
        return extractImplicitISBN(from: text)
    }

    /// Extracts all ISBNs from text
    /// - Parameter text: The text to search
    /// - Returns: Array of validated ISBNs found
    static func extractAllISBNs(from text: String) -> [ISBN] {
        var results: [ISBN] = []

        // Find all potential ISBN patterns
        let candidates = findAllCandidates(in: text)

        for candidate in candidates {
            if let isbn = ISBNValidator.parse(candidate) {
                // Avoid duplicates (same ISBN-13)
                if !results.contains(where: { $0.isbn13 == isbn.isbn13 }) {
                    results.append(isbn)
                }
            }
        }

        return results
    }

    /// Attempts to correct common OCR errors in an ISBN string
    /// - Parameter text: The potentially corrupted ISBN string
    /// - Returns: A validated ISBN if correction succeeds, `nil` otherwise
    static func correctOCRErrors(_ text: String) -> ISBN? {
        let corrected = applyOCRCorrections(text)

        // Try the corrected version
        if let isbn = ISBNValidator.parse(corrected) {
            return isbn
        }

        // Try variations with common substitutions
        for variation in generateOCRVariations(corrected) {
            if let isbn = ISBNValidator.parse(variation) {
                return isbn
            }
        }

        return nil
    }

    // MARK: - Private Extraction Methods

    /// Extracts ISBN from explicit patterns like "ISBN: 978-0-306-40615-7"
    private static func extractExplicitISBN(from text: String) -> ISBN? {
        // Pattern matches:
        // - "ISBN" followed by optional "-10" or "-13"
        // - Optional colon and/or spaces
        // - The ISBN number with optional hyphens/spaces

        let patterns = [
            // ISBN-13: 978-0-306-40615-7
            #"ISBN[- ]?13[:\s]*([0-9][0-9\- ]{11,17}[0-9])"#,
            // ISBN-10: 0-306-40615-2
            #"ISBN[- ]?10[:\s]*([0-9][0-9\- X]{8,13}[0-9X])"#,
            // ISBN: 978-0-306-40615-7 or ISBN 0306406152
            #"ISBN[:\s]+([0-9][0-9\- X]{8,17}[0-9X])"#,
            // Just "ISBN" followed by number
            #"ISBN([0-9][0-9\- X]{8,17}[0-9X])"#
        ]

        for pattern in patterns {
            if let match = firstMatch(pattern: pattern, in: text) {
                let candidate = match.replacingOccurrences(of: " ", with: "")
                                     .replacingOccurrences(of: "-", with: "")
                if let isbn = ISBNValidator.parse(candidate) {
                    return isbn
                }
                // Try OCR correction
                if let isbn = correctOCRErrors(candidate) {
                    return isbn
                }
            }
        }

        return nil
    }

    /// Extracts ISBN from bare numbers that look like ISBNs
    private static func extractImplicitISBN(from text: String) -> ISBN? {
        let candidates = findAllCandidates(in: text)

        for candidate in candidates {
            if let isbn = ISBNValidator.parse(candidate) {
                return isbn
            }
            // Try OCR correction
            if let isbn = correctOCRErrors(candidate) {
                return isbn
            }
        }

        return nil
    }

    /// Finds all potential ISBN candidates in text
    private static func findAllCandidates(in text: String) -> [String] {
        var candidates: [String] = []

        // Pattern for ISBN-13 like sequences (13 digits with optional separators)
        let isbn13Pattern = #"97[89][0-9\- ]{10,14}[0-9]"#

        // Pattern for ISBN-10 like sequences (10 chars, last can be X)
        let isbn10Pattern = #"[0-9][0-9\- ]{8,12}[0-9X]"#

        // Find ISBN-13 candidates
        candidates.append(contentsOf: allMatches(pattern: isbn13Pattern, in: text))

        // Find ISBN-10 candidates
        candidates.append(contentsOf: allMatches(pattern: isbn10Pattern, in: text))

        // Normalize candidates
        return candidates.map { candidate in
            candidate.replacingOccurrences(of: " ", with: "")
                     .replacingOccurrences(of: "-", with: "")
                     .uppercased()
        }.filter { normalized in
            normalized.count == 10 || normalized.count == 13
        }
    }

    // MARK: - OCR Correction

    /// Common OCR character substitutions
    private static let ocrSubstitutions: [(from: Character, to: Character)] = [
        ("O", "0"),  // Letter O → Zero
        ("o", "0"),
        ("I", "1"),  // Letter I → One
        ("l", "1"),  // Lowercase L → One
        ("i", "1"),
        ("Z", "2"),  // Z → Two (less common)
        ("S", "5"),  // S → Five
        ("B", "8"),  // B → Eight
        ("G", "6"),  // G → Six
        ("g", "9"),  // g → Nine
        ("D", "0"),  // D → Zero
    ]

    /// Applies common OCR corrections to a string
    private static func applyOCRCorrections(_ text: String) -> String {
        var result = text.uppercased()

        for (from, to) in ocrSubstitutions {
            result = result.replacingOccurrences(of: String(from), with: String(to))
        }

        return result
    }

    /// Generates variations of the input by trying different OCR corrections
    private static func generateOCRVariations(_ text: String) -> [String] {
        var variations: [String] = []
        let chars = Array(text)

        // For each character position that could be ambiguous, try alternatives
        // Limit to avoid exponential explosion
        let ambiguousPositions = chars.indices.filter { index in
            let char = chars[index]
            return "0O1lIi5S8B6G9g".contains(char)
        }.prefix(4)  // Limit to first 4 ambiguous positions

        guard !ambiguousPositions.isEmpty else { return [] }

        // Generate variations for each ambiguous character
        for position in ambiguousPositions {
            let char = chars[position]

            let alternatives: [Character]
            switch char {
            case "0", "O", "o", "D":
                alternatives = ["0", "O"]
            case "1", "I", "l", "i":
                alternatives = ["1", "I"]
            case "5", "S":
                alternatives = ["5", "S"]
            case "8", "B":
                alternatives = ["8", "B"]
            case "6", "G":
                alternatives = ["6", "G"]
            case "9", "g":
                alternatives = ["9"]
            default:
                continue
            }

            for alt in alternatives where alt != char {
                var newChars = chars
                newChars[position] = alt
                variations.append(String(newChars))
            }
        }

        return variations
    }

    // MARK: - Regex Helpers

    private static func firstMatch(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        // Return the first capture group if present, otherwise the full match
        let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
        guard let swiftRange = Range(captureRange, in: text) else {
            return nil
        }

        return String(text[swiftRange])
    }

    private static func allMatches(pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        return matches.compactMap { match in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            return String(text[swiftRange])
        }
    }
}
