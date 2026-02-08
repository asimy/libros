import SwiftUI
import SwiftData

/// View for adding or editing a book
struct BookEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Author.sortName) private var existingAuthors: [Author]
    @Query(sort: \Genre.name) private var existingGenres: [Genre]
    @Query(sort: \Tag.name) private var existingTags: [Tag]
    @Query(sort: \Series.name) private var existingSeries: [Series]
    @Query(sort: \Location.name) private var existingLocations: [Location]

    let book: Book?
    var initialISBN: String? = nil
    var isEmbedded: Bool = false

    // MARK: - Form State

    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var authorNames: String = ""  // Comma-separated for input
    @State private var isbn13: String = ""
    @State private var isbn10: String = ""
    @State private var publisher: String = ""
    @State private var publishYear: String = ""
    @State private var pageCount: String = ""
    @State private var language: String = ""
    @State private var synopsis: String = ""
    @State private var notes: String = ""
    @State private var readStatus: ReadStatus = .unread
    @State private var rating: Int?
    @State private var coverURL: URL?

    // MARK: - Relationship State

    @State private var selectedGenreIDs: Set<UUID> = []
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var selectedSeriesID: UUID?
    @State private var seriesOrderText: String = ""

    // MARK: - Lookup State

    @State private var isLookingUp = false
    @State private var lookupError: String?
    @State private var lookupSuccessInfo: String?

    // MARK: - Fetched Metadata (for creating authors)

    @State private var fetchedAuthors: [OpenLibraryService.BookMetadata.AuthorInfo] = []
    @State private var fetchedSubjects: [String] = []

    private var isNewBook: Bool { book == nil }

    var body: some View {
        if isEmbedded {
            editForm
        } else {
            NavigationStack {
                editForm
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                    }
            }
        }
    }

    private var editForm: some View {
        Form {
            // ISBN Section
            isbnSection

            // Book Info Section
            bookInfoSection

            // Authors Section
            authorsSection

            // Genres Section
            genresSection

            // Tags Section
            tagsSection

            // Series Section
            seriesSection

            // Publication Section
            publicationSection

            // Synopsis Section
            synopsisSection

            // Status Section
            statusSection

            // Notes Section
            notesSection

            // Copies Section
            copiesSection
        }
        .scrollContentBackground(.visible)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(isNewBook ? "Add Book" : "Edit Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveBook()
                }
                .disabled(title.isEmpty)
            }
        }
        .onAppear {
            loadBookData()
        }
    }

    // MARK: - Form Sections

    private var isbnSection: some View {
        Section {
            HStack {
                TextField("ISBN-13", text: $isbn13)
                    .keyboardType(.numberPad)
                    .textContentType(.none)
                    .autocorrectionDisabled()

                Button {
                    lookupISBN()
                } label: {
                    if isLookingUp {
                        ProgressView()
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .disabled(isbn13.isEmpty || isLookingUp)
            }

            TextField("ISBN-10", text: $isbn10)
                .keyboardType(.numberPad)
                .textContentType(.none)
                .autocorrectionDisabled()

            if let error = lookupError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let info = lookupSuccessInfo {
                Label(info, systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        } header: {
            Text("ISBN")
        } footer: {
            Text("Enter an ISBN and tap the search button to auto-fill from Open Library.")
        }
    }

    private var bookInfoSection: some View {
        Section("Book Information") {
            TextField("Title", text: $title)

            TextField("Subtitle", text: $subtitle)

            if let url = coverURL {
                HStack {
                    Text("Cover")
                        .foregroundStyle(.secondary)
                    Spacer()
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 50, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    private var authorsSection: some View {
        Section {
            TextField("Author(s)", text: $authorNames)
                .textContentType(.name)
        } header: {
            Text("Authors")
        } footer: {
            Text("Separate multiple authors with commas (e.g., \"Isaac Asimov, Robert Silverberg\")")
        }
    }

    private var publicationSection: some View {
        Section("Publication") {
            TextField("Publisher", text: $publisher)

            TextField("Year", text: $publishYear)
                .keyboardType(.numberPad)

            TextField("Pages", text: $pageCount)
                .keyboardType(.numberPad)

            TextField("Language (e.g., en, es, fr)", text: $language)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    private var synopsisSection: some View {
        Section("Synopsis") {
            TextEditor(text: $synopsis)
                .frame(minHeight: 100)
        }
    }

    private var statusSection: some View {
        Section("Reading Status") {
            Picker("Status", selection: $readStatus) {
                ForEach(ReadStatus.allCases) { status in
                    Label(status.displayName, systemImage: status.systemImage)
                        .tag(status)
                }
            }

            HStack {
                Text("Rating")

                Spacer()

                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Button {
                            if rating == index {
                                rating = nil
                            } else {
                                rating = index
                            }
                        } label: {
                            Image(systemName: (rating ?? 0) >= index ? "star.fill" : "star")
                                .foregroundStyle((rating ?? 0) >= index ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            MarkdownNotesView(text: $notes)
        }
    }

    private var genresSection: some View {
        Section("Genres") {
            if !selectedGenreIDs.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(existingGenres.filter { selectedGenreIDs.contains($0.id) }) { genre in
                        HStack(spacing: 4) {
                            Text(genre.name)
                            Button {
                                selectedGenreIDs.remove(genre.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    }
                }
            }

            NavigationLink {
                GenrePickerView(selectedGenreIDs: $selectedGenreIDs)
            } label: {
                Label("Select Genres", systemImage: "tag")
            }
        }
    }

    private var tagsSection: some View {
        Section("Tags") {
            if !selectedTagIDs.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(existingTags.filter { selectedTagIDs.contains($0.id) }) { tag in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(tag.colorHex.map { Color(hex: $0) } ?? .secondary)
                                .frame(width: 8, height: 8)
                            Text(tag.name)
                            Button {
                                selectedTagIDs.remove(tag.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                    }
                }
            }

            NavigationLink {
                TagPickerView(selectedTagIDs: $selectedTagIDs)
            } label: {
                Label("Select Tags", systemImage: "number")
            }
        }
    }

    private var seriesSection: some View {
        Section("Series") {
            Picker("Series", selection: $selectedSeriesID) {
                Text("None").tag(nil as UUID?)
                ForEach(existingSeries) { series in
                    Text(series.name).tag(series.id as UUID?)
                }
            }

            if selectedSeriesID != nil {
                TextField("Order in Series (e.g., 1)", text: $seriesOrderText)
                    .keyboardType(.numberPad)
            }
        }
    }

    private var copiesSection: some View {
        Section("My Copies") {
            if let book = book {
                ForEach(book.copies) { copy in
                    BookCopyEditView(copy: copy)
                }
                .onDelete { offsets in
                    for index in offsets {
                        let copy = book.copies[index]
                        modelContext.delete(copy)
                    }
                }
            }

            Button {
                addCopy()
            } label: {
                Label("Add Copy", systemImage: "plus.circle")
            }
        }
    }

    private func addCopy() {
        let copy = BookCopy(format: .paperback)
        modelContext.insert(copy)
        if let book = book {
            copy.book = book
        }
    }

    // MARK: - Data Methods

    private func loadBookData() {
        if let book = book {
            title = book.title
            subtitle = book.subtitle ?? ""
            authorNames = book.authors.map(\.name).joined(separator: ", ")
            isbn13 = book.isbn13 ?? ""
            isbn10 = book.isbn10 ?? ""
            publisher = book.publisher ?? ""
            publishYear = book.publishYear ?? ""
            pageCount = book.pageCount.map { String($0) } ?? ""
            language = book.language ?? ""
            synopsis = book.synopsis ?? ""
            notes = book.notes ?? ""
            readStatus = book.readStatus
            rating = book.rating
            coverURL = book.coverURL

            // Relationships
            selectedGenreIDs = Set(book.genres.map(\.id))
            selectedTagIDs = Set(book.tags.map(\.id))
            selectedSeriesID = book.series?.id
            seriesOrderText = book.seriesOrder.map { String($0) } ?? ""
        } else if let initialISBN, !initialISBN.isEmpty {
            isbn13 = initialISBN
            lookupISBN()
        }
    }

    private func saveBook() {
        let targetBook: Book
        if let existing = book {
            targetBook = existing
        } else {
            targetBook = Book(title: title)
            modelContext.insert(targetBook)
        }

        // Basic fields
        targetBook.title = title
        targetBook.subtitle = subtitle.isEmpty ? nil : subtitle
        targetBook.isbn13 = isbn13.isEmpty ? nil : isbn13
        targetBook.isbn10 = isbn10.isEmpty ? nil : isbn10
        targetBook.publisher = publisher.isEmpty ? nil : publisher
        targetBook.pageCount = Int(pageCount)
        targetBook.language = language.isEmpty ? nil : language
        targetBook.synopsis = synopsis.isEmpty ? nil : synopsis
        targetBook.notes = notes.isEmpty ? nil : notes
        targetBook.readStatus = readStatus
        targetBook.rating = rating
        targetBook.coverURL = coverURL
        targetBook.dateModified = Date()

        // Parse publish year to date
        if let year = Int(publishYear) {
            var components = DateComponents()
            components.year = year
            components.month = 1
            components.day = 1
            targetBook.publishDate = Calendar.current.date(from: components)
        }

        // Handle authors
        updateAuthors(for: targetBook)

        // Handle genres
        targetBook.genres = existingGenres.filter { selectedGenreIDs.contains($0.id) }

        // Handle tags
        targetBook.tags = existingTags.filter { selectedTagIDs.contains($0.id) }

        // Handle series
        if let seriesID = selectedSeriesID {
            targetBook.series = existingSeries.first { $0.id == seriesID }
            targetBook.seriesOrder = Int(seriesOrderText)
        } else {
            targetBook.series = nil
            targetBook.seriesOrder = nil
        }

        targetBook.updateSearchableText()

        dismiss()
    }

    private func updateAuthors(for book: Book) {
        // Parse comma-separated author names
        let names = authorNames
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var authors: [Author] = []

        for name in names {
            // Check if we have metadata for this author from the API
            let apiAuthor = fetchedAuthors.first { $0.name == name }

            // Look for existing author with same name
            if let existing = existingAuthors.first(where: { $0.name == name }) {
                authors.append(existing)
            } else {
                // Create new author
                let newAuthor = Author(
                    name: name,
                    openLibraryId: apiAuthor?.openLibraryId
                )
                modelContext.insert(newAuthor)
                authors.append(newAuthor)
            }
        }

        book.authors = authors
    }

    // MARK: - API Lookup

    private func lookupISBN() {
        guard !isbn13.isEmpty else { return }

        if !NetworkMonitor.shared.isConnected {
            lookupError = "You're offline. ISBN lookup requires an internet connection."
            return
        }

        isLookingUp = true
        lookupError = nil
        lookupSuccessInfo = nil

        Task {
            do {
                let service = OpenLibraryService()
                let metadata = try await service.lookupByISBN(isbn13)

                await MainActor.run {
                    // Basic info
                    title = metadata.title
                    subtitle = metadata.subtitle ?? ""
                    publisher = metadata.publisher ?? ""
                    synopsis = metadata.synopsis ?? ""

                    // Authors
                    fetchedAuthors = metadata.authors
                    authorNames = metadata.authors.map(\.name).joined(separator: ", ")

                    // Publication info
                    if let pages = metadata.pageCount {
                        pageCount = String(pages)
                    }

                    if let dateStr = metadata.publishDate {
                        // Try to extract year from various formats
                        publishYear = extractYear(from: dateStr)
                    }

                    // ISBNs
                    if let isbn = metadata.isbn13 {
                        isbn13 = isbn
                    }
                    if let isbn = metadata.isbn10 {
                        isbn10 = isbn
                    }

                    // Cover
                    coverURL = metadata.coverURL

                    // Subjects (for future genre mapping)
                    fetchedSubjects = metadata.subjects

                    // Success message
                    var infoItems: [String] = []
                    if !metadata.authors.isEmpty {
                        infoItems.append("\(metadata.authors.count) author(s)")
                    }
                    if metadata.pageCount != nil {
                        infoItems.append("page count")
                    }
                    if metadata.coverURL != nil {
                        infoItems.append("cover image")
                    }
                    if !metadata.subjects.isEmpty {
                        infoItems.append("\(metadata.subjects.count) subjects")
                    }

                    lookupSuccessInfo = "Found: \(infoItems.joined(separator: ", "))"
                    isLookingUp = false
                }
            } catch {
                await MainActor.run {
                    lookupError = error.localizedDescription
                    isLookingUp = false
                }
            }
        }
    }

    /// Extracts a 4-digit year from various date formats
    private func extractYear(from dateString: String) -> String {
        // Try to find a 4-digit year
        let pattern = #"\b(1[0-9]{3}|20[0-9]{2})\b"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: dateString, range: NSRange(dateString.startIndex..., in: dateString)),
           let range = Range(match.range, in: dateString) {
            return String(dateString[range])
        }
        return ""
    }
}

// MARK: - Preview

#Preview("Add Book") {
    BookEditView(book: nil)
        .modelContainer(.preview)
}

#Preview("Edit Book") {
    BookEditView(book: .preview)
        .modelContainer(.preview)
}
