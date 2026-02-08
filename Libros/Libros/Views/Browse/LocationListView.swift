import SwiftUI
import SwiftData

/// View showing all locations in the library
struct LocationListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Location.name)
    private var locations: [Location]

    @State private var searchText = ""
    @State private var showingAddLocation = false

    private var filteredLocations: [Location] {
        if searchText.isEmpty {
            return locations
        }
        let lowercasedSearch = searchText.lowercased()
        return locations.filter { $0.name.lowercased().contains(lowercasedSearch) }
    }

    var body: some View {
        Group {
            if locations.isEmpty {
                emptyStateView
            } else {
                locationListView
            }
        }
        .navigationTitle("Locations")
        .searchable(text: $searchText, prompt: "Search locations...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddLocation = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddLocation) {
            NavigationStack {
                LocationEditView(location: nil)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Locations", systemImage: "mappin.and.ellipse")
        } description: {
            Text("Locations will appear here when you create them to track where your books are stored.")
        } actions: {
            Button {
                showingAddLocation = true
            } label: {
                Text("Add Location")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var locationListView: some View {
        List {
            ForEach(filteredLocations) { location in
                NavigationLink {
                    LocationDetailView(location: location)
                } label: {
                    LocationRowView(location: location)
                }
            }
            .onDelete(perform: deleteLocations)
        }
        .listStyle(.insetGrouped)
        .overlay {
            if filteredLocations.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            let location = filteredLocations[index]
            modelContext.delete(location)
        }
    }
}

// MARK: - Location Row View

struct LocationRowView: View {
    let location: Location

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(.headline)

                if let description = location.locationDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text("\(location.copyCount) cop\(location.copyCount == 1 ? "y" : "ies")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        LocationListView()
    }
    .modelContainer(.preview)
}
