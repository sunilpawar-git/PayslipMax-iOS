import Foundation

/// Represents the analysis results of a PDF document
/// This is a compatibility layer for the extracted DocumentAnalysisResult
struct DocumentAnalysis {
    let pageCount: Int
    let containsScannedContent: Bool
    let hasComplexLayout: Bool
    let textDensity: Double
    let estimatedMemoryRequirement: Int64
    let containsTables: Bool
    let hasText: Bool
    let imageCount: Int
    let containsFormElements: Bool
    
    /// Convenience property to check if document is considered large
    var isLargeDocument: Bool {
        return pageCount > 50 || estimatedMemoryRequirement > 100 * 1024 * 1024 // 100MB
    }
    
    /// Convenience property to check if document likely contains scanned content
    var hasScannedContent: Bool {
        return containsScannedContent
    }
    
    /// Convenience property to determine if document is text-heavy
    var isTextHeavy: Bool {
        return textDensity > 0.5 && hasText
    }
    
    /// Convenience property to check if document contains graphics/images
    var containsGraphics: Bool {
        return imageCount > 0 || containsScannedContent
    }
    
    /// Initialize with default values
    init(pageCount: Int = 0,
         containsScannedContent: Bool = false,
         hasComplexLayout: Bool = false,
         textDensity: Double = 0.0,
         estimatedMemoryRequirement: Int64 = 0,
         containsTables: Bool = false,
         hasText: Bool = false,
         imageCount: Int = 0,
         containsFormElements: Bool = false) {
        self.pageCount = pageCount
        self.containsScannedContent = containsScannedContent
        self.hasComplexLayout = hasComplexLayout
        self.textDensity = textDensity
        self.estimatedMemoryRequirement = estimatedMemoryRequirement
        self.containsTables = containsTables
        self.hasText = hasText
        self.imageCount = imageCount
        self.containsFormElements = containsFormElements
    }
}
