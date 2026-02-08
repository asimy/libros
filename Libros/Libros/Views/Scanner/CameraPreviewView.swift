import SwiftUI
import AVFoundation
import Vision

/// UIViewRepresentable that wraps AVCaptureSession with a preview layer, barcode detection, and OCR text recognition
struct CameraPreviewView: UIViewRepresentable {
    let onBarcodeDetected: (String) -> Void
    let onTextRecognized: (String) -> Void
    @Binding var isRunning: Bool
    @Binding var isTorchOn: Bool
    @Binding var scanMode: ScanMode

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if isRunning {
            uiView.startSession()
        } else {
            uiView.stopSession()
        }

        uiView.setTorch(isTorchOn)
        uiView.setScanMode(scanMode)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeDetected: onBarcodeDetected, onTextRecognized: onTextRecognized)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
        let onBarcodeDetected: (String) -> Void
        let onTextRecognized: (String) -> Void

        // Barcode debounce state — only accessed from main queue (metadata delegate queue)
        nonisolated(unsafe) private var lastDetectedCode: String?
        nonisolated(unsafe) private var lastDetectionTime: Date = .distantPast

        // OCR throttle state — only accessed from videoDataQueue
        nonisolated(unsafe) private var lastOCRProcessTime: Date = .distantPast
        nonisolated(unsafe) private var isProcessingOCR = false

        init(onBarcodeDetected: @escaping (String) -> Void, onTextRecognized: @escaping (String) -> Void) {
            self.onBarcodeDetected = onBarcodeDetected
            self.onTextRecognized = onTextRecognized
        }

        // MARK: - AVCaptureMetadataOutputObjectsDelegate

        nonisolated func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let stringValue = metadataObject.stringValue else {
                return
            }

            // Debounce: ignore same barcode within 1 second
            let now = Date()
            if stringValue == lastDetectedCode,
               now.timeIntervalSince(lastDetectionTime) < 1.0 {
                return
            }

            lastDetectedCode = stringValue
            lastDetectionTime = now

            Task { @MainActor in
                onBarcodeDetected(stringValue)
            }
        }

        // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

        nonisolated func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            // Throttle: skip frames if processed too recently
            let now = Date()
            guard now.timeIntervalSince(lastOCRProcessTime) >= 0.25 else { return }

            // Skip if still processing previous frame
            guard !isProcessingOCR else { return }

            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            isProcessingOCR = true
            lastOCRProcessTime = now

            let request = VNRecognizeTextRequest { [weak self] request, error in
                defer { self?.isProcessingOCR = false }

                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }

                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                guard !recognizedText.isEmpty else { return }

                let callback = self?.onTextRecognized
                Task { @MainActor in
                    callback?(recognizedText)
                }
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en"]
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
            do {
                try handler.perform([request])
            } catch {
                isProcessingOCR = false
            }
        }
    }

    // MARK: - Preview UIView

    class PreviewUIView: UIView {
        weak var delegate: Coordinator?

        private var captureSession: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var isSessionConfigured = false

        private var metadataOutput: AVCaptureMetadataOutput?
        private var videoDataOutput: AVCaptureVideoDataOutput?
        private let videoDataQueue = DispatchQueue(label: "com.libros.videoDataQueue", qos: .userInitiated)
        private var currentScanMode: ScanMode = .barcode

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        private var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            // swiftlint:disable:next force_cast
            layer as! AVCaptureVideoPreviewLayer
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            if superview != nil {
                configureSessionIfNeeded()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
        }

        func startSession() {
            guard let session = captureSession, !session.isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }

        func stopSession() {
            guard let session = captureSession, session.isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }

        func setTorch(_ on: Bool) {
            guard let device = AVCaptureDevice.default(for: .video),
                  device.hasTorch else { return }
            try? device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        }

        func setScanMode(_ mode: ScanMode) {
            guard mode != currentScanMode else { return }
            currentScanMode = mode

            switch mode {
            case .barcode:
                videoDataOutput?.setSampleBufferDelegate(nil, queue: nil)
            case .ocr:
                videoDataOutput?.setSampleBufferDelegate(delegate, queue: videoDataQueue)
            }
        }

        private func configureSessionIfNeeded() {
            guard !isSessionConfigured else { return }
            isSessionConfigured = true

            let session = AVCaptureSession()
            session.sessionPreset = .high

            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                return
            }

            guard session.canAddInput(videoInput) else { return }
            session.addInput(videoInput)

            // Metadata output for barcode detection
            let metadata = AVCaptureMetadataOutput()
            guard session.canAddOutput(metadata) else { return }
            session.addOutput(metadata)

            metadata.setMetadataObjectsDelegate(delegate, queue: .main)

            // Filter to only supported barcode types that are available
            let desiredTypes: [AVMetadataObject.ObjectType] = [.ean13, .upce]
            metadata.metadataObjectTypes = desiredTypes.filter {
                metadata.availableMetadataObjectTypes.contains($0)
            }

            self.metadataOutput = metadata

            // Video data output for OCR text recognition
            let videoData = AVCaptureVideoDataOutput()
            videoData.alwaysDiscardsLateVideoFrames = true
            if session.canAddOutput(videoData) {
                session.addOutput(videoData)
                // Start with delegate set to nil (barcode mode default)
                videoData.setSampleBufferDelegate(nil, queue: nil)
                self.videoDataOutput = videoData
            }

            videoPreviewLayer.session = session
            videoPreviewLayer.videoGravity = .resizeAspectFill

            captureSession = session

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }
}
