import Foundation
import PDFKit
@testable import PayslipMax

/// Generator for anomalous payslip test data to test edge cases
class AnomalousPayslipGenerator {
    
    // MARK: - Edge Case Payslips
    
    /// Creates a payslip with negative values to test error handling
    static func payslipWithNegativeValues(
        id: UUID = UUID(),
        month: String = "February",
        year: Int = 2023,
        name: String = "Test User"
    ) -> PayslipItem {
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: -5000.0,
            debits: -1000.0,
            dsop: -300.0,
            tax: -1500.0,
            name: name,
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
    }
    
    /// Creates a payslip with extremely large values to test overflow handling
    static func payslipWithExtremelyLargeValues(
        id: UUID = UUID(),
        month: String = "March",
        year: Int = 2023,
        name: String = "Test User"
    ) -> PayslipItem {
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: Double.greatestFiniteMagnitude / 2,
            debits: Double.greatestFiniteMagnitude / 4,
            dsop: Double.greatestFiniteMagnitude / 10,
            tax: Double.greatestFiniteMagnitude / 8,
            name: name,
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F"
        )
    }
    
    /// Creates a payslip with missing optional values
    static func payslipWithMissingOptionalValues(
        id: UUID = UUID(),
        month: String = "April",
        year: Int = 2023
    ) -> PayslipItem {
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: 50000.0,
            debits: 10000.0,
            dsop: nil,
            tax: nil,
            name: "",
            accountNumber: nil,
            panNumber: nil
        )
    }
    
    /// Creates a payslip with very long string values to test UI layout
    static func payslipWithVeryLongStrings(
        id: UUID = UUID(),
        month: String = "May",
        year: Int = 2023
    ) -> PayslipItem {
        let veryLongName = String(repeating: "A very long name that might break UI layouts ", count: 5)
        let veryLongAccount = String(repeating: "9", count: 50)
        let veryLongPan = String(repeating: "ABCDEFGHIJ", count: 5)
        
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: 50000.0,
            debits: 10000.0,
            dsop: 3000.0,
            tax: 15000.0,
            name: veryLongName,
            accountNumber: veryLongAccount,
            panNumber: veryLongPan
        )
    }
    
    /// Creates a payslip with unusual but valid characters in string fields
    static func payslipWithSpecialCharacters(
        id: UUID = UUID(),
        month: String = "June",
        year: Int = 2023
    ) -> PayslipItem {
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: 50000.0,
            debits: 10000.0,
            dsop: 3000.0,
            tax: 15000.0,
            name: "John O'Neal-Smith (Jr.) & Associates™",
            accountNumber: "A/C: 123-456-789",
            panNumber: "PAN#: XYZT-1234-A"
        )
    }
    
    // MARK: - Batch Generation
    
    /// Generates an array of anomalous payslips for testing
    static func batchOfAnomalousPayslips() -> [PayslipItem] {
        return [
            payslipWithNegativeValues(),
            payslipWithExtremelyLargeValues(),
            payslipWithMissingOptionalValues(),
            payslipWithVeryLongStrings(),
            payslipWithSpecialCharacters()
        ]
    }
    
    // MARK: - PDF Generation
    
    /// Creates a corrupted or unusual PDF for testing error handling
    static func anomalousPDF(anomalyType: AnomalyType = .emptyDocument) -> PDFDocument {
        switch anomalyType {
        case .emptyDocument:
            return PDFDocument()!
            
        case .singleEmptyPage:
            let document = PDFDocument()
            document.insert(PDFPage(), at: 0)
            return document
            
        case .invalidContentPage:
            // Create a document with garbled content
            let document = PDFDocument()
            let page = PDFPage()
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.black
            ]
            
            // Random bytes as text to confuse parsers
            let randomBytes = (0..<1000).map { _ in UInt8.random(in: 32...126) }
            let randomString = String(bytes: randomBytes, encoding: .ascii) ?? "Invalid content"
            
            let attributedText = NSAttributedString(string: randomString, attributes: attributes)
            page.addAnnotation(PDFAnnotation(bounds: CGRect(x: 0, y: 0, width: 500, height: 700), 
                                           forType: .freeText, 
                                 withProperties: nil))
            
            document.insert(page, at: 0)
            return document
        }
    }
    
    // MARK: - Utility
    
    /// Types of anomalies that can be generated for PDF documents
    enum AnomalyType {
        case emptyDocument
        case singleEmptyPage
        case invalidContentPage
    }
} 