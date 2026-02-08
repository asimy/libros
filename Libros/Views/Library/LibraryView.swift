import SwiftUI
import SwiftData

/// Main library view showing all books
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Book.title)
    private var books: [Book]

    @State private var searchText = ""
    @State private var showingAddBook = false
    @State private var viewMode: ViewMode = .list
    @State private var sortOrder: SortOrder = .title

    enum ViewMode: String, CaseIterable {
        case list = "List"
        case grid = "Grid"

        var systemImage: String {
            switch self {
            case .list: return "list.bullet"
            case .grid: return "square.grid.2x2"
            }
        }
    }

    enum SortOrder: String, CaseIterable {
        case title = "Title"
        case author = "Author"
        case dateAdded = "Date Added"
        case rating = "Rating"

        var systemImage: String {
            switch self {
            case .title: return "textformat.abc"
            case .author: return "person"
            case .dateAdded: return "calendar"
            case .rating: return "star"
            }
        }
    }

    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return sortedBooks
        }

        let lowercasedSearch = searchText.lowercased()
        return sortedBooks.filter { book in
            book.title.lowercased().contains(lowercasedSearch) ||
            book.authorNames.lowercased().contains(lowercasedSearch) ||
            book.isbn13?.contains(searchText) == true ||
            book.isbn10?.contains(searchText) == true
        }
    }

    private var sortedBooks: [Book] {
        switch sortOrder {
        case .title:
            return books.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .author:
            return books.sorted { $0.authorNames.localizedCompare($1.authorNames) == .orderedAscending }
        case .dateAdded:
            return books.sorted { $0.dateAdded > $1.dateAdded }
        case .rating:
            return books.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    emptyStateView
                } else {
                    bookListView
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search books...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("View Mode", selection: $viewMode) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.systemImage)
                            }
                        }

                        Divider()

                        Picker("Sort By", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Label(order.rawValue, systemImage: order.systemImage)
                            }
                        }
                    } label: {
                        Image(systemName: viewMode.systemImage)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddBook = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                BookEditView(book: nil)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Books", systemImage: "books.vertical")
        } description: {
            Text("Your library is empty. Tap the + button to add your first book, or use the Scan tab to scan a barcode.")
        } actions: {
            Button {
                showingAddBook = true
            } label: {
                Text("Add Book")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var bookListView: some View {
        switch viewMode {
        case .list:
            listView
        case .grid:
            gridView
        }
    }

    private var listView: some View {
        List {
            ForEach(filteredBooks) { book in
                NavigationLink {
                    BookDetailView(book: book)
                } label: {
                    BookRowView(book: book)
                }
            }
            .onDelete(perform: deleteBooks)
        }
        .listStyle(.plain)
        .overlay {
            if filteredBooks.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150, maximum: 180))],
                spacing: 16
            ) {
                ForEach(filteredBooks) { book in
                    NavigationLink {
                        BookDetailView(book: book)
                    } label: {
                        BookGridItemView(book: book)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .overlay {
            if filteredBooks.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    // MARK: - Actions

    private func deleteBooks(at offsets: IndexSet) {
        for index in offsets {
            let book = filteredBooks[index]
            modelContext.delete(book)
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .modelContainer(.preview)
}

#Preview("Empty State") {
    LibraryView()
        .modelContainer(for: Book.self, inMemory: true)
}
