import Foundation

/// Protocol for military format detection services
protocol MilitaryFormatDetectionServiceProtocol {
    /// Determines if the provided text content likely originates from a military payslip
    func isMilitaryPayslip(_ text: String) -> Bool
}

/// Service responsible for identifying military payslip formats
///
/// This service uses a two-step identification strategy to determine if text content
/// originates from a military payslip, employing both direct marker identification
/// and military terminology analysis for robust detection.
class MilitaryFormatDetectionService: MilitaryFormatDetectionServiceProtocol {
    
    // MARK: - Public Methods
    
    /// Determines if the provided text content likely originates from a military payslip.
    ///
    /// This check employs a two-step identification strategy:
    ///
    /// 1. **Direct Marker Identification**:
    ///    Searches for definitive markers like "PCDA" or "Principal Controller of Defence Accounts"
    ///    that conclusively identify a military payslip.
    ///
    /// 2. **Military Terminology Analysis**:
    ///    If direct markers aren't found, analyzes the text for the presence of multiple
    ///    military-specific terms (e.g., "Rank", "Service No", "AFPPF"). Finding 3 or more
    ///    such terms suggests a military payslip with high confidence.
    ///
    /// This dual approach ensures accurate identification even when documents have different
    /// headers or when standard markers might be obscured due to OCR errors.
    ///
    /// - Parameter text: The text content extracted from a PDF or other source.
    /// - Returns: `true` if the text is identified as a potential military payslip, `false` otherwise.
    func isMilitaryPayslip(_ text: String) -> Bool {
        // Check for PCDA format markers
        let pcdaMarkers = ["PCDA", "Principal Controller of Defence Accounts"]
        for marker in pcdaMarkers {
            if text.contains(marker) {
                print("MilitaryFormatDetectionService: Detected PCDA format")
                return true
            }
        }
        
        // Check for common military terms
        let militaryTerms = ["Rank", "Service No", "AFPPF", "Army", "Navy", "Air Force", "Defence", "Battalion", "Regiment", "Corps", "Pay Code"]
        var matches = 0
        for term in militaryTerms {
            if text.contains(term) {
                matches += 1
            }
        }
        
        // If at least 3 military terms are found, consider it a military payslip
        if matches >= 3 {
            print("MilitaryFormatDetectionService: Detected \(matches) military terms")
            return true
        }
        
        return false
    }
} 