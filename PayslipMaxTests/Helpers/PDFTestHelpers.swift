import Foundation
import PDFKit
import XCTest
import UIKit
@testable import Payslip_Max

/// Helper utilities for creating test PDFs for PDF Service tests
class PDFTestHelpers {
    
    // MARK: - PDF Type Markers
    static let standardPDFMarker = "Standard PDF Content"
    static let militaryPDFMarker = "MILITARY PAYSLIP"
    static let passwordProtectedMarker = "Password Protected PDF"
    
    // MARK: - Test Data Generation
    
    /// Creates a basic test PDF with standard content
    static func createStandardPDF() -> Data {
        let content = """
        EMPLOYEE PAYSLIP
        Name: John Doe
        Month: April
        Year: 2023
        Gross Pay: 5000.00
        Total Deductions: 1000.00
        Income Tax: 800.00
        Provident Fund: 500.00
        Account No: 1234567890
        PAN: ABCDE1234F
        \(standardPDFMarker)
        """
        return content.data(using: .utf8) ?? Data()
    }
    
    /// Creates a military-style test PDF
    static func createMilitaryPDF() -> Data {
        let content = """
        MINISTRY OF DEFENCE
        ARMY PAY CENTRE
        \(militaryPDFMarker)
        Service No: 123456
        Rank: Captain
        Name: John Doe
        Month: April
        Year: 2023
        Basic Pay: 6500.50
        DA: 1200.75
        MSP: 950.25
        Total Deductions: 600.50
        Account No: 9876543210
        PAN: ZYXWV9876G
        """
        return content.data(using: .utf8) ?? Data()
    }
    
    /// Creates a password-protected PDF with the given content and password
    static func createPasswordProtectedPDF(password: String = "test123") -> Data {
        let content = """
        \(passwordProtectedMarker)
        Password: \(password)
        EMPLOYEE PAYSLIP
        Name: John Doe
        Month: April
        Year: 2023
        Gross Pay: 5000.00
        Total Deductions: 1000.00
        Income Tax: 800.00
        Provident Fund: 500.00
        Account No: 1234567890
        PAN: ABCDE1234F
        """
        return content.data(using: .utf8) ?? Data()
    }
    
    /// Creates a PDF with malformed content that might be challenging to parse
    static func createMalformedPDF() -> Data {
        let content = """
        This is not a valid PDF
        But contains some text that should be extracted
        Name: Jane Smith
        Amount: 3000
        """
        return content.data(using: .utf8) ?? Data()
    }
    
    // MARK: - PDF Type Detection
    
    /// Checks if a PDF is a military PDF by looking for the military marker
    static func isMilitaryPDF(_ data: Data) -> Bool {
        guard let content = String(data: data, encoding: .utf8) else {
            return false
        }
        return content.contains(militaryPDFMarker) ||
               content.contains("MINISTRY OF DEFENCE") ||
               content.contains("ARMY PAY CENTRE") ||
               content.contains("Service No:") ||
               content.contains("Rank:")
    }
    
    /// Checks if a PDF is password protected by looking for the password marker
    static func isPasswordProtected(_ data: Data) -> Bool {
        guard let content = String(data: data, encoding: .utf8) else {
            return false
        }
        return content.contains(passwordProtectedMarker)
    }
    
    /// Attempts to unlock a PDF with the given password
    static func unlockPDF(_ data: Data, password: String) -> Bool {
        guard let dataString = String(data: data, encoding: .utf8) else {
            return false
        }
        
        // Look for the password marker with the correct password
        let expectedMarker = "Password: \(password)"
        return dataString.contains(expectedMarker)
    }
    
    /// Gets the password from a password-protected PDF
    static func getPasswordFromProtectedPDF(_ data: Data) -> String? {
        guard let content = String(data: data, encoding: .utf8),
              content.contains(passwordProtectedMarker) else {
            return nil
        }
        
        // Extract password from the marker format
        if let passwordRange = content.range(of: "Password: (.+)", options: .regularExpression) {
            let password = String(content[passwordRange])
                .replacingOccurrences(of: "Password: ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return password
        }
        
        return nil
    }
    
    // MARK: - PDF Content Extraction
    
    /// Extracts test data from the content
    static func extractTestData(_ content: String) -> [String: String] {
        var result: [String: String] = [:]
        
        // Extract name
        if let nameRange = content.range(of: "Name: (.+)", options: .regularExpression) {
            result["name"] = String(content[nameRange])
                .replacingOccurrences(of: "Name: ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract month
        if let monthRange = content.range(of: "Month: (.+)", options: .regularExpression) {
            result["month"] = String(content[monthRange])
                .replacingOccurrences(of: "Month: ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract year
        if let yearRange = content.range(of: "Year: (.+)", options: .regularExpression) {
            result["year"] = String(content[yearRange])
                .replacingOccurrences(of: "Year: ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract gross pay
        if let grossPayRange = content.range(of: "Gross Pay: (.+)", options: .regularExpression) {
            result["grossPay"] = String(content[grossPayRange])
                .replacingOccurrences(of: "Gross Pay: ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract total deductions
        if let deductionsRange = content.range(of: "Total Deductions: (.+)", options: .regularExpression) {
            result["totalDeductions"] = String(content[deductionsRange])
                .replacingOccurrences(of: "Total Deductions: ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract income tax
        if let taxRange = content.range(of: "Income Tax: (.+)", options: .regularExpression) {
            result["incomeTax"] = String(content[taxRange])
                .replacingOccurrences(of: "Income Tax: ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract provident fund
        if let pfRange = content.range(of: "Provident Fund: (.+)", options: .regularExpression) {
            result["providentFund"] = String(content[pfRange])
                .replacingOccurrences(of: "Provident Fund: ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract account number
        if let accountRange = content.range(of: "Account No: (.+)", options: .regularExpression) {
            result["accountNumber"] = String(content[accountRange])
                .replacingOccurrences(of: "Account No: ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract PAN
        if let panRange = content.range(of: "PAN: (.+)", options: .regularExpression) {
            result["panNumber"] = String(content[panRange])
                .replacingOccurrences(of: "PAN: ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return result
    }
}

// Extension on PDFDocument to support mocking in tests
extension PDFDocument {
    // Static property to control PDF document creation during tests
    static var shouldCreateMockPDFDocument = false
    static var mockDocumentTextContent: String = ""
    static var mockDocumentIsLocked = false
    
    // Original initializer: init?(data: Data)
    // We'll use method swizzling in tests to replace it
    static func mockPDFDocumentInitWithData(_ data: Data) -> PDFDocument? {
        if shouldCreateMockPDFDocument {
            let mockDocument = PDFDocument()
            
            // Add a blank page with our mock text
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
            let attributedString = NSAttributedString(string: mockDocumentTextContent, attributes: attributes)
            
            // Create a blank page and add it to the document
            let page = PDFPage()
            mockDocument.insert(page, at: 0)
            
            // Set document properties
            if mockDocumentIsLocked {
                // There's no public API to make a document appear locked
                // but we can use our own check in tests
            }
            
            return mockDocument
        } else {
            // Call the original implementation
            return PDFDocument(data: data)
        }
    }
}