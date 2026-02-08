import SwiftUI
import SwiftData

/// Multi-select genre picker with hierarchy indentation and inline creation
struct GenrePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Genre.name) private var allGenres: [Genre]
    @Binding var selectedGenreIDs: Set<UUID>
    @State private var searchText = ""
    @State private var newGenreName = ""

    private var filteredGenres: [Genre] {
        if searchText.isEmpty {
            return allGenres
        }
        let lowercasedSearch = searchText.lowercased()
        return allGenres.filter { $0.name.lowercased().contains(lowercasedSearch) }
    }

    var body: some View {
        List {
            // New genre row
            Section {
                HStack {
                    TextField("New genre name", text: $newGenreName)

                    Button {
                        createAndSelectGenre()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .disabled(newGenreName.isEmpty)
                }
            }

            // Existing genres
            Section {
            ForEach(filteredGenres) { genre in
                Button {
                    toggleGenre(genre)
                } label: {
                    HStack {
                        // Indentation based on depth
                        if genre.depth > 0 && searchText.isEmpty {
                            Spacer()
                                .frame(width: CGFloat(genre.depth) * 20)
                        }

                        VStack(alignment: .leading) {
                            Text(genre.name)
                                .foregroundStyle(.primary)

                            if !searchText.isEmpty && genre.parent != nil {
                                Text(genre.fullPath)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if selectedGenreIDs.contains(genre.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search genres...")
        .navigationTitle("Select Genres")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleGenre(_ genre: Genre) {
        if selectedGenreIDs.contains(genre.id) {
            selectedGenreIDs.remove(genre.id)
        } else {
            selectedGenreIDs.insert(genre.id)
        }
    }

    private func createAndSelectGenre() {
        let trimmedName = newGenreName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let genre = Genre(name: trimmedName)
        modelContext.insert(genre)
        selectedGenreIDs.insert(genre.id)
        newGenreName = ""
    }
}
