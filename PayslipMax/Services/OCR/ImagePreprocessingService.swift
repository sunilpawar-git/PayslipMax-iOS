import Foundation
import UIKit
import CoreImage

public protocol ImagePreprocessingServiceProtocol {
    func preprocess(_ image: UIImage) -> UIImage
}

public final class ImagePreprocessingService: ImagePreprocessingServiceProtocol {
    private let ciContext: CIContext

    public init(ciContext: CIContext = CIContext(options: [.useSoftwareRenderer: false])) {
        self.ciContext = ciContext
    }

    public func preprocess(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        // Pipeline: grayscale -> contrast boost -> sharpen -> pseudo-binarize
        let grayscaled = applyGrayscale(to: ciImage)
        let highContrast = applyContrast(to: grayscaled, contrast: 1.35, brightness: 0.0)
        let sharpened = applySharpen(to: highContrast, radius: 1.2, intensity: 0.8)
        let binarized = applyPseudoBinarization(to: sharpened, threshold: 0.55)

        return render(ciImage: binarized, size: image.size) ?? image
    }

    private func applyGrayscale(to image: CIImage) -> CIImage {
        let params: [String: Any] = [kCIInputImageKey: image]
        let filter = CIFilter(name: "CIPhotoEffectNoir", parameters: params) ?? CIFilter(name: "CIColorControls", parameters: [kCIInputImageKey: image, kCIInputSaturationKey: 0.0])
        return filter?.outputImage ?? image
    }

    private func applyContrast(to image: CIImage, contrast: CGFloat, brightness: CGFloat) -> CIImage {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        return filter?.outputImage ?? image
    }

    private func applySharpen(to image: CIImage, radius: CGFloat, intensity: CGFloat) -> CIImage {
        let filter = CIFilter(name: "CIUnsharpMask")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        filter?.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter?.outputImage ?? image
    }

    private func applyPseudoBinarization(to image: CIImage, threshold: CGFloat) -> CIImage {
        // Approximate binarization: clamp then increase contrast significantly
        let clamped = CIFilter(name: "CIColorClamp", parameters: [
            kCIInputImageKey: image,
            "inputMinComponents": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputMaxComponents": CIVector(x: 1, y: 1, z: 1, w: 1)
        ])?.outputImage ?? image

        // Map around threshold by applying a strong gamma via color controls
        let gammaFilter = CIFilter(name: "CIToneCurve")
        gammaFilter?.setValue(clamped, forKey: kCIInputImageKey)
        // Emphasize contrast around the threshold
        gammaFilter?.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0")
        gammaFilter?.setValue(CIVector(x: max(0.0, threshold - 0.2), y: 0.0), forKey: "inputPoint1")
        gammaFilter?.setValue(CIVector(x: threshold, y: 0.5), forKey: "inputPoint2")
        gammaFilter?.setValue(CIVector(x: min(1.0, threshold + 0.2), y: 1.0), forKey: "inputPoint3")
        gammaFilter?.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")
        return gammaFilter?.outputImage ?? clamped
    }

    private func render(ciImage: CIImage, size: CGSize) -> UIImage? {
        let extent = ciImage.extent.integral
        guard let cgImage = ciContext.createCGImage(ciImage, from: extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }
}


