import SwiftUI
import SwiftData

/// Main content view with tab-based navigation
struct ContentView: View {
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var selectedTab: Tab = .library

    enum Tab: String, CaseIterable {
        case library = "Library"
        case add = "Add"
        case authors = "Authors"
        case browse = "Browse"
        case settings = "Settings"

        var systemImage: String {
            switch self {
            case .library: return "books.vertical"
            case .add: return "plus.circle"
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

            AddBookView(isSheet: false)
                .tabItem {
                    Label(Tab.add.rawValue, systemImage: Tab.add.systemImage)
                }
                .tag(Tab.add)

            AuthorListView()
                .tabItem {
                    Label(Tab.authors.rawValue, systemImage: Tab.authors.systemImage)
                }
                .tag(Tab.authors)

            BrowseView()
                .tabItem {
                    Label(Tab.browse.rawValue, systemImage: Tab.browse.systemImage)
                }
                .tag(Tab.browse)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.systemImage)
                }
                .tag(Tab.settings)
        }
        .overlay(alignment: .top) {
            NetworkStatusBanner(networkMonitor: networkMonitor)
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

// MARK: - Preview

#Preview {
    ContentView()
        .environment(NetworkMonitor.shared)
        .modelContainer(.preview)
}
