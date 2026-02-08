import SwiftUI
import SwiftData

/// Detail view for a single tag showing its books
struct TagDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var tag: Tag

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            // Tag info
            Section {
                VStack(alignment: .center, spacing: 12) {
                    Circle()
                        .fill(tag.colorHex.map { Color(hex: $0) } ?? .secondary)
                        .frame(width: 60, height: 60)

                    Text(tag.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(tag.bookCount) book\(tag.bookCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)

            // Books
            Section("Books") {
                if tag.books.isEmpty {
                    Text("No books with this tag")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(tag.books.sorted { $0.title < $1.title }) { book in
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
        .navigationTitle(tag.name)
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
                TagEditView(tag: tag)
            }
        }
        .confirmationDialog(
            "Delete Tag",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(tag)
            }
        } message: {
            Text("Are you sure you want to delete \"\(tag.name)\"? Books will not be deleted.")
        }
    }
}

#Preview {
    NavigationStack {
        TagDetailView(tag: .preview)
    }
    .modelContainer(.preview)
}
