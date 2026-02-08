import Foundation
import SwiftData

/// Represents a physical copy of a book
@Model
final class BookCopy {
    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// Physical format of this copy
    var format: BookFormat

    /// Condition of this copy
    var condition: BookCondition?

    /// When this copy was acquired
    var dateAcquired: Date?

    /// Purchase price (stored as string for locale-independent storage)
    var purchasePriceValue: Decimal?

    /// Currency code for purchase price (e.g., "USD", "EUR")
    var purchasePriceCurrency: String?

    /// Notes specific to this copy
    var notes: String?

    /// Date this copy record was created
    var dateAdded: Date

    /// Date this copy record was last modified
    var dateModified: Date

    // MARK: - Relationships

    /// The book this is a copy of
    var book: Book?

    /// Physical location of this copy
    var location: Location?

    // MARK: - Computed Properties

    /// Formatted price string
    var formattedPrice: String? {
        guard let value = purchasePriceValue else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = purchasePriceCurrency ?? "USD"

        return formatter.string(from: value as NSDecimalNumber)
    }

    /// Brief description of this copy (format and condition)
    var briefDescription: String {
        var parts = [format.displayName]

        if let condition = condition {
            parts.append(condition.displayName)
        }

        if let location = location {
            parts.append(location.name)
        }

        return parts.joined(separator: " • ")
    }

    /// Whether this copy has a known location
    var hasLocation: Bool {
        location != nil
    }

    // MARK: - Initialization

    init(
        format: BookFormat = .paperback,
        condition: BookCondition? = nil,
        location: Location? = nil,
        dateAcquired: Date? = nil
    ) {
        self.id = UUID()
        self.format = format
        self.condition = condition
        self.location = location
        self.dateAcquired = dateAcquired
        self.dateAdded = Date()
        self.dateModified = Date()
    }

    // MARK: - Methods

    /// Sets the purchase price
    func setPrice(_ value: Decimal?, currency: String = "USD") {
        purchasePriceValue = value
        purchasePriceCurrency = currency
        dateModified = Date()
    }

    /// Updates the location
    func moveTo(_ newLocation: Location?) {
        location = newLocation
        dateModified = Date()
    }
}

// MARK: - Sample Data

extension BookCopy {
    static var preview: BookCopy {
        let copy = BookCopy(
            format: .hardcover,
            condition: .good,
            dateAcquired: Date()
        )
        copy.setPrice(24.99)
        return copy
    }

    static var previews: [BookCopy] {
        [
            {
                let copy = BookCopy(format: .hardcover, condition: .likeNew)
                copy.setPrice(29.99)
                return copy
            }(),
            {
                let copy = BookCopy(format: .paperback, condition: .good)
                copy.setPrice(14.99)
                return copy
            }(),
            {
                let copy = BookCopy(format: .ebook)
                copy.setPrice(9.99)
                return copy
            }()
        ]
    }
}
