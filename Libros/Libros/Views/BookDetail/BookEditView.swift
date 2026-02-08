import SwiftUI
import SwiftData

/// View for adding or editing a book
struct BookEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Author.sortName) private var existingAuthors: [Author]

    let book: Book?

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

    // MARK: - Lookup State

    @State private var isLookingUp = false
    @State private var lookupError: String?
    @State private var lookupSuccessInfo: String?

    // MARK: - Fetched Metadata (for creating authors)

    @State private var fetchedAuthors: [OpenLibraryService.BookMetadata.AuthorInfo] = []
    @State private var fetchedSubjects: [String] = []

    private var isNewBook: Bool { book == nil }

    var body: some View {
        NavigationStack {
            Form {
                // ISBN Section
                isbnSection

                // Book Info Section
                bookInfoSection

                // Authors Section
                authorsSection

                // Publication Section
                publicationSection

                // Synopsis Section
                synopsisSection

                // Status Section
                statusSection

                // Notes Section
                notesSection
            }
            .scrollContentBackground(.visible)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isNewBook ? "Add Book" : "Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

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
            TextEditor(text: $notes)
                .frame(minHeight: 80)
        }
    }

    // MARK: - Data Methods

    private func loadBookData() {
        guard let book = book else { return }

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
