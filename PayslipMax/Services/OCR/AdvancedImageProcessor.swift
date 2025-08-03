import UIKit
import Vision

/// Advanced image processor for optimal OCR preprocessing.
final class AdvancedImageProcessor {

    /// Optimizes an image for OCR by applying a series of preprocessing filters.
    ///
    /// - Parameter image: The input `UIImage`.
    /// - Returns: An optimized `UIImage` ready for OCR.
    func optimizeForOCR(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        // 1. Correct orientation
        let orientedImage = correctOrientation(image)

        // 2. Convert to grayscale
        guard let grayscaledImage = convertToGrayscale(orientedImage) else { return orientedImage }

        // 3. Increase contrast
        let contrastImage = increaseContrast(grayscaledImage)

        return contrastImage
    }

    /// Corrects the orientation of a `UIImage` to be `.up`.
    /// Vision framework performs best on correctly oriented images.
    private func correctOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? image
    }

    /// Converts a `UIImage` to grayscale.
    private func convertToGrayscale(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(data: nil,
                                width: cgImage.width,
                                height: cgImage.height,
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.none.rawValue)

        guard let cgContext = context else { return nil }
        let rect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        cgContext.draw(cgImage, in: rect)

        guard let grayscaleCgImage = cgContext.makeImage() else { return nil }
        return UIImage(cgImage: grayscaleCgImage)
    }

    /// Increases the contrast of a `UIImage` using Core Image filters.
    private func increaseContrast(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.5, forKey: kCIInputContrastKey) // Adjust contrast value as needed

        guard let outputImage = filter?.outputImage else { return image }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return image }

        return UIImage(cgImage: cgImage)
    }
}