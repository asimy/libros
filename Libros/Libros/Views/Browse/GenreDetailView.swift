import SwiftUI
import SwiftData

/// Detail view for a single genre showing subgenres and books
struct GenreDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var genre: Genre

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            // Genre info
            Section {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)

                    Text(genre.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if genre.parent != nil {
                        Text(genre.fullPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(genre.totalBookCount) book\(genre.totalBookCount == 1 ? "" : "s") total")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)

            // Subgenres
            if !genre.children.isEmpty {
                Section("Subgenres") {
                    ForEach(genre.children.sorted { $0.name < $1.name }) { child in
                        NavigationLink {
                            GenreDetailView(genre: child)
                        } label: {
                            GenreRowView(genre: child)
                        }
                    }
                }
            }

            // Books
            Section("Books") {
                if genre.books.isEmpty {
                    Text("No books in this genre")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(genre.books.sorted { $0.title < $1.title }) { book in
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
        .navigationTitle(genre.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                GenreEditView(genre: genre)
            }
        }
        .confirmationDialog(
            "Delete Genre",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(genre)
            }
        } message: {
            Text("Are you sure you want to delete \"\(genre.name)\"? Books will not be deleted.")
        }
    }
}

#Preview {
    NavigationStack {
        GenreDetailView(genre: .preview)
    }
    .modelContainer(.preview)
}
