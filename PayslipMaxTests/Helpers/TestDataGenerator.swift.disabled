import Foundation
import PDFKit
@testable import PayslipMax

/// A utility class that provides standardized test data for various test scenarios
class TestDataGenerator {
    
    // MARK: - PayslipItem Generation
    
    /// Creates a standard sample PayslipItem for testing
    static func samplePayslipItem(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        credits: Double = 5000.0,
        debits: Double = 1000.0,
        dsop: Double = 300.0,
        tax: Double = 800.0,
        name: String = "John Doe",
        accountNumber: String = "XXXX1234",
        panNumber: String = "ABCDE1234F"
    ) -> PayslipItem {
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber
        )
    }
    
    /// Creates a collection of sample payslips spanning multiple months
    static func samplePayslipItems(count: Int = 12) -> [PayslipItem] {
        let months = ["January", "February", "March", "April", "May", "June", 
                     "July", "August", "September", "October", "November", "December"]
        
        return (0..<count).map { index in
            let monthIndex = index % 12
            let yearOffset = index / 12
            
            return PayslipItem(
                month: months[monthIndex],
                year: 2023 + yearOffset,
                credits: Double.random(in: 4000...6000),
                debits: Double.random(in: 800...1200),
                dsop: Double.random(in: 200...400),
                tax: Double.random(in: 600...1000),
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            )
        }
    }
    
    /// Creates a PayslipItem that represents an edge case
    static func edgeCasePayslipItem(type: EdgeCaseType) -> PayslipItem {
        switch type {
        case .zeroValues:
            return samplePayslipItem(credits: 0, debits: 0, dsop: 0, tax: 0)
            
        case .negativeBalance:
            return samplePayslipItem(credits: 1000, debits: 1500, dsop: 300, tax: 200)
            
        case .veryLargeValues:
            return samplePayslipItem(credits: 1_000_000, debits: 300_000, dsop: 50_000, tax: 150_000)
            
        case .decimalPrecision:
            return samplePayslipItem(credits: 5000.75, debits: 1000.25, dsop: 300.50, tax: 800.33)
            
        case .specialCharacters:
            return samplePayslipItem(
                name: "O'Connor-Smith, Jr.",
                accountNumber: "XXXX-1234/56",
                panNumber: "ABCDE1234F&"
            )
        }
    }
    
    enum EdgeCaseType {
        case zeroValues
        case negativeBalance
        case veryLargeValues
        case decimalPrecision
        case specialCharacters
    }
    
    // MARK: - PDF Generation
    
    /// Creates a sample PDF document with text for testing
    static func samplePDFDocument(withText text: String = "Sample PDF for testing") -> PDFDocument {
        let pdfData = createPDFWithText(text)
        return PDFDocument(data: pdfData)!
    }
    
    /// Creates a sample payslip PDF for testing
    static func samplePayslipPDF(
        name: String = "John Doe",
        rank: String = "Captain",
        id: String = "ID123456",
        month: String = "January",
        year: Int = 2023,
        credits: Double = 5000.0,
        debits: Double = 1000.0,
        dsop: Double = 300.0,
        tax: Double = 800.0
    ) -> PDFDocument {
        let pdfData = createPayslipPDF(
            name: name,
            rank: rank,
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax
        )
        return PDFDocument(data: pdfData)!
    }
    
    // MARK: - Private PDF Creation Helpers
    
    private static func createPDFWithText(_ text: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: textFont
            ]
            
            text.draw(
                with: CGRect(x: 10, y: 10, width: pageRect.width - 20, height: pageRect.height - 20),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )
        }
    }
    
    private static func createPayslipPDF(
        name: String,
        rank: String,
        id: String,
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double
    ) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            // Constants for styling
            let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
            let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            
            let titleColor = UIColor.black
            let headerColor = UIColor.darkGray
            let textColor = UIColor.black
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            // Draw title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: titleColor,
                .paragraphStyle: paragraphStyle
            ]
            
            "MILITARY PAYSLIP".draw(
                with: CGRect(x: 0, y: 50, width: pageRect.width, height: 30),
                options: .usesLineFragmentOrigin,
                attributes: titleAttributes,
                context: nil
            )
            
            // Draw document date
            paragraphStyle.alignment = .right
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            "Payment for \(month) \(year)".draw(
                with: CGRect(x: pageRect.width - 230, y: 100, width: 200, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: dateAttributes,
                context: nil
            )
            
            // Draw header information
            paragraphStyle.alignment = .left
            let personalInfoAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            "Name: \(name)".draw(
                with: CGRect(x: 50, y: 150, width: pageRect.width - 100, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: personalInfoAttributes,
                context: nil
            )
            
            "Rank: \(rank)".draw(
                with: CGRect(x: 50, y: 170, width: pageRect.width - 100, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: personalInfoAttributes,
                context: nil
            )
            
            "ID: \(id)".draw(
                with: CGRect(x: 50, y: 190, width: pageRect.width - 100, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: personalInfoAttributes,
                context: nil
            )
            
            // Draw table headers
            paragraphStyle.alignment = .center
            let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: headerColor,
                .paragraphStyle: paragraphStyle
            ]
            
            let headerY = 250.0
            let rowHeight = 30.0
            
            // Draw header row
            UIColor.lightGray.withAlphaComponent(0.3).setFill()
            context.fill(CGRect(x: 50, y: headerY, width: pageRect.width - 100, height: rowHeight))
            
            "Description".draw(
                with: CGRect(x: 50, y: headerY, width: 200, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: tableHeaderAttributes,
                context: nil
            )
            
            "Amount (₹)".draw(
                with: CGRect(x: pageRect.width - 250, y: headerY, width: 200, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: tableHeaderAttributes,
                context: nil
            )
            
            // Draw table data
            paragraphStyle.alignment = .left
            let descriptionAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            paragraphStyle.alignment = .right
            let amountAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            // Credits row
            "Total Credits".draw(
                with: CGRect(x: 50, y: headerY + rowHeight, width: 200, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: descriptionAttributes,
                context: nil
            )
            
            String(format: "%.2f", credits).draw(
                with: CGRect(x: pageRect.width - 250, y: headerY + rowHeight, width: 180, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: amountAttributes,
                context: nil
            )
            
            // Debits row
            "Total Debits".draw(
                with: CGRect(x: 50, y: headerY + 2 * rowHeight, width: 200, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: descriptionAttributes,
                context: nil
            )
            
            String(format: "%.2f", debits).draw(
                with: CGRect(x: pageRect.width - 250, y: headerY + 2 * rowHeight, width: 180, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: amountAttributes,
                context: nil
            )
            
            // DSOP row
            "DSOP Contribution".draw(
                with: CGRect(x: 50, y: headerY + 3 * rowHeight, width: 200, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: descriptionAttributes,
                context: nil
            )
            
            String(format: "%.2f", dsop).draw(
                with: CGRect(x: pageRect.width - 250, y: headerY + 3 * rowHeight, width: 180, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: amountAttributes,
                context: nil
            )
            
            // Tax row
            "Income Tax".draw(
                with: CGRect(x: 50, y: headerY + 4 * rowHeight, width: 200, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: descriptionAttributes,
                context: nil
            )
            
            String(format: "%.2f", tax).draw(
                with: CGRect(x: pageRect.width - 250, y: headerY + 4 * rowHeight, width: 180, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: amountAttributes,
                context: nil
            )
            
            // Draw separator line
            let cgContext = context.cgContext
            cgContext.move(to: CGPoint(x: 50, y: headerY + 5 * rowHeight))
            cgContext.addLine(to: CGPoint(x: pageRect.width - 50, y: headerY + 5 * rowHeight))
            cgContext.strokePath()
            
            // Net amount row
            let netAmount = credits - debits  // Net remittance = credits - debits (debits already includes dsop & tax)
            let netAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            "Net Amount".draw(
                with: CGRect(x: 50, y: headerY + 5 * rowHeight + 10, width: 200, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: netAttributes,
                context: nil
            )
            
            String(format: "%.2f", netAmount).draw(
                with: CGRect(x: pageRect.width - 250, y: headerY + 5 * rowHeight + 10, width: 180, height: rowHeight),
                options: .usesLineFragmentOrigin,
                attributes: netAttributes,
                context: nil
            )
            
            // Footer
            paragraphStyle.alignment = .center
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            "This is a generated test payslip for testing purposes only".draw(
                with: CGRect(x: 50, y: pageRect.height - 50, width: pageRect.width - 100, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: footerAttributes,
                context: nil
            )
        }
    }
} 