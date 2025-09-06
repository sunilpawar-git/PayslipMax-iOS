import Foundation

/// Service responsible for financial pattern extraction from text
/// Extracted component for single responsibility - pattern-based financial data extraction
final class FinancialPatternExtractor {
    
    // MARK: - Public Interface
    
    /// Extracts financial data from text using predefined patterns
    /// - Parameter text: The text to analyze
    /// - Returns: Dictionary mapping data keys to values
    func extractFinancialData(from text: String) -> [String: Double] {
        var extractedData = [String: Double]()
        
        // Define patterns to look for in the PDF text
        let patterns: [(key: String, regex: String)] = [
            ("BPAY", "BPAY\\s*[:-]?\\s*([0-9,.]+)"),
            ("DA", "DA\\s*[:-]?\\s*([0-9,.]+)"),
            ("MSP", "MSP\\s*[:-]?\\s*([0-9,.]+)"),
            ("RH12", "RH12\\s*[:-]?\\s*([0-9,.]+)"),
            ("TPTA", "TPTA\\s*[:-]?\\s*([0-9,.]+)"),
            ("TPTADA", "TPTADA\\s*[:-]?\\s*([0-9,.]+)"),
            ("DSOP", "DSOP\\s*[:-]?\\s*([0-9,.]+)"),
            ("AGIF", "AGIF\\s*[:-]?\\s*([0-9,.]+)"),
            ("ITAX", "ITAX\\s*[:-]?\\s*([0-9,.]+)"),
            ("EHCESS", "EHCESS\\s*[:-]?\\s*([0-9,.]+)"),
            ("credits", "(?:Gross Pay|कुल आय)\\s*[:-]?\\s*([0-9,.]+)"),
            ("debits", "(?:Total Deductions|कुल कटौती)\\s*[:-]?\\s*([0-9,.]+)"),
        ]
        
        // Extract each value using regex patterns
        for (key, pattern) in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let nsString = text as NSString
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if let match = matches.first, match.numberOfRanges > 1 {
                    let valueRange = match.range(at: 1)
                    let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Convert to Double
                    let cleanValue = value.replacingOccurrences(of: ",", with: "")
                    if let doubleValue = Double(cleanValue) {
                        extractedData[key] = doubleValue
                        print("[FinancialPatternExtractor] Extracted \(key): \(doubleValue)")
                    }
                }
            } catch {
                print("[FinancialPatternExtractor] Error with regex pattern \(pattern): \(error.localizedDescription)")
            }
        }

        // Try to extract from tables by looking for patterns in the text
        if extractedData.isEmpty {
            extractDataFromTables(text, into: &extractedData)
        }
        
        // Try to find credits/debits totals from common phrases
        if extractedData["credits"] == nil {
            // Look for anything that could be Gross Pay/Total Earnings
            extractAmountWithPattern("(?:Total|Gross|Sum|कुल)\\s+(?:Pay|Earnings|Income|Credits|आय)\\s*[:-]?\\s*([0-9,.]+)", 
                                  from: text, 
                                  forKey: "credits", 
                                  into: &extractedData)
        }
        
        if extractedData["debits"] == nil {
            // Look for anything that could be Total Deductions
            extractAmountWithPattern("(?:Total|Sum|कुल)\\s+(?:Deductions|Cuts|कटौती)\\s*[:-]?\\s*([0-9,.]+)", 
                                  from: text, 
                                  forKey: "debits", 
                                  into: &extractedData)
        }
        
        return extractedData
    }
    
    /// Extracts an amount using a specific pattern
    /// - Parameters:
    ///   - pattern: Regular expression pattern to match
    ///   - text: Text to search in
    ///   - key: Key to store the result under
    ///   - data: Dictionary to store the result in
    func extractAmountWithPattern(
        _ pattern: String,
        from text: String,
        forKey key: String,
        into data: inout [String: Double]
    ) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                let cleanValue = value.replacingOccurrences(of: ",", with: "")
                if let doubleValue = Double(cleanValue) {
                    data[key] = doubleValue
                    print("[FinancialPatternExtractor] Extracted \(key): \(doubleValue)")
                }
            }
        } catch {
            print("[FinancialPatternExtractor] Error with pattern \(pattern): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Implementation
    
    /// Extracts data from table-like structures in the text
    /// - Parameters:
    ///   - text: The text to analyze
    ///   - data: The dictionary to populate with extracted key-value pairs.
    private func extractDataFromTables(_ text: String, into data: inout [String: Double]) {
        // Look for common payslip table patterns
        // Format: Description    Amount
        let tableLinePattern = "\\b([A-Za-z0-9\\s]+)\\s+([0-9,.]+)\\b"
        
        do {
            let regex = try NSRegularExpression(pattern: tableLinePattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches where match.numberOfRanges > 2 {
                let descriptionRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                
                let description = nsString.substring(with: descriptionRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let valueString = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Map description to standard keys
                let key = mapDescriptionToStandardKey(description)
                
                // Convert value to Double
                let cleanValue = valueString.replacingOccurrences(of: ",", with: "")
                if let doubleValue = Double(cleanValue) {
                    data[key] = doubleValue
                    print("[FinancialPatternExtractor] Extracted from table - \(key): \(doubleValue)")
                }
            }
        } catch {
            print("[FinancialPatternExtractor] Error parsing table pattern: \(error.localizedDescription)")
        }
    }
    
    /// Maps common textual descriptions found in payslips to standardized internal keys.
    /// For example, maps "basic pay" or "basic salary" to "BPAY".
    /// - Parameter description: The text description extracted from the payslip (e.g., from a table row).
    /// - Returns: A standardized key (e.g., "BPAY", "DA", "ITAX") or the original description if no mapping is found.
    private func mapDescriptionToStandardKey(_ description: String) -> String {
        let lowercased = description.lowercased()
        
        // Map common variations to standard keys
        if lowercased.contains("basic") && (lowercased.contains("pay") || lowercased.contains("salary")) {
            return "BPAY"
        } else if lowercased.contains("dearness") && lowercased.contains("allowance") {
            return "DA"
        } else if lowercased.contains("medical") && lowercased.contains("allowance") {
            return "MSP"
        } else if lowercased.contains("house") && lowercased.contains("rent") {
            return "RH12"
        } else if lowercased.contains("transport") && lowercased.contains("allowance") {
            return "TPTA"
        } else if lowercased.contains("income") && lowercased.contains("tax") {
            return "ITAX"
        } else if lowercased.contains("provident") && lowercased.contains("fund") {
            return "DSOP"
        } else if lowercased.contains("insurance") {
            return "AGIF"
        } else if lowercased.contains("cess") {
            return "EHCESS"
        }
        
        // Return the original description if no mapping found
        return description
    }
}
