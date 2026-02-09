import SwiftUI
import SwiftData

/// Central "Add Book" hub presenting four entry methods
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \PendingLookup.dateQueued)
    private var allLookups: [PendingLookup]

    private var pendingLookups: [PendingLookup] {
        allLookups.filter { $0.status != .completed }
    }

    /// When false, used as tab root; when true, used as sheet with Cancel button
    var isSheet: Bool = true

    @State private var navigationPath = NavigationPath()

    enum Destination: Hashable {
        case isbnLookup
        case guidedOCR
        case quickPhoto
        case manualEntry
        case pendingLookups
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if !pendingLookups.isEmpty {
                    Section("Offline Queue") {
                        NavigationLink(value: Destination.pendingLookups) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Pending Lookups")
                                        .font(.headline)
                                    Text("\(pendingLookups.count) ISBN(s) queued")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "clock.badge.questionmark")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                    .frame(width: 32)
                            }
                        }
                    }
                }

                NavigationLink(value: Destination.isbnLookup) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scan Barcode/ISBN")
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
                            Text("Manual Entry with ISBN Lookup")
                                .font(.headline)
                            Text("Type details by hand or look up by ISBN")
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
                case .pendingLookups:
                    PendingLookupsView()
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
