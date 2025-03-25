import Foundation
import PDFKit
import XCTest
import UIKit

/// Helper utilities for creating test PDFs for PDF Service tests
class PDFTestHelpers {
    
    // Special marker for password protection
    static let PASSWORD_MARKER = "@@PASSWORD_PROTECTED@@"
    static let MILITARY_MARKER = "@@MILITARY_PDF@@"
    
    /// Creates a basic test PDF with standard content
    static func createStandardPDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Test",
            kCGPDFContextAuthor: "Test Creator",
            kCGPDFContextTitle: "Standard Test PDF"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Add simple payslip content to the PDF
            let text = """
            EMPLOYEE PAYSLIP
            
            Name: John Doe
            Employee ID: 12345
            Pay Period: 01/01/2023 - 31/01/2023
            
            Basic Pay: $4,500.00
            Allowances: $500.00
            Deductions: $1,200.00
            
            Net Pay: $3,800.00
            
            Standard PDF Content
            """
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
        }
        
        // Append plain text marker to identify this as standard PDF that can be found with String(data: data, encoding: .utf8)
        var standardData = data
        let standardContent = "\nStandard PDF Content".data(using: .utf8) ?? Data()
        standardData.append(standardContent)
        
        return standardData
    }
    
    /// Creates a military-style test PDF
    static func createMilitaryPDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Test",
            kCGPDFContextAuthor: "Military Test Creator",
            kCGPDFContextTitle: "Military Test PDF"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Add military-specific payslip content
            let text = """
            MINISTRY OF DEFENCE
            ARMY PAY CENTRE
            MILITARY PAYSLIP
            
            Rank: Captain
            Service Number: MIL123456
            Unit: 42nd Infantry Battalion
            Pay Period: 01/02/2023 - 28/02/2023
            
            Base Pay: $5,200.00
            Combat Allowance: $1,500.00
            Housing Allowance: $800.00
            DSOP FUND: $500.00
            Deductions: $1,300.00
            
            Net Pay: $6,200.00
            """
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
        }
        
        // Add a marker to identify this as military PDF
        var militaryData = data
        let textMarker = "\nMINISTRY OF DEFENCE\nARMY PAY CENTRE\nMILITARY PAYSLIP\n".data(using: .utf8) ?? Data()
        militaryData.append(textMarker)
        
        // Add a special military marker that can be detected with String search
        let militaryMarker = MILITARY_MARKER.data(using: .utf8) ?? Data()
        militaryData.append(militaryMarker)
        
        return militaryData
    }
    
    /// Creates a password-protected PDF with the given content and password
    static func createPasswordProtectedPDF(content: String, password: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Test",
            kCGPDFContextAuthor: "Protected Test Creator",
            kCGPDFContextTitle: "Password Protected PDF"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            // Add content and confidential header to simulate password protection
            let fullContent = """
            CONFIDENTIAL - PASSWORD PROTECTED
            
            \(content)
            """
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            fullContent.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
        }
        
        // Store the password in the PDF data
        // In a real implementation, this would be actual encryption
        var data = pdfData
        
        // Append plaintext content to make it searchable
        let textMarker = "\nThis is password protected content\n".data(using: .utf8) ?? Data()
        data.append(textMarker)
        
        // Append password protection marker
        let passwordMarker = "\(PASSWORD_MARKER):\(password)".data(using: .utf8)!
        data.append(passwordMarker)
        
        return data
    }
    
    /// Creates a password-protected military PDF
    static func createPasswordProtectedMilitaryPDF(password: String) -> Data {
        let militaryContent = """
        MINISTRY OF DEFENCE
        ARMY PAY CENTRE
        CONFIDENTIAL MILITARY PAYSLIP
        
        Rank: Major
        Service Number: MIL789012
        Unit: Special Operations Command
        Pay Period: 01/03/2023 - 31/03/2023
        
        Base Pay: $6,500.00
        Special Duty Pay: $2,000.00
        Hazard Pay: $1,500.00
        Housing Allowance: $900.00
        DSOP FUND: $700.00
        Deductions: $2,100.00
        
        Net Pay: $8,800.00
        """
        
        var data = createPasswordProtectedPDF(content: militaryContent, password: password)
        
        // Add plaintext military marker
        let textMarker = "\nMINISTRY OF DEFENCE\nARMY PAY CENTRE\nMILITARY PAYSLIP\n".data(using: .utf8) ?? Data()
        data.append(textMarker)
        
        // Add a marker to identify this as military PDF
        let militaryMarker = MILITARY_MARKER.data(using: .utf8) ?? Data()
        data.append(militaryMarker)
        
        return data
    }
    
    /// Creates a PDF with malformed content that might be challenging to parse
    static func createMalformedPDF() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Test",
            kCGPDFContextAuthor: "Malformed Test Creator",
            kCGPDFContextTitle: "Malformed Test PDF"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Draw some malformed text
            let text = """
            PAYSLIP DATA xxxx$#@!
            
            Employee: J*****e
            ID: ??-??-??
            
            Basic: $?.??,??
            Allow: $???.??
            
            Period: ../../.... - ../../....
            
            Net: $?,???.??
            """
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: paragraphStyle
            ]
            
            text.draw(at: CGPoint(x: 40, y: 60), withAttributes: attributes)
        }
        
        // Add plaintext marker for malformed content
        var malformedData = data
        let textMarker = "\nPAYSLIP DATA xxxx$#@!\nEmployee: J*****e\n".data(using: .utf8) ?? Data()
        malformedData.append(textMarker)
        
        return malformedData
    }
    
    /// Verify if a PDF is password protected
    static func isPasswordProtected(_ data: Data) -> Bool {
        guard let dataString = String(data: data, encoding: .utf8) else {
            return false
        }
        return dataString.contains(PASSWORD_MARKER)
    }
    
    /// Check if the PDF is a military type
    static func isMilitaryPDF(_ data: Data) -> Bool {
        guard let dataString = String(data: data, encoding: .utf8) else {
            return false
        }
        return dataString.contains(MILITARY_MARKER) || 
               dataString.contains("MINISTRY OF DEFENCE") || 
               dataString.contains("MILITARY PAYSLIP") ||
               dataString.contains("DSOP FUND")
    }
    
    /// Attempts to unlock a PDF with the given password
    static func unlockPDF(_ data: Data, password: String) -> Bool {
        // If the PDF is not password protected, return true for any password
        if !isPasswordProtected(data) {
            return true
        }
        
        // Check if the data contains our password marker with the matching password
        guard let dataString = String(data: data, encoding: .utf8) else {
            return false
        }
        
        // Check for the marker with the correct password
        let markerWithPassword = "\(PASSWORD_MARKER):\(password)"
        return dataString.contains(markerWithPassword)
    }
}