import Foundation

/// Protocol for extracting metadata from document text
protocol DocumentMetadataExtractorProtocol {
    /// Extract metadata from document text
    /// - Parameter text: The full document text to extract metadata from
    /// - Returns: Dictionary of metadata fields and their values
    func extractMetadata(from text: String) -> [String: String]
}

/// Service responsible for extracting metadata from payslip documents
class DocumentMetadataExtractor: DocumentMetadataExtractorProtocol {
    
    // MARK: - Public Methods
    
    /// Extract metadata from document text
    /// - Parameter text: The full document text to extract metadata from  
    /// - Returns: Dictionary of metadata fields and their values
    func extractMetadata(from text: String) -> [String: String] {
        var metadata: [String: String] = [:]
        
        // Extract date information
        let datePattern = "(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})"
        let dateRegex = try? NSRegularExpression(pattern: datePattern, options: [])
        let nsString = text as NSString
        let dateMatches = dateRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        if dateMatches.count >= 1 {
            let dateRange = dateMatches[0].range(at: 1)
            metadata["documentDate"] = nsString.substring(with: dateRange)
        }
        
        // Extract month and year
        let monthYearPattern = "(January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{4})"
        if let match = text.range(of: monthYearPattern, options: .regularExpression) {
            let matchText = String(text[match])
            let components = matchText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            if components.count >= 2 {
                metadata["month"] = components[0]
                metadata["year"] = components[1]
            }
        }
        
        // Extract statement period
        let periodPattern = "(?:Statement Period|Pay Period|Period)[^:]*:[^\\n]*([0-9/\\-]+)\\s*(?:to|-)\\s*([0-9/\\-]+)"
        if let match = text.range(of: periodPattern, options: .regularExpression) {
            let matchText = String(text[match])
            
            // Extract start date
            if let startRange = matchText.range(of: ":[^\\n]*([0-9/\\-]+)", options: .regularExpression),
               let startCaptureRange = matchText[startRange].range(of: "([0-9/\\-]+)", options: .regularExpression) {
                metadata["periodStart"] = String(matchText[startRange][startCaptureRange])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Extract end date
            if let endRange = matchText.range(of: "(?:to|-)\\s*([0-9/\\-]+)", options: .regularExpression),
               let endCaptureRange = matchText[endRange].range(of: "([0-9/\\-]+)", options: .regularExpression) {
                metadata["periodEnd"] = String(matchText[endRange][endCaptureRange])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return metadata
    }
}