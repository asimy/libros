import SwiftUI
import SwiftData

/// Browse tab view with sections for smart collections and entity browsing
struct BrowseView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Collections") {
                    NavigationLink {
                        SmartCollectionsView()
                    } label: {
                        Label("Smart Collections", systemImage: "sparkles")
                    }
                }

                Section("Organize") {
                    NavigationLink {
                        GenreListView()
                    } label: {
                        Label("Genres", systemImage: "tag")
                    }

                    NavigationLink {
                        TagListView()
                    } label: {
                        Label("Tags", systemImage: "number")
                    }

                    NavigationLink {
                        LocationListView()
                    } label: {
                        Label("Locations", systemImage: "mappin.and.ellipse")
                    }

                    NavigationLink {
                        SeriesListView()
                    } label: {
                        Label("Series", systemImage: "books.vertical.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Browse")
        }
    }
}

#Preview {
    BrowseView()
        .modelContainer(.preview)
}
