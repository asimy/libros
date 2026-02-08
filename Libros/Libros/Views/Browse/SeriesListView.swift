import SwiftUI
import SwiftData

/// View showing all series in the library
struct SeriesListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Series.name)
    private var allSeries: [Series]

    @State private var searchText = ""
    @State private var showingAddSeries = false

    private var filteredSeries: [Series] {
        if searchText.isEmpty {
            return allSeries
        }
        let lowercasedSearch = searchText.lowercased()
        return allSeries.filter { $0.name.lowercased().contains(lowercasedSearch) }
    }

    var body: some View {
        Group {
            if allSeries.isEmpty {
                emptyStateView
            } else {
                seriesListView
            }
        }
        .navigationTitle("Series")
        .searchable(text: $searchText, prompt: "Search series...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSeries = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSeries) {
            NavigationStack {
                SeriesEditView(series: nil)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Series", systemImage: "books.vertical.fill")
        } description: {
            Text("Series will appear here when you add them to your library.")
        } actions: {
            Button {
                showingAddSeries = true
            } label: {
                Text("Add Series")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var seriesListView: some View {
        List {
            ForEach(filteredSeries) { series in
                NavigationLink {
                    SeriesDetailView(series: series)
                } label: {
                    SeriesRowView(series: series)
                }
            }
            .onDelete(perform: deleteSeries)
        }
        .listStyle(.insetGrouped)
        .overlay {
            if filteredSeries.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private func deleteSeries(at offsets: IndexSet) {
        for index in offsets {
            let series = filteredSeries[index]
            modelContext.delete(series)
        }
    }
}

// MARK: - Series Row View

struct SeriesRowView: View {
    let series: Series

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "books.vertical.fill")
                .foregroundStyle(.purple)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(series.name)
                        .font(.headline)

                    if let isComplete = series.isComplete, isComplete {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Text(series.progressDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SeriesListView()
    }
    .modelContainer(.preview)
}
