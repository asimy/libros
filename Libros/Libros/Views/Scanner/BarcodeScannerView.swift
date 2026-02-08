import SwiftUI
import SwiftData
import AVFoundation

/// Main barcode scanner view with camera preview, permission handling, and scan-to-add flow
struct BarcodeScannerView: View {
    @Environment(\.modelContext) private var modelContext

    /// When true, skip the NavigationStack wrapper (AddBookView provides it)
    var isEmbedded: Bool = false

    /// Called when a book is successfully added (to dismiss the entire AddBookView)
    var onBookAdded: (() -> Void)? = nil

    /// Called when user wants to switch to a different add method from not-found state
    var onSwitchMethod: ((AddBookView.Destination) -> Void)? = nil

    // MARK: - State

    enum ScanState: Equatable {
        case scanning
        case processing(isbn: String)
        case found(OpenLibraryService.BookMetadata)
        case notFound(isbn: String)
        case error(String)

        static func == (lhs: ScanState, rhs: ScanState) -> Bool {
            switch (lhs, rhs) {
            case (.scanning, .scanning):
                return true
            case (.processing(let a), .processing(let b)):
                return a == b
            case (.found(let a), .found(let b)):
                return a.title == b.title && a.isbn13 == b.isbn13
            case (.notFound(let a), .notFound(let b)):
                return a == b
            case (.error(let a), .error(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    enum CameraPermission {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    @State private var scanState: ScanState = .scanning
    @State private var cameraPermission: CameraPermission = .notDetermined
    @State private var isSessionRunning = true
    @State private var isTorchOn = false
    @State private var showResultSheet = false
    @State private var showEditSheet = false
    @State private var editISBN: String?
    @State private var scanMode: ScanMode = .barcode
    @State private var ocrConfirmationBuffer: [String] = []

    var body: some View {
        if isEmbedded {
            scannerContent
        } else {
            NavigationStack {
                scannerContent
            }
        }
    }

    private var scannerContent: some View {
        ZStack {
            switch cameraPermission {
            case .notDetermined:
                permissionRequestView
            case .authorized:
                scannerView
            case .denied:
                permissionDeniedView
            case .restricted:
                permissionDeniedView
            }
        }
        .navigationTitle("ISBN Lookup")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkCameraPermission()
        }
        .sheet(isPresented: $showResultSheet, onDismiss: {
            resetToScanning()
        }) {
            resultSheet
        }
        .sheet(isPresented: $showEditSheet) {
            BookEditView(book: nil, initialISBN: editISBN)
        }
    }

    // MARK: - Permission Request

    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("Libros needs camera access to scan book barcodes. Your camera is only used for scanning — no images are stored.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button("Enable Camera") {
                requestCameraPermission()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()

            manualEntryButton
        }
        .padding()
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Camera Access Denied")
                .font(.title2)
                .fontWeight(.bold)

            Text("To scan barcodes, enable camera access in Settings > Libros > Camera.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()

            manualEntryButton
        }
        .padding()
    }

    // MARK: - Scanner View

    private var scannerView: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(
                onBarcodeDetected: handleBarcodeDetected,
                onTextRecognized: handleTextRecognized,
                isRunning: $isSessionRunning,
                isTorchOn: $isTorchOn,
                scanMode: $scanMode
            )
            .ignoresSafeArea()

            // Scan overlay
            VStack {
                Spacer()

                // Scan region indicator
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.8), lineWidth: 2)
                    .frame(width: 280, height: scanMode == .barcode ? 160 : 280)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.1))
                    )
                    .animation(.easeInOut(duration: 0.3), value: scanMode)

                Spacer()

                // Status bar
                VStack(spacing: 12) {
                    statusText

                    Picker("Scan Mode", selection: $scanMode) {
                        ForEach(ScanMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: scanMode) {
                        ocrConfirmationBuffer.removeAll()
                    }

                    HStack(spacing: 24) {
                        // Torch toggle
                        Button {
                            isTorchOn.toggle()
                        } label: {
                            Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }

                        // Manual entry
                        Button {
                            editISBN = nil
                            showEditSheet = true
                        } label: {
                            Image(systemName: "keyboard")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var statusText: some View {
        Group {
            switch scanState {
            case .scanning:
                Text(scanMode == .barcode
                     ? "Point camera at a book barcode"
                     : "Point camera at ISBN text on a book")
                    .foregroundStyle(.white)
            case .processing(let isbn):
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text("Looking up ISBN \(isbn)...")
                        .foregroundStyle(.white)
                }
            case .error(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.yellow)
            default:
                EmptyView()
            }
        }
        .font(.subheadline)
    }

    // MARK: - Result Sheet

    @ViewBuilder
    private var resultSheet: some View {
        switch scanState {
        case .found(let metadata):
            ScanResultView(
                mode: .found(metadata),
                onScanAgain: { resetToScanning() },
                onEditManually: { isbn in
                    editISBN = isbn
                    showEditSheet = true
                },
                onBookAdded: onBookAdded
            )
        case .notFound(let isbn):
            ScanResultView(
                mode: .notFound(isbn: isbn),
                onScanAgain: { resetToScanning() },
                onEditManually: { isbn in
                    editISBN = isbn
                    showEditSheet = true
                },
                onTryGuidedOCR: onSwitchMethod != nil ? {
                    showResultSheet = false
                    onSwitchMethod?(.guidedOCR)
                } : nil,
                onTryQuickPhoto: onSwitchMethod != nil ? {
                    showResultSheet = false
                    onSwitchMethod?(.quickPhoto)
                } : nil
            )
        default:
            EmptyView()
        }
    }

    // MARK: - Manual Entry Button

    private var manualEntryButton: some View {
        Button {
            editISBN = nil
            showEditSheet = true
        } label: {
            Label("Enter ISBN Manually", systemImage: "keyboard")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .padding(.bottom)
    }

    // MARK: - Actions

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            cameraPermission = .notDetermined
        case .authorized:
            cameraPermission = .authorized
        case .denied:
            cameraPermission = .denied
        case .restricted:
            cameraPermission = .restricted
        @unknown default:
            cameraPermission = .denied
        }
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            cameraPermission = granted ? .authorized : .denied
        }
    }

    private func handleBarcodeDetected(_ code: String) {
        guard scanState == .scanning else { return }

        // Validate via ISBNValidator
        guard let isbn = ISBNValidator.parse(code) else {
            return
        }

        lookupISBN(isbn.isbn13)
    }

    private func handleTextRecognized(_ text: String) {
        guard scanState == .scanning, scanMode == .ocr else { return }

        guard let isbn = ISBNParser.extractISBN(from: text) else {
            // No ISBN found in this frame — reset buffer
            ocrConfirmationBuffer.removeAll()
            return
        }

        let isbn13 = isbn.isbn13

        // Stabilization: require 3 consecutive frames to agree on the same ISBN
        if let lastISBN = ocrConfirmationBuffer.last, lastISBN != isbn13 {
            // Different ISBN detected — reset buffer
            ocrConfirmationBuffer.removeAll()
        }

        ocrConfirmationBuffer.append(isbn13)

        if ocrConfirmationBuffer.count >= 3 {
            ocrConfirmationBuffer.removeAll()
            lookupISBN(isbn13)
        }
    }

    private func lookupISBN(_ isbn13: String) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Pause scanning
        isSessionRunning = false
        scanState = .processing(isbn: isbn13)

        // Look up the book
        Task {
            do {
                let service = OpenLibraryService()
                let metadata = try await service.lookupByISBN(isbn13)
                scanState = .found(metadata)
                showResultSheet = true
            } catch let error as OpenLibraryService.ServiceError where error == .notFound {
                scanState = .notFound(isbn: isbn13)
                showResultSheet = true
            } catch {
                scanState = .error(error.localizedDescription)
                // Auto-reset after a delay
                try? await Task.sleep(for: .seconds(2))
                resetToScanning()
            }
        }
    }

    private func resetToScanning() {
        scanState = .scanning
        isSessionRunning = true
        showResultSheet = false
        ocrConfirmationBuffer.removeAll()
    }
}

// MARK: - ServiceError Equatable

extension OpenLibraryService.ServiceError: Equatable {
    public static func == (lhs: OpenLibraryService.ServiceError, rhs: OpenLibraryService.ServiceError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}

// MARK: - Preview

#Preview {
    BarcodeScannerView()
        .modelContainer(.preview)
}
