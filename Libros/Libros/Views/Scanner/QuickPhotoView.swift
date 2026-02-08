import SwiftUI
import SwiftData

/// Quick book entry: cover photo + minimal title/author form
struct QuickPhotoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Author.sortName) private var existingAuthors: [Author]

    var onComplete: (() -> Void)? = nil

    @State private var coverImage: UIImage?
    @State private var showingImagePicker = false
    @State private var title: String = ""
    @State private var authorNames: String = ""

    var body: some View {
        Form {
            // Cover photo section
            Section {
                if let coverImage {
                    HStack {
                        Spacer()
                        Image(uiImage: coverImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                    }

                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Retake", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Take Cover Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                }
            } header: {
                Text("Cover Photo")
            }

            // Book info
            Section("Book Information") {
                TextField("Title", text: $title)

                TextField("Author(s)", text: $authorNames)
            }

            // Save
            Section {
                Button {
                    saveBook()
                } label: {
                    Label("Save to Library", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Quick Photo")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingImagePicker) {
            ImagePicker(image: $coverImage)
        }
        .onAppear {
            showingImagePicker = true
        }
    }

    // MARK: - Actions

    private func saveBook() {
        let book = Book(title: title, metadataSource: .quickPhoto)

        // Cover image
        if let coverImage {
            book.coverData = coverImage.jpegData(compressionQuality: 0.8)
        }

        // Authors
        let names = authorNames
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var authors: [Author] = []
        for name in names {
            if let existing = existingAuthors.first(where: { $0.name == name }) {
                authors.append(existing)
            } else {
                let newAuthor = Author(name: name)
                modelContext.insert(newAuthor)
                authors.append(newAuthor)
            }
        }
        book.authors = authors

        book.updateSearchableText()
        modelContext.insert(book)

        onComplete?()
        dismiss()
    }
}
