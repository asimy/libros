import SwiftUI
import SwiftData

/// View for exporting library data
struct ExportView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var exportError: String?
    @State private var showingShareSheet = false

    var body: some View {
        List {
            Section {
                Button {
                    exportLibrary()
                } label: {
                    HStack {
                        Label("Export Library", systemImage: "square.and.arrow.up")

                        Spacer()

                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)
            } footer: {
                Text("Exports all books, authors, genres, tags, locations, and series as a JSON file.")
            }

            if let error = exportError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            if let fileURL = exportedFileURL {
                Section("Export Ready") {
                    ShareLink(item: fileURL) {
                        Label("Share Export File", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Export Library")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func exportLibrary() {
        isExporting = true
        exportError = nil
        exportedFileURL = nil

        Task {
            do {
                let service = LibraryExportService()
                let data = try await service.exportLibrary(context: modelContext)

                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "libros-export-\(Date().formatted(.dateTime.year().month().day())).json"
                let fileURL = tempDir.appendingPathComponent(fileName)
                try data.write(to: fileURL)

                await MainActor.run {
                    exportedFileURL = fileURL
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    exportError = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExportView()
    }
    .modelContainer(.preview)
}
