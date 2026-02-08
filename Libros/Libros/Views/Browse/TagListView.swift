import SwiftUI
import SwiftData

/// View showing all tags in the library
struct TagListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Tag.name)
    private var tags: [Tag]

    @State private var searchText = ""
    @State private var showingAddTag = false

    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return tags
        }
        let lowercasedSearch = searchText.lowercased()
        return tags.filter { $0.name.lowercased().contains(lowercasedSearch) }
    }

    var body: some View {
        Group {
            if tags.isEmpty {
                emptyStateView
            } else {
                tagListView
            }
        }
        .navigationTitle("Tags")
        .searchable(text: $searchText, prompt: "Search tags...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddTag = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTag) {
            NavigationStack {
                TagEditView(tag: nil)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Tags", systemImage: "number")
        } description: {
            Text("Tags will appear here when you create them.")
        } actions: {
            Button {
                showingAddTag = true
            } label: {
                Text("Add Tag")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var tagListView: some View {
        List {
            ForEach(filteredTags) { tag in
                NavigationLink {
                    TagDetailView(tag: tag)
                } label: {
                    TagRowView(tag: tag)
                }
            }
            .onDelete(perform: deleteTags)
        }
        .listStyle(.insetGrouped)
        .overlay {
            if filteredTags.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = filteredTags[index]
            modelContext.delete(tag)
        }
    }
}

// MARK: - Tag Row View

struct TagRowView: View {
    let tag: Tag

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(tag.colorHex.map { Color(hex: $0) } ?? .secondary)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(tag.name)
                    .font(.headline)

                Text("\(tag.bookCount) book\(tag.bookCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        TagListView()
    }
    .modelContainer(.preview)
}
