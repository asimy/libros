import SwiftUI
import SwiftData

/// Detail view for a single location showing its book copies
struct LocationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var location: Location

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            // Location info
            Section {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)

                    Text(location.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let description = location.locationDescription, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(location.copyCount) cop\(location.copyCount == 1 ? "y" : "ies")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)

            // Copies
            Section("Book Copies") {
                if location.bookCopies.isEmpty {
                    Text("No book copies at this location")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(location.bookCopies.sorted { ($0.book?.title ?? "") < ($1.book?.title ?? "") }) { copy in
                        if let book = copy.book {
                            NavigationLink {
                                BookDetailView(book: book)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(book.title)
                                            .font(.headline)

                                        HStack(spacing: 8) {
                                            Text(copy.format.displayName)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)

                                            if let condition = copy.condition {
                                                Text(condition.displayName)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(location.name)
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
                LocationEditView(location: location)
            }
        }
        .confirmationDialog(
            "Delete Location",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(location)
            }
        } message: {
            Text("Are you sure you want to delete \"\(location.name)\"? Book copies will not be deleted.")
        }
    }
}

#Preview {
    NavigationStack {
        LocationDetailView(location: .preview)
    }
    .modelContainer(.preview)
}
