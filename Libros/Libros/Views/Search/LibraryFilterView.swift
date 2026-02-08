import SwiftUI
import SwiftData

/// Sheet for configuring library filters
struct LibraryFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Author.sortName) private var authors: [Author]
    @Query(sort: \Genre.name) private var genres: [Genre]
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Query(sort: \Location.name) private var locations: [Location]

    @Binding var filter: LibraryFilter

    var body: some View {
        NavigationStack {
            List {
                // Read Status
                Section {
                    DisclosureGroup {
                        ForEach(ReadStatus.allCases) { status in
                            Button {
                                toggleReadStatus(status)
                            } label: {
                                HStack {
                                    Label(status.displayName, systemImage: status.systemImage)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if filter.readStatuses.contains(status) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        filterSectionLabel("Read Status", count: filter.readStatuses.count)
                    }
                }

                // Rating
                Section {
                    HStack {
                        Text("Minimum Rating")

                        Spacer()

                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { index in
                                Button {
                                    if filter.minimumRating == index {
                                        filter.minimumRating = nil
                                    } else {
                                        filter.minimumRating = index
                                    }
                                } label: {
                                    Image(systemName: (filter.minimumRating ?? 0) >= index ? "star.fill" : "star")
                                        .foregroundStyle((filter.minimumRating ?? 0) >= index ? .yellow : .secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Authors
                if !authors.isEmpty {
                    Section {
                        DisclosureGroup {
                            ForEach(authors) { author in
                                Button {
                                    toggleID(author.id, in: &filter.authorIDs)
                                } label: {
                                    HStack {
                                        Text(author.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if filter.authorIDs.contains(author.id) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                            }
                        } label: {
                            filterSectionLabel("Authors", count: filter.authorIDs.count)
                        }
                    }
                }

                // Genres
                if !genres.isEmpty {
                    Section {
                        DisclosureGroup {
                            ForEach(genres) { genre in
                                Button {
                                    toggleID(genre.id, in: &filter.genreIDs)
                                } label: {
                                    HStack {
                                        Text(genre.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if filter.genreIDs.contains(genre.id) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                            }
                        } label: {
                            filterSectionLabel("Genres", count: filter.genreIDs.count)
                        }
                    }
                }

                // Tags
                if !tags.isEmpty {
                    Section {
                        DisclosureGroup {
                            ForEach(tags) { tag in
                                Button {
                                    toggleID(tag.id, in: &filter.tagIDs)
                                } label: {
                                    HStack {
                                        Circle()
                                            .fill(tag.colorHex.map { Color(hex: $0) } ?? .secondary)
                                            .frame(width: 10, height: 10)
                                        Text(tag.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if filter.tagIDs.contains(tag.id) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                            }
                        } label: {
                            filterSectionLabel("Tags", count: filter.tagIDs.count)
                        }
                    }
                }

                // Locations
                if !locations.isEmpty {
                    Section {
                        DisclosureGroup {
                            ForEach(locations) { location in
                                Button {
                                    toggleID(location.id, in: &filter.locationIDs)
                                } label: {
                                    HStack {
                                        Text(location.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if filter.locationIDs.contains(location.id) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                            }
                        } label: {
                            filterSectionLabel("Locations", count: filter.locationIDs.count)
                        }
                    }
                }

                // Reset
                if filter.isActive {
                    Section {
                        Button("Reset All Filters", role: .destructive) {
                            filter.reset()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filter Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func filterSectionLabel(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private func toggleReadStatus(_ status: ReadStatus) {
        if filter.readStatuses.contains(status) {
            filter.readStatuses.remove(status)
        } else {
            filter.readStatuses.insert(status)
        }
    }

    private func toggleID(_ id: UUID, in set: inout Set<UUID>) {
        if set.contains(id) {
            set.remove(id)
        } else {
            set.insert(id)
        }
    }
}
