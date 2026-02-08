import Foundation

/// Represents a validated ISBN
struct ISBN: Equatable, Hashable, Sendable {
    /// The normalized ISBN-10 (if convertible)
    let isbn10: String?

    /// The normalized ISBN-13
    let isbn13: String

    /// The original input that was parsed
    let originalInput: String

    /// The format that was detected from input
    let detectedFormat: Format

    enum Format: String, Sendable {
        case isbn10 = "ISBN-10"
        case isbn13 = "ISBN-13"
    }
}

/// Validates and converts ISBN-10 and ISBN-13 formats
enum ISBNValidator {

    // MARK: - Validation

    /// Validates an ISBN-10 string
    /// - Parameter isbn: A 10-character ISBN string (hyphens/spaces will be removed)
    /// - Returns: `true` if the ISBN-10 is valid
    static func isValidISBN10(_ isbn: String) -> Bool {
        let normalized = normalize(isbn)

        guard normalized.count == 10 else { return false }

        // ISBN-10 uses modulo 11 check
        // Sum of (digit * position) where position is 10, 9, 8... 1
        // 'X' represents 10 in the check digit position

        var sum = 0
        for (index, char) in normalized.enumerated() {
            let position = 10 - index
            let value: Int

            if char == "X" || char == "x" {
                // X is only valid as the last character (check digit)
                guard index == 9 else { return false }
                value = 10
            } else if let digit = char.wholeNumberValue {
                value = digit
            } else {
                return false
            }

            sum += value * position
        }

        return sum % 11 == 0
    }

    /// Validates an ISBN-13 string
    /// - Parameter isbn: A 13-character ISBN string (hyphens/spaces will be removed)
    /// - Returns: `true` if the ISBN-13 is valid
    static func isValidISBN13(_ isbn: String) -> Bool {
        let normalized = normalize(isbn)

        guard normalized.count == 13 else { return false }
        guard normalized.allSatisfy({ $0.isNumber }) else { return false }

        // ISBN-13 uses modulo 10 check
        // Alternating weights of 1 and 3

        var sum = 0
        for (index, char) in normalized.enumerated() {
            guard let digit = char.wholeNumberValue else { return false }
            let weight = (index % 2 == 0) ? 1 : 3
            sum += digit * weight
        }

        return sum % 10 == 0
    }

    // MARK: - Conversion

    /// Converts an ISBN-10 to ISBN-13
    /// - Parameter isbn10: A valid ISBN-10 string
    /// - Returns: The equivalent ISBN-13, or `nil` if conversion fails
    static func toISBN13(_ isbn10: String) -> String? {
        let normalized = normalize(isbn10)

        guard normalized.count == 10 else { return nil }
        guard isValidISBN10(normalized) else { return nil }

        // Remove the ISBN-10 check digit and prepend 978
        let isbn12 = "978" + normalized.prefix(9)

        // Calculate the ISBN-13 check digit
        guard let checkDigit = calculateISBN13CheckDigit(String(isbn12)) else {
            return nil
        }

        return isbn12 + String(checkDigit)
    }

    /// Converts an ISBN-13 to ISBN-10 (only works for 978- prefix)
    /// - Parameter isbn13: A valid ISBN-13 string
    /// - Returns: The equivalent ISBN-10, or `nil` if conversion fails
    static func toISBN10(_ isbn13: String) -> String? {
        let normalized = normalize(isbn13)

        guard normalized.count == 13 else { return nil }
        guard normalized.hasPrefix("978") else { return nil }
        guard isValidISBN13(normalized) else { return nil }

        // Remove 978 prefix and the ISBN-13 check digit
        let isbn9 = String(normalized.dropFirst(3).prefix(9))

        // Calculate the ISBN-10 check digit
        guard let checkDigit = calculateISBN10CheckDigit(isbn9) else {
            return nil
        }

        return isbn9 + checkDigit
    }

    // MARK: - Parsing

    /// Parses and validates an ISBN string
    /// - Parameter input: An ISBN string in any format
    /// - Returns: A validated `ISBN` struct, or `nil` if invalid
    static func parse(_ input: String) -> ISBN? {
        let normalized = normalize(input)

        if normalized.count == 13 && isValidISBN13(normalized) {
            let isbn10 = toISBN10(normalized)
            return ISBN(
                isbn10: isbn10,
                isbn13: normalized,
                originalInput: input,
                detectedFormat: .isbn13
            )
        }

        if normalized.count == 10 && isValidISBN10(normalized) {
            guard let isbn13 = toISBN13(normalized) else { return nil }
            return ISBN(
                isbn10: normalized,
                isbn13: isbn13,
                originalInput: input,
                detectedFormat: .isbn10
            )
        }

        return nil
    }

    // MARK: - Formatting

    /// Formats an ISBN-13 with standard hyphenation
    /// Note: This uses a simplified format. Full hyphenation requires registration group data.
    /// - Parameter isbn: An ISBN-13 string
    /// - Returns: A hyphenated ISBN-13 (e.g., "978-0-306-40615-7")
    static func formatISBN13(_ isbn: String) -> String {
        let normalized = normalize(isbn)
        guard normalized.count == 13 else { return isbn }

        // Simplified format: 978-X-XXX-XXXXX-X
        // Real hyphenation varies by registration group
        let prefix = normalized.prefix(3)
        let group = normalized.dropFirst(3).prefix(1)
        let publisher = normalized.dropFirst(4).prefix(3)
        let title = normalized.dropFirst(7).prefix(5)
        let check = normalized.suffix(1)

        return "\(prefix)-\(group)-\(publisher)-\(title)-\(check)"
    }

    /// Formats an ISBN-10 with standard hyphenation
    /// - Parameter isbn: An ISBN-10 string
    /// - Returns: A hyphenated ISBN-10 (e.g., "0-306-40615-2")
    static func formatISBN10(_ isbn: String) -> String {
        let normalized = normalize(isbn)
        guard normalized.count == 10 else { return isbn }

        // Simplified format: X-XXX-XXXXX-X
        let group = normalized.prefix(1)
        let publisher = normalized.dropFirst(1).prefix(3)
        let title = normalized.dropFirst(4).prefix(5)
        let check = normalized.suffix(1)

        return "\(group)-\(publisher)-\(title)-\(check)"
    }

    // MARK: - Private Helpers

    /// Removes hyphens, spaces, and other non-alphanumeric characters
    private static func normalize(_ isbn: String) -> String {
        isbn.filter { $0.isLetter || $0.isNumber }.uppercased()
    }

    /// Calculates the check digit for an ISBN-13 (first 12 digits)
    private static func calculateISBN13CheckDigit(_ isbn12: String) -> Int? {
        guard isbn12.count == 12 else { return nil }

        var sum = 0
        for (index, char) in isbn12.enumerated() {
            guard let digit = char.wholeNumberValue else { return nil }
            let weight = (index % 2 == 0) ? 1 : 3
            sum += digit * weight
        }

        let remainder = sum % 10
        return remainder == 0 ? 0 : (10 - remainder)
    }

    /// Calculates the check digit for an ISBN-10 (first 9 digits)
    private static func calculateISBN10CheckDigit(_ isbn9: String) -> String? {
        guard isbn9.count == 9 else { return nil }

        var sum = 0
        for (index, char) in isbn9.enumerated() {
            guard let digit = char.wholeNumberValue else { return nil }
            let position = 10 - index
            sum += digit * position
        }

        let remainder = sum % 11
        let checkValue = (11 - remainder) % 11

        if checkValue == 10 {
            return "X"
        }
        return String(checkValue)
    }
}

// MARK: - ISBN Error Types

enum ISBNError: LocalizedError {
    case invalidFormat
    case invalidCheckDigit
    case conversionFailed
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The ISBN format is not recognized. Please enter a valid 10 or 13 digit ISBN."
        case .invalidCheckDigit:
            return "The ISBN check digit is incorrect. Please verify the number."
        case .conversionFailed:
            return "Could not convert between ISBN formats."
        case .notFound:
            return "No ISBN was found in the provided text."
        }
    }
}
