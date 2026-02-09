import SwiftUI
import SwiftData

/// A row view for displaying a book in a list
struct BookRowView: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            // Cover image
            BookCoverView(book: book, size: .small)

            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.authorNames)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Read status
                    readStatusBadge

                    // Rating
                    if let rating = book.rating {
                        ratingView(rating: rating)
                    }

                    // Series info
                    if let seriesInfo = book.seriesInfo {
                        Text(seriesInfo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var readStatusBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: book.readStatus.systemImage)
            Text(book.readStatus.displayName)
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(readStatusColor.opacity(0.2))
        .foregroundStyle(readStatusColor)
        .clipShape(Capsule())
    }

    private var readStatusColor: Color {
        switch book.readStatus {
        case .unread: return .secondary
        case .reading: return .blue
        case .read: return .green
        }
    }

    private func ratingView(rating: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(index <= rating ? .yellow : .secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        BookRowView(book: .preview)
        BookRowView(book: {
            let book = Book(title: "A Very Long Book Title That Might Need Truncation")
            book.readStatus = .reading
            book.rating = 3
            return book
        }())
        BookRowView(book: {
            let book = Book(title: "Unrated Book")
            book.readStatus = .unread
            return book
        }())
    }
    .modelContainer(.preview)
}
