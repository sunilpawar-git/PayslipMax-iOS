import Foundation
import PDFKit

/// Represents a section of the payslip document
public struct DocumentSection {
    let name: String
    let text: String
    let bounds: CGRect?
    let pageIndex: Int
}

/// Protocol for extracting document sections from PDF content
protocol DocumentSectionExtractorProtocol {
    /// Extract document sections based on the identified structure
    /// - Parameters:
    ///   - document: The PDF document
    ///   - structure: The identified document structure
    /// - Returns: Array of document sections
    func extractDocumentSections(from document: PDFDocument, structure: DocumentStructure) -> [DocumentSection]
}

/// Service responsible for extracting structured sections from payslip documents based on their format
class DocumentSectionExtractor: DocumentSectionExtractorProtocol {
    
    // MARK: - Public Methods
    
    /// Extract document sections based on the identified structure
    /// - Parameters:
    ///   - document: The PDF document
    ///   - structure: The identified document structure
    /// - Returns: Array of document sections
    func extractDocumentSections(from document: PDFDocument, structure: DocumentStructure) -> [DocumentSection] {
        var sections: [DocumentSection] = []
        
        // Extract text from each page
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i), let pageText = page.string else { continue }
            
            // Different section extraction based on document structure
            switch structure {
            case .armyFormat:
                sections.append(contentsOf: extractArmyFormatSections(from: pageText, pageIndex: i))
            case .navyFormat:
                sections.append(contentsOf: extractNavyFormatSections(from: pageText, pageIndex: i))
            case .airForceFormat:
                sections.append(contentsOf: extractAirForceFormatSections(from: pageText, pageIndex: i))
            case .genericFormat, .unknown:
                sections.append(contentsOf: extractGenericFormatSections(from: pageText, pageIndex: i))
            }
        }
        
        return sections
    }
    
    // MARK: - Private Methods
    
    /// Extract sections from Army format payslips
    private func extractArmyFormatSections(from text: String, pageIndex: Int) -> [DocumentSection] {
        var sections: [DocumentSection] = []
        
        // Common section headers in Army payslips
        let sectionPatterns = [
            "personal": "(?:PERSONAL DETAILS|EMPLOYEE DETAILS)",
            "earnings": "(?:EARNINGS|PAYMENTS|PAY AND ALLOWANCES)",
            "deductions": "(?:DEDUCTIONS|RECOVERIES)",
            "tax": "(?:INCOME TAX DETAILS|TAX DETAILS)",
            "dsop": "(?:DSOP FUND|DSOP DETAILS)",
            "contact": "(?:CONTACT DETAILS|YOUR CONTACT POINTS)"
        ]
        
        // Extract each section
        for (sectionName, pattern) in sectionPatterns {
            if let range = text.range(of: pattern, options: .regularExpression) {
                let sectionStart = text.distance(from: text.startIndex, to: range.lowerBound)
                
                // Find the next section start or end of text
                var sectionEnd = text.count
                for (_, otherPattern) in sectionPatterns where otherPattern != pattern {
                    if let otherRange = text.range(of: otherPattern, options: .regularExpression, range: range.upperBound..<text.endIndex) {
                        let otherStart = text.distance(from: text.startIndex, to: otherRange.lowerBound)
                        sectionEnd = min(sectionEnd, otherStart)
                    }
                }
                
                // Extract section text
                let startIndex = text.index(text.startIndex, offsetBy: sectionStart)
                let endIndex = text.index(text.startIndex, offsetBy: sectionEnd)
                let sectionText = String(text[startIndex..<endIndex])
                
                sections.append(DocumentSection(name: sectionName, text: sectionText, bounds: nil, pageIndex: pageIndex))
            }
        }
        
        return sections
    }
    
    /// Extract sections from Navy format payslips
    private func extractNavyFormatSections(from text: String, pageIndex: Int) -> [DocumentSection] {
        // Similar to Army but with Navy-specific patterns
        // For now, use the generic extraction as a fallback
        return extractGenericFormatSections(from: text, pageIndex: pageIndex)
    }
    
    /// Extract sections from Air Force format payslips
    private func extractAirForceFormatSections(from text: String, pageIndex: Int) -> [DocumentSection] {
        // Similar to Army but with Air Force-specific patterns
        // For now, use the generic extraction as a fallback
        return extractGenericFormatSections(from: text, pageIndex: pageIndex)
    }
    
    /// Extract sections from generic format payslips
    private func extractGenericFormatSections(from text: String, pageIndex: Int) -> [DocumentSection] {
        var sections: [DocumentSection] = []
        
        // Generic section patterns that might work across different formats
        let sectionPatterns = [
            "personal": "(?:PERSONAL|EMPLOYEE|DETAILS|NAME|RANK)",
            "earnings": "(?:EARNINGS|PAYMENTS|ALLOWANCES|CREDITS|SALARY)",
            "deductions": "(?:DEDUCTIONS|RECOVERIES|DEBITS)",
            "tax": "(?:INCOME TAX|TAX|TDS)",
            "dsop": "(?:DSOP|FUND|PROVIDENT)",
            "contact": "(?:CONTACT|HELPDESK|QUERIES|CONTACT US|CONTACT DETAILS|FOR QUERIES|HELP DESK|CONTACT INFORMATION)"
        ]
        
        // Try to find sections using generic patterns
        for (sectionName, pattern) in sectionPatterns {
            if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                // Find a reasonable section boundary (next section or paragraph breaks)
                let sectionStart = range.lowerBound
                
                // Look for the next section or a reasonable boundary
                var sectionEnd = text.endIndex
                for (_, otherPattern) in sectionPatterns where otherPattern != pattern {
                    if let otherRange = text.range(of: otherPattern, options: [.regularExpression, .caseInsensitive], range: range.upperBound..<text.endIndex) {
                        sectionEnd = min(sectionEnd, otherRange.lowerBound)
                    }
                }
                
                // Extract section text
                let sectionText = String(text[sectionStart..<sectionEnd])
                
                sections.append(DocumentSection(name: sectionName, text: sectionText, bounds: nil, pageIndex: pageIndex))
            }
        }
        
        // If no sections were found, create a single "unknown" section with all text
        if sections.isEmpty {
            sections.append(DocumentSection(name: "unknown", text: text, bounds: nil, pageIndex: pageIndex))
        }
        
        // If no contact section was found, try to find contact information in the entire text
        if !sections.contains(where: { $0.name == "contact" }) {
            // Look for phone numbers, email addresses, or website URLs in the entire text
            let contactPatterns = [
                "\\(\\d{3,}[-\\s]?\\d{3,}\\)",  // Phone numbers in parentheses
                "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",  // Email addresses
                "(?:https?://)?(?:www\\.)?[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"  // Website URLs
            ]
            
            for pattern in contactPatterns {
                if let _ = text.range(of: pattern, options: .regularExpression) {
                    // Found contact information, create a contact section with the entire text
                    sections.append(DocumentSection(name: "contact", text: text, bounds: nil, pageIndex: pageIndex))
                    break
                }
            }
        }
        
        return sections
    }
}