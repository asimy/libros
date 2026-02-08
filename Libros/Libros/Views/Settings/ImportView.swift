import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// View for importing library data from JSON
struct ImportView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var showingFilePicker = false
    @State private var isImporting = false
    @State private var importStrategy: LibraryExportService.ImportStrategy = .merge
    @State private var importError: String?
    @State private var importResult: LibraryExportService.ImportResult?

    var body: some View {
        List {
            Section {
                Picker("Import Strategy", selection: $importStrategy) {
                    Text("Merge (skip duplicates)").tag(LibraryExportService.ImportStrategy.merge)
                    Text("Replace (clear first)").tag(LibraryExportService.ImportStrategy.replace)
                }
            } footer: {
                switch importStrategy {
                case .merge:
                    Text("Books with matching ISBNs will be skipped. New books and entities will be added.")
                case .replace:
                    Text("Warning: All existing data will be deleted before importing.")
                }
            }

            Section {
                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Label("Select JSON File", systemImage: "doc")

                        Spacer()

                        if isImporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isImporting)
            }

            if let error = importError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            if let result = importResult {
                Section("Import Complete") {
                    LabeledContent("Books Imported", value: "\(result.booksImported)")
                    LabeledContent("Authors Imported", value: "\(result.authorsImported)")
                    LabeledContent("Genres Imported", value: "\(result.genresImported)")
                    LabeledContent("Tags Imported", value: "\(result.tagsImported)")
                    LabeledContent("Locations Imported", value: "\(result.locationsImported)")
                    LabeledContent("Series Imported", value: "\(result.seriesImported)")

                    if result.booksSkipped > 0 {
                        LabeledContent("Books Skipped (duplicates)", value: "\(result.booksSkipped)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Import Data")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFile(from: url)
        case .failure(let error):
            importError = error.localizedDescription
        }
    }

    private func importFile(from url: URL) {
        isImporting = true
        importError = nil
        importResult = nil

        Task {
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "ImportView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access selected file."])
                }
                defer { url.stopAccessingSecurityScopedResource() }

                let data = try Data(contentsOf: url)
                let service = LibraryExportService()
                let result = try await service.importLibrary(from: data, context: modelContext, strategy: importStrategy)

                await MainActor.run {
                    importResult = result
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importError = error.localizedDescription
                    isImporting = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ImportView()
    }
    .modelContainer(.preview)
}
