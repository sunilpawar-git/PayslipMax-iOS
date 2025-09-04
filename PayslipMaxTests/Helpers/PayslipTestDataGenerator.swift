import Foundation
import PDFKit
@testable import PayslipMax

/// A specialized generator for payslip-related test data
class PayslipTestDataGenerator {
    
    // MARK: - Standard Payslip Data Generation
    
    /// Creates a standard military payslip for testing
    static func standardMilitaryPayslip(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        rank: String = "Major",
        name: String = "John Doe",
        serviceNumber: String = "MIL123456",
        credits: Double = 85000.0,
        debits: Double = 15000.0,
        dsop: Double = 6000.0,
        tax: Double = 25000.0,
        includeAllowances: Bool = true
    ) -> PayslipItem {
        let payslip = PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: "XXXX5678",
            panNumber: "ABCDE1234F"
        )
        
        // Note: Military-specific metadata would be set here if PayslipItem conformed to MilitaryPayslipRepresentable
        // For now, we return the base PayslipItem as military payslips are handled by MilitaryPayslipGenerator
        
        return payslip
    }
    
    // Corporate payslip generation removed - PayslipMax is exclusively for defense personnel
    
    /// Creates a PCDA payslip for testing defense personnel
    static func standardPCDAPayslip(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        name: String = "Major Jane Smith",
        serviceNumber: String = "PCDA123456",
        basicPay: Double = 67700.0,
        msp: Double = 15500.0,
        da: Double = 4062.0,
        dsop: Double = 6770.0,
        incomeTax: Double = 15000.0
    ) -> PayslipItem {
        // PCDA payslip fields  
        let credits = basicPay + msp + da
        let debits = dsop
        let tax = incomeTax
        
        let payslip = PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,  // PCDA payslips include DSOP
            tax: tax,
            name: name,
            accountNumber: "XXXX4321",
            panNumber: "FGHIJ5678K"
        )
        
        // Note: PCDA-specific metadata would be set here if needed
        
        return payslip
    }
    
    // MARK: - Specialized Data Generation
    
    /// Creates a payslip with anomalies for testing edge cases
    static func anomalousPayslip(anomalyType: AnomalyType) -> PayslipItem {
        switch anomalyType {
        case .negativeValues:
            return PayslipItem(
                month: "February",
                year: 2023,
                credits: 5000.0,
                debits: -200.0,  // Negative debit (unusual)
                dsop: 300.0,
                tax: 800.0,
                name: "Anomaly Test",
                accountNumber: "XXXX9999",
                panNumber: "AAAAA9999A"
            )
            
        case .excessiveValues:
            return PayslipItem(
                month: "March",
                year: 2023,
                credits: 9999999.0,  // Unusually high value
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "Excessive Value",
                accountNumber: "XXXX8888",
                panNumber: "BBBBB8888B"
            )
            
        case .specialCharacters:
            return PayslipItem(
                month: "April",
                year: 2023,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "Spécïal Ch@r$",  // Special characters
                accountNumber: "XXXX-7777",
                panNumber: "CCCCC7777C"
            )
            
        case .missingFields:
            return PayslipItem(
                month: "",  // Empty month
                year: 2023,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "Missing Fields",
                accountNumber: "",  // Empty account number
                panNumber: ""  // Empty PAN
            )
        }
    }
    
    /// Creates a collection of payslips with varied date ranges
    static func payslipTimeSeriesData(
        startMonth: Int = 1,
        startYear: Int = 2022,
        count: Int = 12,
        baseCredits: Double = 5000.0,
        incrementAmount: Double = 200.0
    ) -> [PayslipItem] {
        let months = ["January", "February", "March", "April", "May", "June", 
                     "July", "August", "September", "October", "November", "December"]
        
        return (0..<count).map { index in
            let monthIndex = (startMonth - 1 + index) % 12
            let yearOffset = (startMonth - 1 + index) / 12
            let currentYear = startYear + yearOffset
            
            // Gradually increase salary over time
            let currentCredits = baseCredits + (Double(index) * incrementAmount)
            let currentDebits = currentCredits * 0.2  // 20% of credits
            let currentDSOP = currentCredits * 0.05  // 5% of credits
            let currentTax = currentCredits * 0.15  // 15% of credits
            
            return PayslipItem(
                month: months[monthIndex],
                year: currentYear,
                credits: currentCredits,
                debits: currentDebits,
                dsop: currentDSOP,
                tax: currentTax,
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            )
        }
    }
    
    /// Creates a set of payslips with various allowances and deductions
    static func detailedPayslipWithBreakdown(
        name: String = "James Wilson",
        month: String = "September",
        year: Int = 2023
    ) -> PayslipItem {
        let payslip = PayslipItem(
            month: month,
            year: year,
            credits: 8500.0,
            debits: 1700.0,
            dsop: 425.0,
            tax: 1275.0,
            name: name,
            accountNumber: "XXXX6543",
            panNumber: "PQRST6789U"
        )
        
        // Note: Detailed breakdown would be added here if PayslipItem conformed to DetailedPayslipRepresentable
        // For now, we return the base PayslipItem as detailed formatting is handled by specialized generators
        
        return payslip
    }
    
    // MARK: - PDF Generation
    
    /// Creates a military payslip PDF for testing
    static func militaryPayslipPDF(
        name: String = "John Doe",
        rank: String = "Major",
        serviceNumber: String = "MIL123456",
        month: String = "January",
        year: Int = 2023,
        credits: Double = 85000.0,
        debits: Double = 15000.0,
        dsop: Double = 6000.0,
        tax: Double = 25000.0
    ) -> PDFDocument {
        // Utilize the core PDF generation capability from the main test data generator
        return TestDataGenerator.samplePayslipPDF(
            name: name,
            rank: rank,
            id: serviceNumber,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax
        )
    }
    
    /// Creates a corporate payslip PDF for testing
    static func corporatePayslipPDF(
        name: String = "Jane Smith",
        employeeId: String = "EMP78910",
        department: String = "Engineering",
        designation: String = "Senior Developer",
        month: String = "January",
        year: Int = 2023,
        basicSalary: Double = 60000.0,
        hra: Double = 20000.0,
        specialAllowance: Double = 15000.0,
        totalEarnings: Double = 95000.0,
        providentFund: Double = 7200.0,
        professionalTax: Double = 200.0,
        incomeTax: Double = 18000.0,
        totalDeductions: Double = 25400.0
    ) -> PDFDocument {
        let pdfMetaData = [
            kCGPDFContextCreator: "PayslipMax Tests",
            kCGPDFContextAuthor: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let pdfData = UIGraphicsPDFRenderer(bounds: pageRect, format: format).pdfData { context in
            context.beginPage()
            
            // Constants for styling
            let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
            let headerFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            let smallFont = UIFont.systemFont(ofSize: 10.0, weight: .regular)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            // Draw company logo placeholder and header
            UIColor.darkGray.setFill()
            context.fill(CGRect(x: 50, y: 50, width: 80, height: 40))
            
            paragraphStyle.alignment = .center
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            "ACME CORPORATION".draw(
                with: CGRect(x: 140, y: 50, width: 315, height: 30),
                options: .usesLineFragmentOrigin,
                attributes: titleAttributes,
                context: nil
            )
            
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: paragraphStyle
            ]
            
            "Payslip for \(month) \(year)".draw(
                with: CGRect(x: 140, y: 75, width: 315, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: subtitleAttributes,
                context: nil
            )
            
            // Draw employee information
            paragraphStyle.alignment = .left
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            // Left column
            "Employee Name: \(name)".draw(
                with: CGRect(x: 50, y: 130, width: 250, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: infoAttributes,
                context: nil
            )
            
            "Employee ID: \(employeeId)".draw(
                with: CGRect(x: 50, y: 150, width: 250, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: infoAttributes,
                context: nil
            )
            
            "Designation: \(designation)".draw(
                with: CGRect(x: 50, y: 170, width: 250, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: infoAttributes,
                context: nil
            )
            
            // Right column
            "Department: \(department)".draw(
                with: CGRect(x: 320, y: 130, width: 250, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: infoAttributes,
                context: nil
            )
            
            "Pay Period: \(month) \(year)".draw(
                with: CGRect(x: 320, y: 150, width: 250, height: 20),
                options: .usesLineFragmentOrigin,
                attributes: infoAttributes,
                context: nil
            )
            
            // Draw tables
            let tableY = 220.0
            let columnWidth = 125.0
            
            // Headers
            paragraphStyle.alignment = .center
            let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            // Earnings Header
            UIColor.darkGray.setFill()
            context.fill(CGRect(x: 50, y: tableY, width: 2 * columnWidth, height: 30))
            
            "EARNINGS".draw(
                with: CGRect(x: 50, y: tableY, width: 2 * columnWidth, height: 30),
                options: .usesLineFragmentOrigin,
                attributes: tableHeaderAttributes,
                context: nil
            )
            
            // Deductions Header
            context.fill(CGRect(x: 50 + (2 * columnWidth) + 20, y: tableY, width: 2 * columnWidth, height: 30))
            
            "DEDUCTIONS".draw(
                with: CGRect(x: 50 + (2 * columnWidth) + 20, y: tableY, width: 2 * columnWidth, height: 30),
                options: .usesLineFragmentOrigin,
                attributes: tableHeaderAttributes,
                context: nil
            )
            
            // Earnings Column Headers
            UIColor.lightGray.withAlphaComponent(0.3).setFill()
            context.fill(CGRect(x: 50, y: tableY + 30, width: columnWidth, height: 25))
            context.fill(CGRect(x: 50 + columnWidth, y: tableY + 30, width: columnWidth, height: 25))
            
            paragraphStyle.alignment = .left
            let columnHeaderAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            "Description".draw(
                with: CGRect(x: 60, y: tableY + 30, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: columnHeaderAttributes,
                context: nil
            )
            
            paragraphStyle.alignment = .right
            "Amount (₹)".draw(
                with: CGRect(x: 50 + columnWidth + 10, y: tableY + 30, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: columnHeaderAttributes,
                context: nil
            )
            
            // Deductions Column Headers
            UIColor.lightGray.withAlphaComponent(0.3).setFill()
            context.fill(CGRect(x: 50 + (2 * columnWidth) + 20, y: tableY + 30, width: columnWidth, height: 25))
            context.fill(CGRect(x: 50 + (3 * columnWidth) + 20, y: tableY + 30, width: columnWidth, height: 25))
            
            paragraphStyle.alignment = .left
            "Description".draw(
                with: CGRect(x: 60 + (2 * columnWidth) + 20, y: tableY + 30, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: columnHeaderAttributes,
                context: nil
            )
            
            paragraphStyle.alignment = .right
            "Amount (₹)".draw(
                with: CGRect(x: 50 + (3 * columnWidth) + 30, y: tableY + 30, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: columnHeaderAttributes,
                context: nil
            )
            
            // Earnings Rows
            let leftDescAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .left
                    return style
                }()
            ]
            
            let rightAmountAttributes: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor.black,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .right
                    return style
                }()
            ]
            
            let earningItems = [
                ("Basic Salary", basicSalary),
                ("House Rent Allowance", hra),
                ("Special Allowance", specialAllowance)
            ]
            
            for (index, item) in earningItems.enumerated() {
                let y = tableY + 55 + (CGFloat(index) * CGFloat(25))
                
                // Description
                item.0.draw(
                    with: CGRect(x: 60, y: y, width: columnWidth - 20, height: 25),
                    options: .usesLineFragmentOrigin,
                    attributes: leftDescAttributes,
                    context: nil
                )
                
                // Amount
                String(format: "%.2f", item.1).draw(
                    with: CGRect(x: 50 + columnWidth + 10, y: y, width: columnWidth - 20, height: 25),
                    options: .usesLineFragmentOrigin,
                    attributes: rightAmountAttributes,
                    context: nil
                )
            }
            
            // Deduction Rows
            let deductionItems = [
                ("Provident Fund", providentFund),
                ("Professional Tax", professionalTax),
                ("Income Tax", incomeTax)
            ]
            
            for (index, item) in deductionItems.enumerated() {
                let y = tableY + 55 + (CGFloat(index) * CGFloat(25))
                
                // Description
                item.0.draw(
                    with: CGRect(x: 60 + (2 * columnWidth) + 20, y: y, width: columnWidth - 20, height: 25),
                    options: .usesLineFragmentOrigin,
                    attributes: leftDescAttributes,
                    context: nil
                )
                
                // Amount
                String(format: "%.2f", item.1).draw(
                    with: CGRect(x: 50 + (3 * columnWidth) + 30, y: y, width: columnWidth - 20, height: 25),
                    options: .usesLineFragmentOrigin,
                    attributes: rightAmountAttributes,
                    context: nil
                )
            }
            
            // Total Lines
            let totalY = tableY + 130
            UIColor.lightGray.setStroke()
            
            // Get the underlying CGContext for drawing
            let cgContext = context.cgContext
            
            // Earnings Total Line
            cgContext.move(to: CGPoint(x: 50, y: totalY))
            cgContext.addLine(to: CGPoint(x: 50 + (2 * columnWidth), y: totalY))
            cgContext.strokePath()
            
            // Deductions Total Line
            cgContext.move(to: CGPoint(x: 50 + (2 * columnWidth) + 20, y: totalY))
            cgContext.addLine(to: CGPoint(x: 50 + (4 * columnWidth) + 20, y: totalY))
            cgContext.strokePath()
            
            // Total Earnings
            "Total Earnings".draw(
                with: CGRect(x: 60, y: totalY + 10, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: columnHeaderAttributes,
                context: nil
            )
            
            paragraphStyle.alignment = .right
            String(format: "%.2f", totalEarnings).draw(
                with: CGRect(x: 50 + columnWidth + 10, y: totalY + 10, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: columnHeaderAttributes,
                context: nil
            )
            
            // Total Deductions
            paragraphStyle.alignment = .left
            "Total Deductions".draw(
                with: CGRect(x: 60 + (2 * columnWidth) + 20, y: totalY + 10, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: columnHeaderAttributes,
                context: nil
            )
            
            paragraphStyle.alignment = .right
            String(format: "%.2f", totalDeductions).draw(
                with: CGRect(x: 50 + (3 * columnWidth) + 30, y: totalY + 10, width: columnWidth - 20, height: 25),
                options: .usesLineFragmentOrigin,
                attributes: columnHeaderAttributes,
                context: nil
            )
            
            // Net Pay
            let netPayY = totalY + 60
            UIColor.darkGray.setFill()
            context.fill(CGRect(x: 150, y: netPayY, width: 300, height: 40))
            
            paragraphStyle.alignment = .center
            let netPayAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16.0, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let netPay = totalEarnings - totalDeductions
            "NET PAY: ₹\(String(format: "%.2f", netPay))".draw(
                with: CGRect(x: 150, y: netPayY, width: 300, height: 40),
                options: .usesLineFragmentOrigin,
                attributes: netPayAttributes,
                context: nil
            )
            
            // Footer
            let footerY = pageRect.height - 50
            UIColor.lightGray.setFill()
            context.fill(CGRect(x: 50, y: footerY, width: pageRect.width - 100, height: 1))
            
            paragraphStyle.alignment = .center
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: smallFont,
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: paragraphStyle
            ]
            
            "This is a test payslip generated for testing purposes only. Not valid for financial transactions.".draw(
                with: CGRect(x: 50, y: footerY + 10, width: pageRect.width - 100, height: 30),
                options: .usesLineFragmentOrigin,
                attributes: footerAttributes,
                context: nil
            )
        }
        
        return PDFDocument(data: pdfData)!
    }
    
    // MARK: - Helper Methods
    
    /// Generate a random set of military allowances
    private static func generateMilitaryAllowances() -> [String: Double] {
        return [
            "Field Area Allowance": 3000.0,
            "Transport Allowance": 1500.0,
            "Uniform Allowance": 2000.0,
            "Ration Allowance": 1000.0,
            "Housing Allowance": 5000.0
        ]
    }
    
    // MARK: - Enums
    
    /// Types of anomalies for generating edge cases
    enum AnomalyType {
        case negativeValues
        case excessiveValues
        case specialCharacters
        case missingFields
    }
}

// MARK: - Protocol Extensions

/// Protocol for military payslip representation
protocol MilitaryPayslipRepresentable {
    var rank: String { get set }
    var serviceNumber: String { get set }
    var allowances: [String: Double] { get set }
}

/// Protocol for PCDA payslip representation (defense personnel)
protocol PCDAPayslipRepresentable {
    var serviceNumber: String { get set }
    var rank: String { get set }
    var unit: String { get set }
    var basicPay: Double { get set }
    var msp: Double { get set }
    var specialAllowance: Double { get set }
    var providentFund: Double { get set }
    var professionalTax: Double { get set }
}

/// Protocol for detailed payslip breakdowns
protocol DetailedPayslipRepresentable {
    var creditsBreakdown: [String: Double] { get set }
    var debitsBreakdown: [String: Double] { get set }
} 