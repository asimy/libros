import SwiftUI
import SwiftData

/// Detail view for a single author showing their books
struct AuthorDetailView: View {
    @Bindable var author: Author

    var body: some View {
        List {
            // Author info section
            Section {
                VStack(alignment: .center, spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))

                        Text(author.name.prefix(1).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.blue)
                    }
                    .frame(width: 80, height: 80)

                    Text(author.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(author.bookCount) book\(author.bookCount == 1 ? "" : "s") in library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)

            // Biography
            if let bio = author.biography, !bio.isEmpty {
                Section("Biography") {
                    Text(bio)
                        .font(.body)
                }
            }

            // Books section
            Section("Books") {
                if author.books.isEmpty {
                    Text("No books in library")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(author.books.sorted { $0.title < $1.title }) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            BookRowView(book: book)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(author.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AuthorDetailView(author: .preview)
    }
    .modelContainer(.preview)
}
