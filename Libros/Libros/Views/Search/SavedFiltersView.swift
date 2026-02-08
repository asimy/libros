import SwiftUI
import SwiftData

/// View for managing saved filters
struct SavedFiltersView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \SavedFilter.dateSaved, order: .reverse)
    private var savedFilters: [SavedFilter]

    @Binding var currentFilter: LibraryFilter
    @State private var showingSaveSheet = false
    @State private var newFilterName = ""

    var body: some View {
        List {
            if currentFilter.isActive {
                Section {
                    Button {
                        showingSaveSheet = true
                    } label: {
                        Label("Save Current Filter", systemImage: "square.and.arrow.down")
                    }
                }
            }

            Section("Saved Filters") {
                if savedFilters.isEmpty {
                    Text("No saved filters")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(savedFilters) { saved in
                        Button {
                            currentFilter = saved.toFilter()
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(saved.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("Saved \(saved.dateSaved.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteFilters)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Saved Filters")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Save Filter", isPresented: $showingSaveSheet) {
            TextField("Filter Name", text: $newFilterName)
            Button("Save") {
                saveCurrentFilter()
            }
            Button("Cancel", role: .cancel) {
                newFilterName = ""
            }
        } message: {
            Text("Enter a name for this filter configuration.")
        }
    }

    private func saveCurrentFilter() {
        guard !newFilterName.isEmpty else { return }
        let saved = SavedFilter.fromFilter(currentFilter, name: newFilterName)
        modelContext.insert(saved)
        newFilterName = ""
    }

    private func deleteFilters(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedFilters[index])
        }
    }
}
