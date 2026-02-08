import SwiftUI
import SwiftData

/// Form for creating or editing a series
struct SeriesEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let series: Series?

    @State private var name = ""
    @State private var seriesDescription = ""
    @State private var expectedCountText = ""

    private var isNewSeries: Bool { series == nil }

    var body: some View {
        Form {
            Section("Series Information") {
                TextField("Name", text: $name)

                TextField("Description (optional)", text: $seriesDescription)
            }

            Section {
                TextField("Expected Number of Books", text: $expectedCountText)
                    .keyboardType(.numberPad)
            } header: {
                Text("Completion Tracking")
            } footer: {
                Text("If you know the total number of books in the series, enter it here to track completion progress.")
            }
        }
        .navigationTitle(isNewSeries ? "Add Series" : "Edit Series")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSeries()
                }
                .disabled(name.isEmpty)
            }
        }
        .onAppear {
            loadSeriesData()
        }
    }

    // MARK: - Data Methods

    private func loadSeriesData() {
        if let series = series {
            name = series.name
            seriesDescription = series.seriesDescription ?? ""
            expectedCountText = series.expectedCount.map { String($0) } ?? ""
        }
    }

    private func saveSeries() {
        let targetSeries: Series
        if let existing = series {
            targetSeries = existing
        } else {
            targetSeries = Series(name: name)
            modelContext.insert(targetSeries)
        }

        targetSeries.name = name
        targetSeries.seriesDescription = seriesDescription.isEmpty ? nil : seriesDescription
        targetSeries.expectedCount = Int(expectedCountText)

        dismiss()
    }
}

#Preview {
    NavigationStack {
        SeriesEditView(series: nil)
    }
    .modelContainer(.preview)
}
