import SwiftUI
import SwiftData

/// Multi-step wizard for extracting book metadata via OCR from physical book pages
struct GuidedOCRView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Author.sortName) private var existingAuthors: [Author]

    var onComplete: (() -> Void)? = nil

    // MARK: - Step State Machine

    enum Step: Int, CaseIterable {
        case coverPhoto     // Step 1
        case titlePage      // Step 2
        case copyrightPage  // Step 3
        case backCover      // Step 4
        case review         // Step 5

        var title: String {
            switch self {
            case .coverPhoto: return "Cover Photo"
            case .titlePage: return "Title Page"
            case .copyrightPage: return "Copyright Page"
            case .backCover: return "Back Cover"
            case .review: return "Review"
            }
        }

        var isOCRStep: Bool {
            switch self {
            case .titlePage, .copyrightPage, .backCover: return true
            default: return false
            }
        }
    }

    // MARK: - State

    @State private var currentStep: Step = .coverPhoto
    @State private var coverImage: UIImage?
    @State private var rawCoverImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isProcessingCover = false

    // OCR state
    @State private var capturedOCRText: String = ""
    @State private var titlePageText: String = ""
    @State private var copyrightPageText: String = ""
    @State private var backCoverText: String = ""

    // Extracted metadata
    @State private var extractedMetadata: ExtractedMetadata = .empty

    // Review form fields
    @State private var formTitle: String = ""
    @State private var formSubtitle: String = ""
    @State private var formAuthors: String = ""
    @State private var formPublisher: String = ""
    @State private var formPublishYear: String = ""
    @State private var formISBN: String = ""
    @State private var formSynopsis: String = ""

    // Camera state
    @State private var isSessionRunning = false
    @State private var isTorchOn = false
    @State private var scanMode: ScanMode = .ocr

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressBar
                .padding(.horizontal)
                .padding(.top, 8)

            // Step content
            Group {
                switch currentStep {
                case .coverPhoto:
                    coverPhotoStep
                case .titlePage, .copyrightPage, .backCover:
                    ocrStep
                case .review:
                    reviewStep
                }
            }
        }
        .navigationTitle(currentStep.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingImagePicker) {
            ImagePicker(image: $rawCoverImage)
        }
        .onChange(of: rawCoverImage) { _, newImage in
            guard let newImage else { return }
            isProcessingCover = true
            Task {
                let processed = await CoverImageProcessor.process(newImage)
                await MainActor.run {
                    coverImage = processed
                    isProcessingCover = false
                }
            }
        }
        .onAppear {
            showingImagePicker = true
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(Step.allCases, id: \.rawValue) { step in
                Button {
                    if step.rawValue < currentStep.rawValue {
                        goToStep(step)
                    }
                } label: {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
                .disabled(step.rawValue >= currentStep.rawValue)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Cover Photo Step

    private var coverPhotoStep: some View {
        VStack(spacing: 24) {
            Spacer()

            if isProcessingCover {
                ProgressView("Processing cover...")
                    .frame(maxHeight: 300)
            } else if let coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)

                HStack(spacing: 16) {
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Retake", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        advanceStep()
                    } label: {
                        Label("Next", systemImage: "arrow.right")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Image(systemName: "camera")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("Take a photo of the book cover")
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Open Camera", systemImage: "camera")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        advanceStep()
                    } label: {
                        Text("Skip")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - OCR Step

    private var ocrStep: some View {
        VStack(spacing: 0) {
            // Camera preview
            CameraPreviewView(
                onBarcodeDetected: { _ in },
                onTextRecognized: { text in
                    capturedOCRText = text
                },
                isRunning: $isSessionRunning,
                isTorchOn: $isTorchOn,
                scanMode: $scanMode
            )
            .frame(maxHeight: .infinity)
            .onAppear {
                scanMode = .ocr
                isSessionRunning = true
                capturedOCRText = ""
            }
            .onDisappear {
                isSessionRunning = false
            }

            // Recognized text and controls
            VStack(spacing: 12) {
                ScrollView {
                    Text(capturedOCRText.isEmpty ? "Point camera at the \(currentStep.title.lowercased())..." : capturedOCRText)
                        .font(.caption)
                        .foregroundStyle(capturedOCRText.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 80)

                HStack(spacing: 12) {
                    Button {
                        goBack()
                    } label: {
                        Label("Back", systemImage: "arrow.left")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        advanceStep()
                    } label: {
                        Text(currentStep == .backCover ? "Skip (Optional)" : "Skip")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        captureCurrentText()
                        advanceStep()
                    } label: {
                        Label("Use This Text", systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(capturedOCRText.isEmpty)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Review Step

    private var reviewStep: some View {
        Form {
            if let coverImage {
                Section {
                    HStack {
                        Spacer()
                        Image(uiImage: coverImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                    }
                }
            }

            Section("Book Information") {
                TextField("Title", text: $formTitle)
                TextField("Subtitle", text: $formSubtitle)
            }

            Section {
                TextField("Author(s)", text: $formAuthors)
            } header: {
                Text("Authors")
            } footer: {
                Text("Separate multiple authors with commas")
            }

            Section("Publication") {
                TextField("Publisher", text: $formPublisher)
                TextField("Year", text: $formPublishYear)
                    .keyboardType(.numberPad)
                TextField("ISBN", text: $formISBN)
                    .keyboardType(.numberPad)
            }

            Section("Synopsis") {
                TextEditor(text: $formSynopsis)
                    .frame(minHeight: 80)
            }

            Section {
                Button {
                    goBack()
                } label: {
                    Label("Back to Scanning", systemImage: "arrow.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    saveBook()
                } label: {
                    Label("Save to Library", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(formTitle.isEmpty)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            populateFormFromMetadata()
        }
    }

    // MARK: - Actions

    private func advanceStep() {
        guard let nextIndex = Step.allCases.firstIndex(of: currentStep)?.advanced(by: 1),
              nextIndex < Step.allCases.count else { return }

        // Stop camera before advancing
        if currentStep.isOCRStep {
            isSessionRunning = false
        }

        currentStep = Step.allCases[nextIndex]
    }

    private func goBack() {
        guard let prevIndex = Step.allCases.firstIndex(of: currentStep)?.advanced(by: -1),
              prevIndex >= 0 else { return }

        if currentStep.isOCRStep {
            isSessionRunning = false
        }

        let target = Step.allCases[prevIndex]
        goToStep(target)
    }

    private func goToStep(_ step: Step) {
        if currentStep.isOCRStep {
            isSessionRunning = false
        }

        currentStep = step

        // Restore previously captured text for OCR steps
        switch step {
        case .titlePage:
            capturedOCRText = titlePageText
        case .copyrightPage:
            capturedOCRText = copyrightPageText
        case .backCover:
            capturedOCRText = backCoverText
        default:
            capturedOCRText = ""
        }
    }

    private func captureCurrentText() {
        switch currentStep {
        case .titlePage:
            titlePageText = capturedOCRText
            let titleMeta = BookMetadataExtractor.extractFromTitlePage(capturedOCRText)
            extractedMetadata = extractedMetadata.merging(with: titleMeta)
        case .copyrightPage:
            copyrightPageText = capturedOCRText
            let copyrightMeta = BookMetadataExtractor.extractFromCopyrightPage(capturedOCRText)
            extractedMetadata = extractedMetadata.merging(with: copyrightMeta)
        case .backCover:
            backCoverText = capturedOCRText
            let backMeta = BookMetadataExtractor.extractFromBackCover(capturedOCRText)
            extractedMetadata = extractedMetadata.merging(with: backMeta)
        default:
            break
        }
        capturedOCRText = ""
    }

    private func populateFormFromMetadata() {
        formTitle = extractedMetadata.title ?? ""
        formSubtitle = extractedMetadata.subtitle ?? ""
        formAuthors = extractedMetadata.authors.joined(separator: ", ")
        formPublisher = extractedMetadata.publisher ?? ""
        formPublishYear = extractedMetadata.publishYear.map { String($0) } ?? ""
        formISBN = extractedMetadata.isbn ?? ""
        formSynopsis = extractedMetadata.synopsis ?? ""
    }

    private func saveBook() {
        let book = Book(title: formTitle, metadataSource: .ocrExtraction)
        book.subtitle = formSubtitle.isEmpty ? nil : formSubtitle
        book.publisher = formPublisher.isEmpty ? nil : formPublisher
        book.synopsis = formSynopsis.isEmpty ? nil : formSynopsis

        // ISBN
        if !formISBN.isEmpty {
            if formISBN.count == 13 {
                book.isbn13 = formISBN
            } else if formISBN.count == 10 {
                book.isbn10 = formISBN
            }
        }

        // Publish year
        if let year = Int(formPublishYear) {
            var components = DateComponents()
            components.year = year
            components.month = 1
            components.day = 1
            book.publishDate = Calendar.current.date(from: components)
        }

        // Cover image
        if let coverImage {
            book.coverData = coverImage.jpegData(compressionQuality: 0.8)
        }

        // Authors
        let names = formAuthors
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
