import SwiftUI
import SwiftData

/// View listing all smart collections
struct SmartCollectionsView: View {
    var body: some View {
        List {
            ForEach(SmartCollection.allCases) { collection in
                NavigationLink {
                    SmartCollectionDetailView(collection: collection)
                } label: {
                    Label {
                        Text(collection.displayName)
                    } icon: {
                        Image(systemName: collection.systemImage)
                            .foregroundStyle(collection.color)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Smart Collections")
    }
}

#Preview {
    NavigationStack {
        SmartCollectionsView()
    }
    .modelContainer(.preview)
}
