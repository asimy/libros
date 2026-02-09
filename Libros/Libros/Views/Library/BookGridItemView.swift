import SwiftUI
import SwiftData

/// A grid item view for displaying a book in a grid layout
struct BookGridItemView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            BookCoverView(book: book, size: .large)
                .overlay(alignment: .topTrailing) {
                    if book.readStatus == .reading {
                        readingBadge
                    }
                }

            // Title
            Text(book.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Author
            Text(book.authorNames)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Rating
            if let rating = book.rating {
                ratingView(rating: rating)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Subviews

    private var readingBadge: some View {
        Image(systemName: "bookmark.fill")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(4)
            .background(.blue)
            .clipShape(Circle())
            .padding(6)
    }

    private func ratingView(rating: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: 8))
                    .foregroundStyle(index <= rating ? .yellow : .secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
            BookGridItemView(book: .preview)
            BookGridItemView(book: {
                let book = Book(title: "A Longer Title")
                book.readStatus = .reading
                book.rating = 4
                return book
            }())
            BookGridItemView(book: {
                let book = Book(title: "No Cover")
                book.readStatus = .unread
                return book
            }())
            BookGridItemView(book: {
                let book = Book(title: "Another Book With a Very Long Title")
                book.rating = 5
                book.readStatus = .read
                return book
            }())
        }
        .padding()
    }
    .modelContainer(.preview)
}
