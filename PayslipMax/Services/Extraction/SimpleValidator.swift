import Foundation

/// Simple validation service for extraction results
/// Replaces the massive ExtractionResultValidator with essential functionality only
class SimpleValidator {
    
    // MARK: - Validation Methods
    
    /// Performs basic validation on extracted text
    /// - Parameter text: The extracted text to validate
    /// - Returns: True if text meets basic quality standards
    static func isValidExtraction(_ text: String) -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        // Minimum length check
        guard text.count >= 10 else {
            return false
        }
        
        // Basic artifact detection
        let artifactRatio = calculateArtifactRatio(in: text)
        return artifactRatio < 0.3 // Allow up to 30% artifacts
    }
    
    /// Quick quality score for extracted text
    /// - Parameter text: The extracted text
    /// - Returns: Quality score between 0.0 and 1.0
    static func calculateQualityScore(_ text: String) -> Double {
        let length = text.count
        let lengthScore = min(1.0, Double(length) / 1000.0)
        
        let artifactRatio = calculateArtifactRatio(in: text)
        let artifactScore = max(0.0, 1.0 - artifactRatio)
        
        return (lengthScore + artifactScore) / 2.0
    }
    
    // MARK: - Private Helpers
    
    private static func calculateArtifactRatio(in text: String) -> Double {
        guard text.count > 0 else { return 0.0 }
        
        let artifactChars = ["�", "□", "▢", "◇", "○"]
        let artifactCount = artifactChars.reduce(0) { count, char in
            count + text.components(separatedBy: char).count - 1
        }
        
        return Double(artifactCount) / Double(text.count)
    }
}
