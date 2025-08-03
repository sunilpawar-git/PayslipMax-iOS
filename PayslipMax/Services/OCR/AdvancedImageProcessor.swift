import CoreImage
import UIKit
import Vision

/// Advanced image processor for optimal OCR preprocessing
class AdvancedImageProcessor {
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    // MARK: - Document Rectification
    func rectifyDocument(_ image: UIImage, bounds: VNRectangleObservation?) -> UIImage {
        guard let bounds = bounds,
              let ciImage = CIImage(image: image) else {
            return image
        }
        
        // Apply perspective correction based on detected bounds
        let perspectiveCorrection = CIFilter(name: "CIPerspectiveCorrection")!
        perspectiveCorrection.setValue(ciImage, forKey: kCIInputImageKey)
        
        // Set corner points from VNRectangleObservation
        let imageSize = ciImage.extent.size
        perspectiveCorrection.setValue(CIVector(cgPoint: CGPoint(
            x: bounds.topLeft.x * imageSize.width,
            y: (1 - bounds.topLeft.y) * imageSize.height
        )), forKey: "inputTopLeft")
        
        perspectiveCorrection.setValue(CIVector(cgPoint: CGPoint(
            x: bounds.topRight.x * imageSize.width,
            y: (1 - bounds.topRight.y) * imageSize.height
        )), forKey: "inputTopRight")
        
        perspectiveCorrection.setValue(CIVector(cgPoint: CGPoint(
            x: bounds.bottomLeft.x * imageSize.width,
            y: (1 - bounds.bottomLeft.y) * imageSize.height
        )), forKey: "inputBottomLeft")
        
        perspectiveCorrection.setValue(CIVector(cgPoint: CGPoint(
            x: bounds.bottomRight.x * imageSize.width,
            y: (1 - bounds.bottomRight.y) * imageSize.height
        )), forKey: "inputBottomRight")
        
        guard let outputImage = perspectiveCorrection.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - OCR Optimization
    func optimizeForOCR(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        var processedImage = ciImage
        
        // 1. Convert to grayscale for better OCR
        processedImage = applyGrayscaleConversion(processedImage)
        
        // 2. Enhance contrast
        processedImage = enhanceContrast(processedImage)
        
        // 3. Reduce noise
        processedImage = reduceNoise(processedImage)
        
        // 4. Sharpen text
        processedImage = sharpenText(processedImage)
        
        guard let cgImage = ciContext.createCGImage(processedImage, from: processedImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Enhancement Filters
    private func applyGrayscaleConversion(_ image: CIImage) -> CIImage {
        let grayscale = CIFilter(name: "CIColorMonochrome")!
        grayscale.setValue(image, forKey: kCIInputImageKey)
        grayscale.setValue(CIColor.gray, forKey: kCIInputColorKey)
        grayscale.setValue(1.0, forKey: kCIInputIntensityKey)
        return grayscale.outputImage ?? image
    }
    
    private func enhanceContrast(_ image: CIImage) -> CIImage {
        let contrast = CIFilter(name: "CIColorControls")!
        contrast.setValue(image, forKey: kCIInputImageKey)
        contrast.setValue(1.2, forKey: kCIInputContrastKey) // 20% contrast increase
        return contrast.outputImage ?? image
    }
    
    private func reduceNoise(_ image: CIImage) -> CIImage {
        let denoise = CIFilter(name: "CINoiseReduction")!
        denoise.setValue(image, forKey: kCIInputImageKey)
        denoise.setValue(0.02, forKey: "inputNoiseLevel")
        return denoise.outputImage ?? image
    }
    
    private func sharpenText(_ image: CIImage) -> CIImage {
        let sharpen = CIFilter(name: "CIUnsharpMask")!
        sharpen.setValue(image, forKey: kCIInputImageKey)
        sharpen.setValue(0.5, forKey: kCIInputRadiusKey)
        sharpen.setValue(0.9, forKey: kCIInputIntensityKey)
        return sharpen.outputImage ?? image
    }
    
    // MARK: - Quality Assessment
    func assessImageQuality(_ image: UIImage) -> ImageQualityMetrics {
        guard let ciImage = CIImage(image: image) else {
            return ImageQualityMetrics()
        }
        
        // Calculate basic quality metrics
        let sharpness = calculateSharpness(ciImage)
        let contrast = calculateContrast(ciImage)
        let brightness = calculateBrightness(ciImage)
        
        return ImageQualityMetrics(
            sharpness: sharpness,
            contrast: contrast,
            brightness: brightness,
            overallScore: (sharpness + contrast + brightness) / 3.0
        )
    }
    
    private func calculateSharpness(_ image: CIImage) -> Double {
        // Use edge detection to measure sharpness
        let edgeFilter = CIFilter(name: "CIEdges")!
        edgeFilter.setValue(image, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let edgeImage = edgeFilter.outputImage else { return 0.0 }
        
        // Calculate mean intensity of edges as sharpness metric
        return calculateMeanIntensity(edgeImage)
    }
    
    private func calculateContrast(_ image: CIImage) -> Double {
        let histogram = calculateHistogram(image)
        
        // Calculate standard deviation as contrast measure
        let mean = histogram.reduce(0.0, +) / Double(histogram.count)
        let variance = histogram.reduce(0.0) { sum, value in
            sum + pow(value - mean, 2)
        } / Double(histogram.count)
        
        return sqrt(variance) / 255.0 // Normalize to 0-1
    }
    
    private func calculateBrightness(_ image: CIImage) -> Double {
        return calculateMeanIntensity(image)
    }
    
    private func calculateMeanIntensity(_ image: CIImage) -> Double {
        // Simplified calculation - in real implementation would use CIAreaAverage
        return 0.5 // Placeholder value
    }
    
    private func calculateHistogram(_ image: CIImage) -> [Double] {
        // Simplified histogram - in real implementation would use CIAreaHistogram
        return Array(repeating: 0.5, count: 256) // Placeholder values
    }
}

// MARK: - Supporting Models
struct ImageQualityMetrics {
    let sharpness: Double
    let contrast: Double
    let brightness: Double
    let overallScore: Double
    
    init(sharpness: Double = 0.0, contrast: Double = 0.0, brightness: Double = 0.0, overallScore: Double = 0.0) {
        self.sharpness = sharpness
        self.contrast = contrast
        self.brightness = brightness
        self.overallScore = overallScore
    }
    
    var isGoodQuality: Bool {
        return overallScore > 0.6
    }
    
    var qualityDescription: String {
        switch overallScore {
        case 0.8...:
            return "Excellent"
        case 0.6..<0.8:
            return "Good"
        case 0.4..<0.6:
            return "Fair"
        case 0.2..<0.4:
            return "Poor"
        default:
            return "Very Poor"
        }
    }
}