import Foundation
import PDFKit

/// Layout analysis helper utilities for memory-efficient processing
struct LayoutAnalysisHelpers {
    
    /// Check for multiple column indicators and form patterns
    /// - Parameter text: Text to analyze
    /// - Returns: Tuple with (hasMultipleColumns, hasFormFields)
    static func detectLayoutFeatures(in text: String) -> (hasMultipleColumns: Bool, hasFormFields: Bool) {
        let columnIndicators = ["|", "│", "║", "  |  ", " | "]
        let formPatterns = ["_________", "__________", "□", "☐", "[ ]", "[  ]", "__/__/____"]
        let formLabels = ["Name:", "Address:", "Phone:", "Email:", "Date:", "Signature:"]
        
        var hasColumns = false
        var hasFormFields = false
        
        for indicator in columnIndicators {
            if text.contains(indicator) {
                hasColumns = true
                break
            }
        }
        
        if !hasFormFields {
            for pattern in formPatterns {
                if text.contains(pattern) {
                    hasFormFields = true
                    break
                }
            }
        }
        
        if !hasFormFields {
            for label in formLabels {
                if text.contains(label) {
                    hasFormFields = true
                    break
                }
            }
        }
        
        return (hasColumns, hasFormFields)
    }
    
    /// Select representative sample for memory efficiency
    /// - Parameters:
    ///   - pageIndices: All page indices
    ///   - maxSample: Maximum sample size
    /// - Returns: Representative sample
    static func selectRepresentativeSample(from pageIndices: [Int], maxSample: Int) -> [Int] {
        guard pageIndices.count > maxSample else { return pageIndices }
        
        var sample: [Int] = []
        
        // First page
        if let first = pageIndices.first {
            sample.append(first)
        }
        
        // Middle page
        if pageIndices.count > 2 {
            sample.append(pageIndices[pageIndices.count / 2])
        }
        
        // Last page
        if let last = pageIndices.last, last != pageIndices.first {
            sample.append(last)
        }
        
        // Fill remaining spots evenly
        let remaining = maxSample - sample.count
        if remaining > 0 && pageIndices.count > 3 {
            let strideValue = max(1, pageIndices.count / (remaining + 1))
            for i in stride(from: strideValue, to: pageIndices.count - 1, by: strideValue) {
                if sample.count < maxSample && !sample.contains(pageIndices[i]) {
                    sample.append(pageIndices[i])
                }
            }
        }
        
        return sample.sorted()
    }
} 