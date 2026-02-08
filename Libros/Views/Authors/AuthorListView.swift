import SwiftUI
import SwiftData

/// View showing all authors in the library
struct AuthorListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Author.sortName)
    private var authors: [Author]

    @State private var searchText = ""

    private var filteredAuthors: [Author] {
        if searchText.isEmpty {
            return authors
        }

        let lowercasedSearch = searchText.lowercased()
        return authors.filter { author in
            author.name.lowercased().contains(lowercasedSearch)
        }
    }

    private var groupedAuthors: [(String, [Author])] {
        let grouped = Dictionary(grouping: filteredAuthors) { author in
            author.sortLetter
        }

        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if authors.isEmpty {
                    emptyStateView
                } else {
                    authorListView
                }
            }
            .navigationTitle("Authors")
            .searchable(text: $searchText, prompt: "Search authors...")
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Authors", systemImage: "person.2")
        } description: {
            Text("Authors will appear here when you add books to your library.")
        }
    }

    private var authorListView: some View {
        List {
            ForEach(groupedAuthors, id: \.0) { letter, authorsInSection in
                Section(header: Text(letter)) {
                    ForEach(authorsInSection) { author in
                        NavigationLink {
                            AuthorDetailView(author: author)
                        } label: {
                            AuthorRowView(author: author)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if filteredAuthors.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}

// MARK: - Author Row View

struct AuthorRowView: View {
    let author: Author

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))

                Text(author.name.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            .frame(width: 44, height: 44)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(author.name)
                    .font(.headline)

                Text("\(author.bookCount) book\(author.bookCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    AuthorListView()
        .modelContainer(.preview)
}
