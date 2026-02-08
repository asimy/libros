import SwiftUI
import SwiftData

/// Detail view for a smart collection showing filtered books
struct SmartCollectionDetailView: View {
    let collection: SmartCollection

    @Query(sort: \Book.title)
    private var allBooks: [Book]

    private var filteredBooks: [Book] {
        allBooks.filter { collection.matches($0) }
    }

    var body: some View {
        Group {
            if filteredBooks.isEmpty {
                ContentUnavailableView {
                    Label(collection.displayName, systemImage: collection.systemImage)
                } description: {
                    Text(emptyMessage)
                }
            } else {
                List {
                    ForEach(filteredBooks) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            BookRowView(book: book)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(collection.displayName)
    }

    private var emptyMessage: String {
        switch collection {
        case .recentlyAdded:
            return "No books added in the last 30 days."
        case .currentlyReading:
            return "You're not currently reading any books."
        case .unread:
            return "All your books have been read!"
        case .read:
            return "No books marked as read yet."
        case .highestRated:
            return "No books rated 4 stars or higher."
        case .favorites:
            return "No books rated 5 stars yet."
        }
    }
}

#Preview {
    NavigationStack {
        SmartCollectionDetailView(collection: .currentlyReading)
    }
    .modelContainer(.preview)
}
