import SwiftUI
import SwiftData

/// Detailed view for a single book
struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: Book

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with cover and basic info
                headerSection

                Divider()

                // Reading status and rating
                statusSection

                // Synopsis
                if let synopsis = book.synopsis, !synopsis.isEmpty {
                    synopsisSection(synopsis)
                }

                // Details
                detailsSection

                // Copies
                if !book.copies.isEmpty {
                    copiesSection
                }

                // Notes
                notesSection

                // Metadata
                metadataSection
            }
            .padding()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            BookEditView(book: book)
        }
        .confirmationDialog(
            "Delete Book",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(book)
            }
        } message: {
            Text("Are you sure you want to delete \"\(book.title)\"? This action cannot be undone.")
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Cover
            coverImage
                .frame(width: 120, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)

            // Basic info
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title2)
                    .fontWeight(.bold)

                if let subtitle = book.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(book.authorNames)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let seriesInfo = book.seriesInfo {
                    Text(seriesInfo)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                Spacer()

                if let publishYear = book.publishYear {
                    Text(publishYear)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var coverImage: some View {
        Group {
            if let coverData = book.coverData,
               let uiImage = UIImage(data: coverData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let coverURL = book.coverURL ?? book.openLibraryCoverURL {
                AsyncImage(url: coverURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderCover
                    @unknown default:
                        placeholderCover
                    }
                }
            } else {
                placeholderCover
            }
        }
    }

    private var placeholderCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))

            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Read status picker
            HStack {
                Text("Status")
                    .font(.headline)

                Spacer()

                Picker("Status", selection: $book.readStatus) {
                    ForEach(ReadStatus.allCases) { status in
                        Label(status.displayName, systemImage: status.systemImage)
                            .tag(status)
                    }
                }
                .pickerStyle(.menu)
            }

            // Rating
            HStack {
                Text("Rating")
                    .font(.headline)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Button {
                            if book.rating == index {
                                book.rating = nil
                            } else {
                                book.rating = index
                            }
                        } label: {
                            Image(systemName: (book.rating ?? 0) >= index ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle((book.rating ?? 0) >= index ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func synopsisSection(_ synopsis: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)

            Text(synopsis)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let publisher = book.publisher {
                    detailItem(label: "Publisher", value: publisher)
                }

                if let pageCount = book.pageCount {
                    detailItem(label: "Pages", value: "\(pageCount)")
                }

                if let isbn13 = book.isbn13 {
                    detailItem(label: "ISBN-13", value: isbn13)
                }

                if let isbn10 = book.isbn10 {
                    detailItem(label: "ISBN-10", value: isbn10)
                }

                if let language = book.language {
                    detailItem(label: "Language", value: language.uppercased())
                }
            }

            // Genres
            if !book.genres.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Genres")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(book.genres) { genre in
                            Text(genre.name)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Tags
            if !book.tags.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tags")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(book.tags) { tag in
                            Text(tag.name)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func detailItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var copiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Copies")
                .font(.headline)

            ForEach(book.copies) { copy in
                HStack {
                    Image(systemName: copy.format.systemImage)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading) {
                        Text(copy.format.displayName)
                            .font(.subheadline)

                        if let condition = copy.condition {
                            Text(condition.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if let location = copy.location {
                        Label(location.name, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)

            if let notes = book.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
            } else {
                Text("No notes yet")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Added \(book.dateAdded.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Modified \(book.dateModified.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookDetailView(book: .preview)
    }
    .modelContainer(.preview)
}
