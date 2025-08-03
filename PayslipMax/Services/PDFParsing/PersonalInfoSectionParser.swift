import Foundation

/// Protocol for parsing personal information from document sections
protocol PersonalInfoSectionParserProtocol {
    /// Parse personal information from a document section
    /// - Parameter section: The document section containing personal information
    /// - Returns: Dictionary of personal information fields and their values
    func parsePersonalInfoSection(_ section: DocumentSection) -> [String: String]
}

/// Service responsible for parsing personal information from payslip document sections
class PersonalInfoSectionParser: PersonalInfoSectionParserProtocol {
    
    // MARK: - Public Methods
    
    /// Parse personal information from a document section
    /// - Parameter section: The document section containing personal information
    /// - Returns: Dictionary of personal information fields and their values
    func parsePersonalInfoSection(_ section: DocumentSection) -> [String: String] {
        var result: [String: String] = [:]
        
        // Common personal info fields
        let patterns = [
            "name": "(?:Name|Employee Name|Officer Name)[^:]*:[^\\n]*([A-Za-z\\s.]+)",
            "rank": "(?:Rank|Grade|Level)[^:]*:[^\\n]*([A-Za-z0-9\\s.]+)",
            "serviceNumber": "(?:Service No|ID|Number)[^:]*:[^\\n]*([A-Za-z0-9\\s.]+)",
            "accountNumber": "(?:A/C No|Account Number|Bank A/C)[^:]*:[^\\n]*([A-Za-z0-9\\s./]+)",
            "panNumber": "(?:PAN|PAN No|PAN Number)[^:]*:[^\\n]*([A-Za-z0-9\\s]+)"
        ]
        
        // Extract each field using regex
        for (field, pattern) in patterns {
            if let match = section.text.range(of: pattern, options: .regularExpression) {
                let matchText = String(section.text[match])
                
                // Extract the captured group (the actual value)
                if let valueRange = matchText.range(of: ":[^\\n]*([A-Za-z0-9\\s./]+)", options: .regularExpression),
                   let captureRange = matchText[valueRange].range(of: "([A-Za-z0-9\\s./]+)", options: .regularExpression) {
                    let value = String(matchText[valueRange][captureRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    result[field] = value
                }
            }
        }
        
        return result
    }
    
    // MARK: - Private Methods
    
    /// Extract a specific field value using a regex pattern
    /// - Parameters:
    ///   - pattern: The regex pattern to match
    ///   - text: The text to search in
    /// - Returns: The extracted value, if found
    private func extractFieldValue(for pattern: String, in text: String) -> String? {
        if let match = text.range(of: pattern, options: .regularExpression) {
            let matchText = String(text[match])
            
            // Extract the captured group (the actual value)
            if let valueRange = matchText.range(of: ":[^\\n]*([A-Za-z0-9\\s./]+)", options: .regularExpression),
               let captureRange = matchText[valueRange].range(of: "([A-Za-z0-9\\s./]+)", options: .regularExpression) {
                return String(matchText[valueRange][captureRange])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
}