import Foundation
import PDFKit

/// A specialized handler for PCDA (Principal Controller of Defence Accounts) payslips.
/// These military payslips often have specific password formats and structure.
class PCDAPayslipHandler {
    
    /// Attempts to unlock a PCDA PDF using various password strategies.
    /// - Parameters:
    ///   - data: The password-protected PDF data
    ///   - basePassword: The base password provided by the user
    /// - Returns: A tuple containing the unlocked data (if successful) and the password that worked
    func unlockPDF(data: Data, basePassword: String) async -> (Data?, String?) {
        guard let pdfDocument = PDFDocument(data: data), pdfDocument.isLocked else {
            // Not locked or not a valid PDF
            return (data, nil)
        }
        
        print("[PCDAPayslipHandler] Attempting to unlock PCDA PDF")
        
        // Try with the original password first
        if pdfDocument.unlock(withPassword: basePassword) {
            print("[PCDAPayslipHandler] Unlocked with original password")
            if let unlockedData = pdfDocument.dataRepresentation() {
                return (unlockedData, basePassword)
            }
        }
        
        // Generate variants of the base password to try
        let passwordVariants = generatePasswordVariants(from: basePassword)
        
        // Try each variant
        for variant in passwordVariants {
            // Create a fresh document for each attempt (PDFKit limitation)
            if let freshDocument = PDFDocument(data: data),
               freshDocument.unlock(withPassword: variant) {
                print("[PCDAPayslipHandler] Unlocked with variant: \(variant)")
                if let unlockedData = freshDocument.dataRepresentation() {
                    return (unlockedData, variant)
                }
            }
        }
        
        // Try common PCDA passwords if base password didn't work
        let commonPasswords = ["PCDA", "pcda", "army", "ARMY", "defence", "DEFENCE"]
        
        for password in commonPasswords {
            if let freshDocument = PDFDocument(data: data),
               freshDocument.unlock(withPassword: password) {
                print("[PCDAPayslipHandler] Unlocked with common password: \(password)")
                if let unlockedData = freshDocument.dataRepresentation() {
                    return (unlockedData, password)
                }
            }
        }
        
        return (nil, nil)
    }
    
    /// Generates various password formats commonly used in PCDA documents
    /// - Parameter basePassword: The original password
    /// - Returns: An array of password variants to try
    private func generatePasswordVariants(from basePassword: String) -> [String] {
        var variants = [String]()
        
        // Common transformations
        variants.append(basePassword.uppercased())
        variants.append(basePassword.lowercased())
        
        // Remove spaces if any
        let noSpaces = basePassword.replacingOccurrences(of: " ", with: "")
        if noSpaces != basePassword {
            variants.append(noSpaces)
            variants.append(noSpaces.uppercased())
            variants.append(noSpaces.lowercased())
        }
        
        // Common suffixes for service numbers
        let suffixes = ["", "1", "@", "#", "123", "army", "ARMY"]
        for suffix in suffixes {
            variants.append(basePassword + suffix)
            variants.append(basePassword.uppercased() + suffix)
        }
        
        // Prefix with common military designations
        let prefixes = ["JC", "JCO", "OR", "OFFICER", "OFF"]
        for prefix in prefixes {
            variants.append(prefix + basePassword)
            variants.append(prefix + "-" + basePassword)
        }
        
        // If it could be a service number, try different formats
        if basePassword.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil {
            // Service numbers often have different formatting
            let digitsOnly = basePassword.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if digitsOnly.count > 0 {
                variants.append(digitsOnly)
                
                // Try different length variants (some systems truncate)
                if digitsOnly.count > 6 {
                    variants.append(String(digitsOnly.prefix(6)))
                }
                if digitsOnly.count > 8 {
                    variants.append(String(digitsOnly.prefix(8)))
                }
            }
        }
        
        return variants
    }
    
    /// Extracts payslip data specific to PCDA format
    /// - Parameter document: The unlocked PDF document
    /// - Returns: Dictionary of extracted data or nil if extraction failed
    func extractPayslipData(from document: PDFDocument) -> [String: Any]? {
        guard !document.isLocked, document.pageCount > 0 else {
            return nil
        }
        
        var extractedData = [String: Any]()
        
        // Extract text from each page
        var fullText = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i),
               let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        // Check if it's definitely a PCDA payslip
        if !isPCDAPayslip(text: fullText) {
            return nil
        }
        
        // Extract basic information
        extractedData["fullText"] = fullText
        
        // Extract specific PCDA fields
        if let name = extractField(pattern: "Name\\s*:\\s*([\\w\\s]+)", from: fullText) {
            extractedData["name"] = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let rank = extractField(pattern: "Rank\\s*:\\s*([\\w\\s]+)", from: fullText) {
            extractedData["rank"] = rank.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let serviceNumber = extractField(pattern: "(Army|Service)\\s+No\\.?\\s*:\\s*([\\w\\d\\s/-]+)", from: fullText, captureGroup: 2) {
            extractedData["serviceNumber"] = serviceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract earnings and deductions
        extractedData["earnings"] = extractFinancialData(from: fullText, section: "EARNINGS")
        extractedData["deductions"] = extractFinancialData(from: fullText, section: "DEDUCTIONS")
        
        return extractedData
    }
    
    /// Checks if the text content is from a PCDA payslip
    /// - Parameter text: The full text of the document
    /// - Returns: True if it's a PCDA payslip, false otherwise
    private func isPCDAPayslip(text: String) -> Bool {
        let pcdaKeywords = [
            "PCDA", "Principal Controller of Defence Accounts",
            "PAY AND ALLOWANCES", "ARMY OFFICERS",
            "DSOP FUND", "CDA"
        ]
        
        for keyword in pcdaKeywords {
            if text.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    /// Extracts a field using regex pattern
    /// - Parameters:
    ///   - pattern: The regex pattern to match
    ///   - text: The text to search in
    ///   - captureGroup: The capture group to extract (default: 1)
    /// - Returns: The extracted field or nil if not found
    private func extractField(pattern: String, from text: String, captureGroup: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsRange) else {
            return nil
        }
        
        guard captureGroup < match.numberOfRanges,
              let range = Range(match.range(at: captureGroup), in: text) else {
            return nil
        }
        
        return String(text[range])
    }
    
    /// Extracts financial data from a specific section
    /// - Parameters:
    ///   - text: The full text
    ///   - section: The section name (EARNINGS or DEDUCTIONS)
    /// - Returns: Dictionary of financial items and values
    private func extractFinancialData(from text: String, section: String) -> [String: Double] {
        var result = [String: Double]()
        
        // This would need a more sophisticated parser for actual implementation
        // Here's a basic approach that would need enhancement for production
        
        let sectionPattern = "\(section)[\\s\\S]*?(?:TOTAL|NET|GRAND TOTAL)"
        guard let sectionText = extractField(pattern: sectionPattern, from: text) else {
            return result
        }
        
        // Pattern to match item and amount: Item name followed by amount
        let itemPattern = "([A-Za-z\\s/()-]+)\\s+(\\d+\\.\\d+)"
        guard let regex = try? NSRegularExpression(pattern: itemPattern, options: []) else {
            return result
        }
        
        let nsRange = NSRange(sectionText.startIndex..<sectionText.endIndex, in: sectionText)
        let matches = regex.matches(in: sectionText, options: [], range: nsRange)
        
        for match in matches {
            guard match.numberOfRanges >= 3,
                  let itemRange = Range(match.range(at: 1), in: sectionText),
                  let valueRange = Range(match.range(at: 2), in: sectionText) else {
                continue
            }
            
            let item = String(sectionText[itemRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let valueString = String(sectionText[valueRange])
            
            if let value = Double(valueString), !item.isEmpty {
                result[item] = value
            }
        }
        
        return result
    }
} 