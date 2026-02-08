import SwiftUI
import SwiftData

/// List view showing pending and failed ISBN lookups
struct PendingLookupsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PendingLookup.dateQueued)
    private var allLookups: [PendingLookup]

    private var pendingLookups: [PendingLookup] {
        allLookups.filter { $0.status != .completed }
    }

    var body: some View {
        Group {
            if pendingLookups.isEmpty {
                ContentUnavailableView(
                    "No Pending Lookups",
                    systemImage: "checkmark.circle",
                    description: Text("All ISBN lookups have been processed.")
                )
            } else {
                List {
                    ForEach(pendingLookups) { lookup in
                        lookupRow(lookup)
                    }
                    .onDelete(perform: deleteLookups)
                }
            }
        }
        .navigationTitle("Pending Lookups")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Row

    private func lookupRow(_ lookup: PendingLookup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(ISBNValidator.formatISBN13(lookup.isbn))
                    .font(.system(.body, design: .monospaced))

                Spacer()

                Label(lookup.status.displayName, systemImage: lookup.status.systemImage)
                    .font(.caption)
                    .foregroundStyle(colorForStatus(lookup.status))
            }

            if let error = lookup.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Queued \(lookup.dateQueued, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                if lookup.status == .failed || lookup.status == .notFound {
                    Button("Retry") {
                        lookup.status = .pending
                        lookup.retryCount = 0
                        lookup.lastError = nil
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func deleteLookups(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(pendingLookups[index])
        }
    }

    // MARK: - Helpers

    private func colorForStatus(_ status: LookupStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        case .notFound: return .secondary
        }
    }
}
