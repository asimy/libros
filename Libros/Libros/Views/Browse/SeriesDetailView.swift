import SwiftUI
import SwiftData

/// Detail view for a single series showing its books in order
struct SeriesDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var series: Series

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            // Series info
            Section {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.purple)

                    Text(series.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let description = series.seriesDescription, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Progress
                    HStack(spacing: 8) {
                        Text(series.progressDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let isComplete = series.isComplete, isComplete {
                            Label("Complete", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    // Progress bar
                    if let expected = series.expectedCount, expected > 0 {
                        ProgressView(value: Double(series.bookCount), total: Double(expected))
                            .tint(.purple)
                            .padding(.horizontal, 40)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)

            // Books in order
            Section("Books") {
                if series.books.isEmpty {
                    Text("No books in this series yet")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(series.sortedBooks) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            HStack {
                                if let order = book.seriesOrder {
                                    Text("#\(order)")
                                        .font(.headline)
                                        .foregroundStyle(.purple)
                                        .frame(width: 36)
                                }

                                BookRowView(book: book)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(series.name)
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
                SeriesEditView(series: series)
            }
        }
        .confirmationDialog(
            "Delete Series",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(series)
            }
        } message: {
            Text("Are you sure you want to delete \"\(series.name)\"? Books will not be deleted.")
        }
    }
}

#Preview {
    NavigationStack {
        SeriesDetailView(series: .preview)
    }
    .modelContainer(.preview)
}
