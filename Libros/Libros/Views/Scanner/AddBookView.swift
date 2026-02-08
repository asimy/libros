import SwiftUI
import SwiftData

/// Central "Add Book" hub presenting four entry methods
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss

    /// When false, used as tab root; when true, used as sheet with Cancel button
    var isSheet: Bool = true

    @State private var navigationPath = NavigationPath()

    enum Destination: Hashable {
        case isbnLookup
        case guidedOCR
        case quickPhoto
        case manualEntry
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                NavigationLink(value: Destination.isbnLookup) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ISBN Lookup")
                                .font(.headline)
                            Text("Scan barcode or ISBN text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 32)
                    }
                }

                NavigationLink(value: Destination.guidedOCR) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Guided OCR")
                                .font(.headline)
                            Text("Photograph book pages to extract info")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "text.viewfinder")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .frame(width: 32)
                    }
                }

                NavigationLink(value: Destination.quickPhoto) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick Photo")
                                .font(.headline)
                            Text("Cover photo plus title and author")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "camera")
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .frame(width: 32)
                    }
                }

                NavigationLink(value: Destination.manualEntry) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Manual Entry")
                                .font(.headline)
                            Text("Type all book details by hand")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "keyboard")
                            .font(.title2)
                            .foregroundStyle(.purple)
                            .frame(width: 32)
                    }
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isSheet {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .isbnLookup:
                    BarcodeScannerView(
                        isEmbedded: true,
                        onBookAdded: { dismiss() },
                        onSwitchMethod: { switchMethod($0) }
                    )
                case .guidedOCR:
                    GuidedOCRView(onComplete: { dismiss() })
                case .quickPhoto:
                    QuickPhotoView(onComplete: { dismiss() })
                case .manualEntry:
                    BookEditView(book: nil, isEmbedded: true)
                }
            }
        }
    }

    // MARK: - Method Switching

    private func switchMethod(_ destination: Destination) {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
        navigationPath.append(destination)
    }
}

// MARK: - Preview

#Preview {
    AddBookView()
        .modelContainer(.preview)
}

#Preview("As Tab") {
    AddBookView(isSheet: false)
        .modelContainer(.preview)
}
