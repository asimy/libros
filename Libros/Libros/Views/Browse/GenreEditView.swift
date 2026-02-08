import SwiftUI
import SwiftData

/// Form for creating or editing a genre
struct GenreEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Genre.name) private var allGenres: [Genre]

    let genre: Genre?

    @State private var name = ""
    @State private var selectedParentID: UUID?
    @State private var isUserCreated = true

    private var isNewGenre: Bool { genre == nil }

    /// Genres that can be selected as parent (excludes self and descendants to prevent cycles)
    private var availableParents: [Genre] {
        guard let genre = genre else { return allGenres }
        return allGenres.filter { candidate in
            candidate.id != genre.id && !isDescendant(candidate, of: genre)
        }
    }

    var body: some View {
        Form {
            Section("Genre Information") {
                TextField("Name", text: $name)
            }

            Section {
                Picker("Parent Genre", selection: $selectedParentID) {
                    Text("None (Root Genre)")
                        .tag(nil as UUID?)

                    ForEach(availableParents) { parent in
                        Text(parent.fullPath)
                            .tag(parent.id as UUID?)
                    }
                }
            } header: {
                Text("Hierarchy")
            } footer: {
                Text("Optionally nest this genre under a parent genre.")
            }
        }
        .navigationTitle(isNewGenre ? "Add Genre" : "Edit Genre")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveGenre()
                }
                .disabled(name.isEmpty)
            }
        }
        .onAppear {
            loadGenreData()
        }
    }

    // MARK: - Data Methods

    private func loadGenreData() {
        if let genre = genre {
            name = genre.name
            selectedParentID = genre.parent?.id
            isUserCreated = genre.isUserCreated
        }
    }

    private func saveGenre() {
        let targetGenre: Genre
        if let existing = genre {
            targetGenre = existing
        } else {
            targetGenre = Genre(name: name, isUserCreated: isUserCreated)
            modelContext.insert(targetGenre)
        }

        targetGenre.name = name

        if let parentID = selectedParentID {
            targetGenre.parent = allGenres.first { $0.id == parentID }
        } else {
            targetGenre.parent = nil
        }

        dismiss()
    }

    /// Checks if a genre is a descendant of another genre
    private func isDescendant(_ candidate: Genre, of ancestor: Genre) -> Bool {
        for child in ancestor.children {
            if child.id == candidate.id || isDescendant(candidate, of: child) {
                return true
            }
        }
        return false
    }
}

#Preview {
    NavigationStack {
        GenreEditView(genre: nil)
    }
    .modelContainer(.preview)
}
