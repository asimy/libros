import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// Processes captured book cover images with perspective correction and background removal
enum CoverImageProcessor {

    /// Processes a book cover photo: perspective correction -> background removal -> final result
    static func process(_ image: UIImage) async -> UIImage {
        var result = image

        // Step 1: Perspective correction
        if let corrected = await correctPerspective(result) {
            result = corrected
        }

        // Step 2: Background removal
        if let masked = await removeBackground(result) {
            result = masked
        }

        return result
    }

    // MARK: - Perspective Correction

    private static func correctPerspective(_ image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.2
        request.minimumConfidence = 0.6
        request.maximumObservations = 1

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observation = request.results?.first else { return nil }

        let ciImage = CIImage(cgImage: cgImage)
        let imageSize = ciImage.extent.size

        // Convert normalized Vision coordinates to CIImage coordinates
        let topLeft = CGPoint(
            x: observation.topLeft.x * imageSize.width,
            y: observation.topLeft.y * imageSize.height
        )
        let topRight = CGPoint(
            x: observation.topRight.x * imageSize.width,
            y: observation.topRight.y * imageSize.height
        )
        let bottomLeft = CGPoint(
            x: observation.bottomLeft.x * imageSize.width,
            y: observation.bottomLeft.y * imageSize.height
        )
        let bottomRight = CGPoint(
            x: observation.bottomRight.x * imageSize.width,
            y: observation.bottomRight.y * imageSize.height
        )

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = ciImage
        filter.topLeft = topLeft
        filter.topRight = topRight
        filter.bottomLeft = bottomLeft
        filter.bottomRight = bottomRight

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext()
        guard let cgResult = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgResult, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Background Removal

    private static func removeBackground(_ image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let result = request.results?.first else { return nil }

        do {
            let maskPixelBuffer = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )

            let ciMask = CIImage(cvPixelBuffer: maskPixelBuffer)
            let ciImage = CIImage(cgImage: cgImage)

            // Composite foreground over white background
            let whiteBackground = CIImage(color: .white).cropped(to: ciImage.extent)

            let blendFilter = CIFilter.blendWithMask()
            blendFilter.inputImage = ciImage
            blendFilter.backgroundImage = whiteBackground
            blendFilter.maskImage = ciMask.transformed(
                by: CGAffineTransform(
                    scaleX: ciImage.extent.width / ciMask.extent.width,
                    y: ciImage.extent.height / ciMask.extent.height
                )
            )

            guard let outputImage = blendFilter.outputImage else { return nil }

            let context = CIContext()
            guard let cgResult = context.createCGImage(outputImage, from: outputImage.extent) else {
                return nil
            }

            return UIImage(cgImage: cgResult, scale: image.scale, orientation: image.imageOrientation)
        } catch {
            return nil
        }
    }
}
