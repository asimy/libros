import SwiftUI
import SwiftData

/// Inline form for editing a single book copy
struct BookCopyEditView: View {
    @Bindable var copy: BookCopy
    @Query(sort: \Location.name) private var locations: [Location]

    var body: some View {
        Group {
            Picker("Format", selection: $copy.format) {
                ForEach(BookFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }

            Picker("Condition", selection: $copy.condition) {
                Text("Not Specified").tag(nil as BookCondition?)
                ForEach(BookCondition.allCases) { condition in
                    Text(condition.displayName).tag(condition as BookCondition?)
                }
            }

            Picker("Location", selection: $copy.location) {
                Text("No Location").tag(nil as Location?)
                ForEach(locations) { location in
                    Text(location.name).tag(location as Location?)
                }
            }

            DatePicker(
                "Date Acquired",
                selection: Binding(
                    get: { copy.dateAcquired ?? Date() },
                    set: { copy.dateAcquired = $0 }
                ),
                displayedComponents: .date
            )
        }
    }
}
