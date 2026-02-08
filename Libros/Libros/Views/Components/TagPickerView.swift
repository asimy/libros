import SwiftUI
import SwiftData

/// Multi-select tag picker with color indicators and inline creation
struct TagPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @Binding var selectedTagIDs: Set<UUID>
    @State private var searchText = ""
    @State private var newTagName = ""

    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return allTags
        }
        let lowercasedSearch = searchText.lowercased()
        return allTags.filter { $0.name.lowercased().contains(lowercasedSearch) }
    }

    var body: some View {
        List {
            // New tag row
            Section {
                HStack {
                    TextField("New tag name", text: $newTagName)

                    Button {
                        createAndSelectTag()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .disabled(newTagName.isEmpty)
                }
            }

            // Existing tags
            Section {
                ForEach(filteredTags) { tag in
                    Button {
                        toggleTag(tag)
                    } label: {
                        HStack {
                            Circle()
                                .fill(tag.colorHex.map { Color(hex: $0) } ?? .secondary)
                                .frame(width: 12, height: 12)

                            Text(tag.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedTagIDs.contains(tag.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search tags...")
        .navigationTitle("Select Tags")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleTag(_ tag: Tag) {
        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.remove(tag.id)
        } else {
            selectedTagIDs.insert(tag.id)
        }
    }

    private func createAndSelectTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let tag = Tag(name: trimmedName, colorHex: TagColors.defaultHex)
        modelContext.insert(tag)
        selectedTagIDs.insert(tag.id)
        newTagName = ""
    }
}
