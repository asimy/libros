import SwiftUI
import SwiftData

/// Main content view with tab-based navigation
struct ContentView: View {
    @State private var selectedTab: Tab = .library

    enum Tab: String, CaseIterable {
        case library = "Library"
        case scan = "Scan"
        case authors = "Authors"
        case browse = "Browse"
        case settings = "Settings"

        var systemImage: String {
            switch self {
            case .library: return "books.vertical"
            case .scan: return "barcode.viewfinder"
            case .authors: return "person.2"
            case .browse: return "folder"
            case .settings: return "gear"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label(Tab.library.rawValue, systemImage: Tab.library.systemImage)
                }
                .tag(Tab.library)

            BarcodeScannerView()
                .tabItem {
                    Label(Tab.scan.rawValue, systemImage: Tab.scan.systemImage)
                }
                .tag(Tab.scan)

            AuthorListView()
                .tabItem {
                    Label(Tab.authors.rawValue, systemImage: Tab.authors.systemImage)
                }
                .tag(Tab.authors)

            BrowsePlaceholderView()
                .tabItem {
                    Label(Tab.browse.rawValue, systemImage: Tab.browse.systemImage)
                }
                .tag(Tab.browse)

            SettingsPlaceholderView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.systemImage)
                }
                .tag(Tab.settings)
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

struct ScanPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)

                Text("Scanner")
                    .font(.title)

                Text("Barcode and OCR scanning coming soon")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Scan")
        }
    }
}

struct BrowsePlaceholderView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    Text("Genres list coming soon")
                } label: {
                    Label("Genres", systemImage: "tag")
                }

                NavigationLink {
                    Text("Tags list coming soon")
                } label: {
                    Label("Tags", systemImage: "number")
                }

                NavigationLink {
                    Text("Locations list coming soon")
                } label: {
                    Label("Locations", systemImage: "mappin.and.ellipse")
                }

                NavigationLink {
                    Text("Series list coming soon")
                } label: {
                    Label("Series", systemImage: "books.vertical.fill")
                }
            }
            .navigationTitle("Browse")
        }
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Sync") {
                    HStack {
                        Label("iCloud Sync", systemImage: "icloud")
                        Spacer()
                        Text("Enabled")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Data") {
                    NavigationLink {
                        Text("Export coming soon")
                    } label: {
                        Label("Export Library", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink {
                        Text("Import coming soon")
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(.preview)
}
