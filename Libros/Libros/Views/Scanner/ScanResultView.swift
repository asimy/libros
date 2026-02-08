import SwiftUI
import SwiftData

/// Sheet displaying the result of a barcode scan — either a found book or a not-found state
struct ScanResultView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Author.sortName) private var existingAuthors: [Author]

    enum Mode {
        case found(OpenLibraryService.BookMetadata)
        case notFound(isbn: String)
    }

    let mode: Mode
    let onScanAgain: () -> Void
    let onEditManually: (String) -> Void
    var onBookAdded: (() -> Void)? = nil
    var onTryGuidedOCR: (() -> Void)? = nil
    var onTryQuickPhoto: (() -> Void)? = nil

    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .found(let metadata):
                    foundView(metadata)
                case .notFound(let isbn):
                    notFoundView(isbn)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Found View

    private func foundView(_ metadata: OpenLibraryService.BookMetadata) -> some View {
        VStack(spacing: 24) {
            // Cover image
            if let coverURL = metadata.coverURL {
                AsyncImage(url: coverURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)
            }

            // Book info
            VStack(spacing: 8) {
                Text(metadata.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if !metadata.authors.isEmpty {
                    Text(metadata.authors.map(\.name).joined(separator: ", "))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    if let publisher = metadata.publisher {
                        Label(publisher, systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let pages = metadata.pageCount {
                        Label("\(pages) pages", systemImage: "book.pages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    addToLibrary(metadata)
                } label: {
                    Label("Add to Library", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSaving)

                Button {
                    dismiss()
                    onEditManually(metadata.isbn13 ?? metadata.isbn10 ?? "")
                } label: {
                    Label("Edit First", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding()
        .navigationTitle("Book Found")
    }

    // MARK: - Not Found View

    private func notFoundView(_ isbn: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Book Not Found")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("No results for ISBN")
                    .foregroundStyle(.secondary)

                Text(ISBNValidator.formatISBN13(isbn))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    dismiss()
                    onEditManually(isbn)
                } label: {
                    Label("Enter Manually", systemImage: "keyboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    dismiss()
                    onScanAgain()
                } label: {
                    Label("Scan Again", systemImage: "barcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                if let onTryGuidedOCR {
                    Button {
                        dismiss()
                        onTryGuidedOCR()
                    } label: {
                        Label("Try Guided OCR", systemImage: "text.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                if let onTryQuickPhoto {
                    Button {
                        dismiss()
                        onTryQuickPhoto()
                    } label: {
                        Label("Quick Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
        .padding()
        .navigationTitle("Not Found")
    }

    // MARK: - Actions

    private func addToLibrary(_ metadata: OpenLibraryService.BookMetadata) {
        isSaving = true

        let book = Book(title: metadata.title, metadataSource: .openLibrary)
        book.subtitle = metadata.subtitle
        book.isbn13 = metadata.isbn13
        book.isbn10 = metadata.isbn10
        book.publisher = metadata.publisher
        book.pageCount = metadata.pageCount
        book.synopsis = metadata.synopsis
        book.coverURL = metadata.coverURL
        book.openLibraryWorkId = metadata.openLibraryWorkId
        book.openLibraryEditionId = metadata.openLibraryEditionId

        if let dateStr = metadata.publishDate {
            let pattern = #"\b(1[0-9]{3}|20[0-9]{2})\b"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: dateStr, range: NSRange(dateStr.startIndex..., in: dateStr)),
               let range = Range(match.range, in: dateStr),
               let year = Int(String(dateStr[range])) {
                var components = DateComponents()
                components.year = year
                components.month = 1
                components.day = 1
                book.publishDate = Calendar.current.date(from: components)
            }
        }

        // Handle authors
        var authors: [Author] = []
        for authorInfo in metadata.authors {
            if let existing = existingAuthors.first(where: { $0.name == authorInfo.name }) {
                authors.append(existing)
            } else {
                let newAuthor = Author(
                    name: authorInfo.name,
                    openLibraryId: authorInfo.openLibraryId
                )
                modelContext.insert(newAuthor)
                authors.append(newAuthor)
            }
        }
        book.authors = authors

        book.updateSearchableText()
        modelContext.insert(book)

        isSaving = false
        dismiss()
        onBookAdded?()
    }
}
