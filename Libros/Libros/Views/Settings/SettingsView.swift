import SwiftUI
import SwiftData

/// Real settings view replacing the placeholder
struct SettingsView: View {
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = true
    @AppStorage("coverImageMode") private var coverImageMode: CoverImageMode = .syncWithCloudKit

    @Query(sort: \SavedFilter.dateSaved, order: .reverse)
    private var savedFilters: [SavedFilter]

    @State private var dummyFilter = LibraryFilter()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $iCloudSyncEnabled) {
                        Label("iCloud Sync", systemImage: "icloud")
                    }
                } header: {
                    Text("Sync")
                } footer: {
                    Text("When disabled, your library data is stored locally only. Changes take effect on next app launch.")
                }

                Section {
                    Picker(selection: $coverImageMode) {
                        ForEach(CoverImageMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    } label: {
                        Label("Cover Images", systemImage: "photo")
                    }
                } header: {
                    Text("Cover Images")
                } footer: {
                    Text(coverImageMode.description)
                }

                Section("Data") {
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export Library", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink {
                        ImportView()
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                }

                Section("Saved Filters") {
                    NavigationLink {
                        SavedFiltersView(currentFilter: $dummyFilter)
                    } label: {
                        HStack {
                            Label("Manage Filters", systemImage: "line.3.horizontal.decrease.circle")
                            Spacer()
                            Text("\(savedFilters.count)")
                                .foregroundStyle(.secondary)
                        }
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
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(.preview)
}
