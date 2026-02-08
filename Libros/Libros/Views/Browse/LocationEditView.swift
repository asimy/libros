import SwiftUI
import SwiftData

/// Form for creating or editing a location
struct LocationEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let location: Location?

    @State private var name = ""
    @State private var locationDescription = ""

    private var isNewLocation: Bool { location == nil }

    var body: some View {
        Form {
            Section("Location Information") {
                TextField("Name", text: $name)

                TextField("Description (optional)", text: $locationDescription)
            }
        }
        .navigationTitle(isNewLocation ? "Add Location" : "Edit Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveLocation()
                }
                .disabled(name.isEmpty)
            }
        }
        .onAppear {
            loadLocationData()
        }
    }

    // MARK: - Data Methods

    private func loadLocationData() {
        if let location = location {
            name = location.name
            locationDescription = location.locationDescription ?? ""
        }
    }

    private func saveLocation() {
        let targetLocation: Location
        if let existing = location {
            targetLocation = existing
        } else {
            targetLocation = Location(name: name, description: locationDescription.isEmpty ? nil : locationDescription)
            modelContext.insert(targetLocation)
        }

        targetLocation.name = name
        targetLocation.locationDescription = locationDescription.isEmpty ? nil : locationDescription

        dismiss()
    }
}

#Preview {
    NavigationStack {
        LocationEditView(location: nil)
    }
    .modelContainer(.preview)
}
