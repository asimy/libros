import SwiftUI
import SwiftData

/// View showing all genres in the library with hierarchy support
struct GenreListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Genre.name)
    private var allGenres: [Genre]

    @State private var searchText = ""
    @State private var showingAddGenre = false

    private var rootGenres: [Genre] {
        allGenres.filter { $0.isRoot }
    }

    private var filteredGenres: [Genre] {
        if searchText.isEmpty {
            return rootGenres
        }
        let lowercasedSearch = searchText.lowercased()
        return allGenres.filter { $0.name.lowercased().contains(lowercasedSearch) }
    }

    var body: some View {
        Group {
            if allGenres.isEmpty {
                emptyStateView
            } else {
                genreListView
            }
        }
        .navigationTitle("Genres")
        .searchable(text: $searchText, prompt: "Search genres...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddGenre = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGenre) {
            NavigationStack {
                GenreEditView(genre: nil)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Genres", systemImage: "tag")
        } description: {
            Text("Genres will appear here when you add them to your library.")
        } actions: {
            Button {
                showingAddGenre = true
            } label: {
                Text("Add Genre")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var genreListView: some View {
        List {
            ForEach(filteredGenres) { genre in
                NavigationLink {
                    GenreDetailView(genre: genre)
                } label: {
                    GenreRowView(genre: genre)
                }
            }
            .onDelete(perform: deleteGenres)
        }
        .listStyle(.insetGrouped)
        .overlay {
            if filteredGenres.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private func deleteGenres(at offsets: IndexSet) {
        for index in offsets {
            let genre = filteredGenres[index]
            modelContext.delete(genre)
        }
    }
}

// MARK: - Genre Row View

struct GenreRowView: View {
    let genre: Genre

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: genre.children.isEmpty ? "tag" : "folder")
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(genre.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text("\(genre.totalBookCount) book\(genre.totalBookCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !genre.children.isEmpty {
                        Text("\(genre.children.count) subgenre\(genre.children.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        GenreListView()
    }
    .modelContainer(.preview)
}
