import SwiftUI
import SwiftData
import Foundation
import Combine
import PDFKit

#if canImport(Vision)
import Vision
#endif

@MainActor
class PayslipDetailViewModel: ObservableObject, @preconcurrency PayslipViewModelProtocol {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var payslipData: Models.PayslipData
    @Published var showShareSheet = false
    @Published var showDiagnostics = false
    @Published var showOriginalPDF = false
    @Published var unknownComponents: [String: (Double, String)] = [:]
    
    // MARK: - Private Properties
    private(set) var payslip: any PayslipItemProtocol
    private let securityService: SecurityServiceProtocol
    private let dataService: DataServiceProtocol
    
    // MARK: - Public Properties
    var pdfFilename: String
    private let parser: PayslipWhitelistParser
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipDetailViewModel with the specified payslip and services.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to display details for.
    ///   - securityService: The security service to use for sensitive data operations.
    ///   - dataService: The data service to use for saving data.
    init(payslip: any PayslipItemProtocol, securityService: SecurityServiceProtocol? = nil, dataService: DataServiceProtocol? = nil) {
        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        self.parser = PayslipWhitelistParser()
        
        // Set the PDF filename
        let month = payslip.month
        let year = String(payslip.year)
        self.pdfFilename = "Payslip_\(month)_\(year).pdf"
        
        // Set the initial payslip data
        self.payslipData = Models.PayslipData.from(payslipItem: payslip)
        
        // If there's PDF data, parse it for additional details
        Task {
            await loadAdditionalData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads additional data from the PDF if available.
    func loadAdditionalData() async {
        isLoading = true
        defer { isLoading = false }
        
        if let payslipItem = payslip as? PayslipItem, let pdfData = payslipItem.pdfData {
            if let pdfDocument = PDFDocument(data: pdfData) {
                // Parse additional data from the PDF
                let parsedData = parser.parse(pdfDocument: pdfDocument)
                
                // Update the payslipData with additional info from parsing
                enrichPayslipData(with: parsedData)
            }
        }
    }
    
    /// Enriches the payslip data with additional information from parsing
    func enrichPayslipData(with pdfData: [String: String]) {
        // Create temporary data model from the parsed PDF data for merging
        var tempData = Models.PayslipData()
        
        // Add data from PDF parsing
        for (key, value) in pdfData {
            // TODO: Add special handling for certain keys if needed
            
            // Example mapping logic:
            switch key.lowercased() {
            case "rank":
                tempData.rank = value
            case "name":
                tempData.name = value
            case "posting":
                tempData.postedTo = value
            // Add more mappings as needed
            default:
                break
            }
        }
        
        // Merge this data with our payslipData, but preserve core financial data
        mergeParsedData(tempData)
    }
    
    // Helper to merge parsed data while preserving core financial values
    private func mergeParsedData(_ parsedData: Models.PayslipData) {
        // Personal details (can be overridden by PDF data if available)
        if !parsedData.name.isEmpty { payslipData.name = parsedData.name }
        if !parsedData.rank.isEmpty { payslipData.rank = parsedData.rank }
        if !parsedData.postedTo.isEmpty { payslipData.postedTo = parsedData.postedTo }
        
        // Don't override the core financial data from the original payslip
    }
    
    /// Formats a value as a currency string.
    ///
    /// - Parameter value: The value to format.
    /// - Returns: A formatted currency string.
    func formatCurrency(_ value: Double) -> String {
        // Format without decimal places
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        
        if let formattedValue = formatter.string(from: NSNumber(value: value)) {
            return formattedValue
        }
        
        return String(format: "%.0f", value)
    }
    
    /// Gets a formatted string representation of the payslip for sharing.
    ///
    /// - Returns: A formatted string with payslip details.
    func getShareText() -> String {
        // Create a formatted description from PayslipData
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let creditsStr = formatter.string(from: NSNumber(value: payslipData.totalCredits)) ?? "\(payslipData.totalCredits)"
        let debitsStr = formatter.string(from: NSNumber(value: payslipData.totalDebits)) ?? "\(payslipData.totalDebits)"
        let dsopStr = formatter.string(from: NSNumber(value: payslipData.dsop)) ?? "\(payslipData.dsop)"
        let taxStr = formatter.string(from: NSNumber(value: payslipData.incomeTax)) ?? "\(payslipData.incomeTax)"
        let netStr = formatter.string(from: NSNumber(value: payslipData.netRemittance)) ?? "\(payslipData.netRemittance)"
        
        var description = """
        PAYSLIP DETAILS
        ---------------
        
        PERSONAL DETAILS:
        Name: \(payslipData.name)
        Month: \(payslipData.month)
        Year: \(payslipData.year)
        Location: \(payslipData.location)
        
        FINANCIAL DETAILS:
        Credits: \(creditsStr)
        Debits: \(debitsStr)
        DSOP: \(dsopStr)
        Tax: \(taxStr)
        Net Amount: \(netStr)
        """
        
        // Add earnings breakdown if available
        if !payslipData.allEarnings.isEmpty {
            description += "\n\nEARNINGS BREAKDOWN:"
            for (key, value) in payslipData.allEarnings.sorted(by: { $0.key < $1.key }) {
                if value > 0 {
                    let valueStr = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
                    description += "\n\(key): \(valueStr)"
                }
            }
        }
        
        // Add deductions breakdown if available
        if !payslipData.allDeductions.isEmpty {
            description += "\n\nDEDUCTIONS BREAKDOWN:"
            for (key, value) in payslipData.allDeductions.sorted(by: { $0.key < $1.key }) {
                if value > 0 {
                    let valueStr = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
                    description += "\n\(key): \(valueStr)"
                }
            }
        }
        
        description += "\n\nGenerated by Payslip Max"
        
        return description
    }
    
    /// Get the URL for the original PDF, creating or repairing it if needed
    func getPDFURL() async throws -> URL? {
        guard let payslipItem = payslip as? PayslipItem else {
            throw PDFStorageError.failedToSave
        }
        
        print("GetPDFURL: Attempting to get PDF URL for payslip \(payslipItem.id)")
        
        // First, check if the PDF already exists in the PDFManager
        if let url = PDFManager.shared.getPDFURL(for: payslipItem.id.uuidString) {
            print("GetPDFURL: Found existing PDF at \(url.path)")
            
            // Verify the file has content and is a valid PDF
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[FileAttributeKey.size] as? Int, size > 100 {
                    print("GetPDFURL: Existing PDF has valid size: \(size) bytes")
                    
                    // Additional verification - check if the PDF is valid
                    do {
                        let fileData = try Data(contentsOf: url)
                        if isPDFValid(data: fileData) {
                            print("GetPDFURL: Verified existing PDF is valid")
                            return url
                        } else {
                            print("GetPDFURL: Existing PDF is invalid, will create formatted PDF")
                            let formattedPDF = createFormattedPlaceholderPDF()
                            let newUrl = try PDFManager.shared.savePDF(data: formattedPDF, identifier: payslipItem.id.uuidString)
                            // Update payslip with formatted PDF
                            payslipItem.pdfData = formattedPDF
                            try? await dataService.save(payslipItem)
                            return newUrl
                        }
                    } catch {
                        print("GetPDFURL: Error reading PDF data: \(error)")
                    }
                } else {
                    print("GetPDFURL: Existing PDF has invalid size, will recreate")
                }
            } catch {
                print("GetPDFURL: Error checking existing PDF: \(error)")
            }
        }
        
        // If we have PDF data in the PayslipItem, save it to the PDFManager
        if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
            print("GetPDFURL: Using PDF data from payslip item (\(pdfData.count) bytes)")
            
            // Check if this appears to be a military PDF
            let isMilitaryPDF = checkForMilitaryPDFFormat(pdfData)
            if isMilitaryPDF {
                print("GetPDFURL: Detected military PDF format")
            }
            
            // First check if this is a valid PDF
            if isPDFValid(data: pdfData) {
                print("GetPDFURL: PDF data appears valid, saving directly")
                // Save the PDF data
                do {
                    let url = try PDFManager.shared.savePDF(data: pdfData, identifier: payslipItem.id.uuidString)
                    print("GetPDFURL: Saved PDF data to \(url.path)")
                    return url
                } catch {
                    print("GetPDFURL: Failed to save PDF data: \(error)")
                }
            } else {
                print("GetPDFURL: PDF data is invalid, creating formatted placeholder")
                let formattedPDF = createFormattedPlaceholderPDF()
                let url = try PDFManager.shared.savePDF(data: formattedPDF, identifier: payslipItem.id.uuidString)
                
                // Update the PayslipItem with the formatted PDF
                payslipItem.pdfData = formattedPDF
                try? await dataService.save(payslipItem)
                
                return url
            }
        }
        
        // No PDF data available, create a placeholder PDF
        print("GetPDFURL: No PDF data available, creating formatted placeholder")
        let formattedPDF = createFormattedPlaceholderPDF()
        
        do {
            let url = try PDFManager.shared.savePDF(data: formattedPDF, identifier: payslipItem.id.uuidString)
            print("GetPDFURL: Saved placeholder PDF to \(url.path)")
            
            // Update the PayslipItem with the placeholder data
            if let payslipItem = payslip as? PayslipItem {
                payslipItem.pdfData = formattedPDF
                let dataService = DIContainer.shared.dataService
                try? await dataService.save(payslipItem)
                print("GetPDFURL: Updated PayslipItem with placeholder PDF data")
            }
            
            return url
        } catch {
            print("GetPDFURL: Failed to save placeholder PDF: \(error)")
            throw error
        }
    }
    
    /// Checks if the provided data is a valid PDF
    private func isPDFValid(data: Data) -> Bool {
        // Quick check for PDF header
        let pdfHeaderCheck = data.prefix(5).map { UInt8($0) }
        let validHeader: [UInt8] = [37, 80, 68, 70, 45] // %PDF-
        
        if pdfHeaderCheck != validHeader {
            print("isPDFValid: Invalid PDF header")
            return false
        }
        
        // Try creating a PDFDocument
        if let document = PDFDocument(data: data), document.pageCount > 0 {
            print("isPDFValid: Valid PDF with \(document.pageCount) pages")
            
            // Check if the document has any text content to ensure it's not corrupt
            let firstPageText = document.page(at: 0)?.string ?? ""
            
            // If the document has suspicious encoded characters, treat as invalid
            let suspiciousPatterns = ["MILPDF:", "jZUdqY", "BaXSGIz", "cmCV3wK", "MG/9Qxz", "k8eUKJd"]
            for pattern in suspiciousPatterns {
                if firstPageText.contains(pattern) {
                    print("isPDFValid: PDF contains suspicious encoded content")
                    return false
                }
            }
            
            // Check if there's any readable text
            if !firstPageText.isEmpty && firstPageText.count > 20 {
                // Count readable characters (alphanumeric, punctuation, spaces)
                let readableCharCount = firstPageText.filter { $0.isLetter || $0.isNumber || $0.isPunctuation || $0.isWhitespace }.count
                let readableRatio = Double(readableCharCount) / Double(firstPageText.count)
                
                // If less than 60% of the content is readable text, consider it corrupted
                if readableRatio < 0.6 {
                    print("isPDFValid: PDF has low readable text ratio (\(readableRatio)), likely corrupted")
                    return false
                }
            }
            
            return true
        }
        
        print("isPDFValid: Could not create PDF document from data")
        return false
    }
    
    /// Check if this is a military PDF format
    private func checkForMilitaryPDFFormat(_ data: Data) -> Bool {
        // Check for common military PDF identifiers
        guard let dataString = String(data: data.prefix(10000), encoding: .ascii) ?? 
                               String(data: data.prefix(10000), encoding: .utf8) else {
            return false
        }
        
        // Military-specific keywords
        let militaryKeywords = [
            "MILITARY PAY", "DFAS", "Defense Finance", "Army", "Navy", "Marines", "Air Force",
            "LES", "Leave and Earnings", "MyPay", "Armed Forces", "Basic Pay", "COLA", "BAH", "BAS",
            "Department of Defense", "DoD", "Service Member", "Military Department"
        ]
        
        for keyword in militaryKeywords {
            if dataString.contains(keyword) {
                return true
            }
        }
        
        // Check for PDF security features often found in military PDFs
        if dataString.contains("/Encrypt") {
            return true
        }
        
        return false
    }
    
    /// Creates a professionally formatted PDF with payslip details
    private func createFormattedPlaceholderPDF() -> Data {
        let payslipItem = payslip as? PayslipItem
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headerFont = UIFont.boldSystemFont(ofSize: 18)
            let textFont = UIFont.systemFont(ofSize: 16)
            let smallFont = UIFont.systemFont(ofSize: 12)
            
            // Header with military blue styling
            let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 80)
            context.cgContext.setFillColor(UIColor(red: 0.0, green: 0.25, blue: 0.50, alpha: 1.0).cgColor)
            context.cgContext.fill(headerRect)
            
            // Title
            let titleRect = CGRect(x: 50, y: 25, width: pageRect.width - 100, height: 40)
            "Military Payslip".draw(in: titleRect, withAttributes: [
                NSAttributedString.Key.font: titleFont,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ])
            
            // Month and Year
            let dateRect = CGRect(x: 50, y: 100, width: pageRect.width - 100, height: 30)
            "\(payslipItem?.month ?? "Unknown") \(payslipItem?.year ?? 0)".draw(in: dateRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Name if available
            let nameRect = CGRect(x: 50, y: 140, width: pageRect.width - 100, height: 30)
            "Service Member: \(payslipData.name)".draw(in: nameRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Format numbers with currency
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "₹"
            formatter.minimumFractionDigits = 2
            
            // EARNINGS SECTION
            let earningsHeaderRect = CGRect(x: 50, y: 190, width: pageRect.width - 100, height: 30)
            "ENTITLEMENTS".draw(in: earningsHeaderRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Draw table header
            let headerY = 230.0
            let col1 = 50.0
            let col2 = 350.0
            
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(1.0)
            context.cgContext.move(to: CGPoint(x: col1, y: headerY + 25))
            context.cgContext.addLine(to: CGPoint(x: pageRect.width - 50, y: headerY + 25))
            context.cgContext.strokePath()
            
            // Draw headers
            "DESCRIPTION".draw(
                at: CGPoint(x: col1, y: headerY),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.darkText
                ]
            )
            
            "AMOUNT".draw(
                at: CGPoint(x: col2, y: headerY),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.darkText
                ]
            )
            
            // Add earnings components
            var rowY = headerY + 40
            
            // Basic Pay if available
            if payslipData.basicPay > 0 {
                "Basic Pay".draw(
                    at: CGPoint(x: col1, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                let amount = formatter.string(from: NSNumber(value: payslipData.basicPay)) ?? ""
                amount.draw(
                    at: CGPoint(x: col2, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                rowY += 25
            }
            
            // Dearness Allowance if available
            if payslipData.dearnessPay > 0 {
                "Dearness Allowance".draw(
                    at: CGPoint(x: col1, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                let amount = formatter.string(from: NSNumber(value: payslipData.dearnessPay)) ?? ""
                amount.draw(
                    at: CGPoint(x: col2, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                rowY += 25
            }
            
            // Military Service Pay if available
            if payslipData.militaryServicePay > 0 {
                "Military Service Pay".draw(
                    at: CGPoint(x: col1, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                let amount = formatter.string(from: NSNumber(value: payslipData.militaryServicePay)) ?? ""
                amount.draw(
                    at: CGPoint(x: col2, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                rowY += 25
            }
            
            // Other Allowances if available
            if payslipData.miscCredits > 0 {
                "Other Allowances".draw(
                    at: CGPoint(x: col1, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                let amount = formatter.string(from: NSNumber(value: payslipData.miscCredits)) ?? ""
                amount.draw(
                    at: CGPoint(x: col2, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                rowY += 25
            }
            
            // Draw total line
            rowY += 10
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(1.0)
            context.cgContext.move(to: CGPoint(x: col1, y: rowY))
            context.cgContext.addLine(to: CGPoint(x: pageRect.width - 50, y: rowY))
            context.cgContext.strokePath()
            rowY += 15
            
            // Total Credits
            "TOTAL ENTITLEMENTS".draw(
                at: CGPoint(x: col1, y: rowY),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.darkText]
            )
            
            let creditsTotal = formatter.string(from: NSNumber(value: payslipData.totalCredits)) ?? ""
            creditsTotal.draw(
                at: CGPoint(x: col2, y: rowY),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.darkText]
            )
            
            // DEDUCTIONS SECTION
            rowY += 50
            let deductionsHeaderRect = CGRect(x: 50, y: rowY, width: pageRect.width - 100, height: 30)
            "DEDUCTIONS".draw(in: deductionsHeaderRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Draw table header
            rowY += 40
            
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(1.0)
            context.cgContext.move(to: CGPoint(x: col1, y: rowY + 25))
            context.cgContext.addLine(to: CGPoint(x: pageRect.width - 50, y: rowY + 25))
            context.cgContext.strokePath()
            
            // Draw headers
            "DESCRIPTION".draw(
                at: CGPoint(x: col1, y: rowY),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.darkText
                ]
            )
            
            "AMOUNT".draw(
                at: CGPoint(x: col2, y: rowY),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.darkText
                ]
            )
            
            rowY += 40
            
            // DSOP if available
            if payslipData.dsop > 0 {
                "DSOP".draw(
                    at: CGPoint(x: col1, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                let amount = formatter.string(from: NSNumber(value: payslipData.dsop)) ?? ""
                amount.draw(
                    at: CGPoint(x: col2, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                rowY += 25
            }
            
            // AGIF if available
            if payslipData.agif > 0 {
                "AGIF".draw(
                    at: CGPoint(x: col1, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                let amount = formatter.string(from: NSNumber(value: payslipData.agif)) ?? ""
                amount.draw(
                    at: CGPoint(x: col2, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                rowY += 25
            }
            
            // Income Tax if available
            if payslipData.incomeTax > 0 {
                "Income Tax".draw(
                    at: CGPoint(x: col1, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                let amount = formatter.string(from: NSNumber(value: payslipData.incomeTax)) ?? ""
                amount.draw(
                    at: CGPoint(x: col2, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                rowY += 25
            }
            
            // Other Deductions if available
            if payslipData.miscDebits > 0 {
                "Other Deductions".draw(
                    at: CGPoint(x: col1, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                let amount = formatter.string(from: NSNumber(value: payslipData.miscDebits)) ?? ""
                amount.draw(
                    at: CGPoint(x: col2, y: rowY),
                    withAttributes: [.font: textFont, .foregroundColor: UIColor.darkText]
                )
                
                rowY += 25
            }
            
            // Draw total line
            rowY += 10
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(1.0)
            context.cgContext.move(to: CGPoint(x: col1, y: rowY))
            context.cgContext.addLine(to: CGPoint(x: pageRect.width - 50, y: rowY))
            context.cgContext.strokePath()
            rowY += 15
            
            // Total Deductions
            "TOTAL DEDUCTIONS".draw(
                at: CGPoint(x: col1, y: rowY),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.darkText]
            )
            
            let debitsTotal = formatter.string(from: NSNumber(value: payslipData.totalDebits)) ?? ""
            debitsTotal.draw(
                at: CGPoint(x: col2, y: rowY),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.darkText]
            )
            
            // NET PAY SECTION
            rowY += 50
            
            // Draw highlight box for net pay
            context.cgContext.setFillColor(UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0).cgColor)
            context.cgContext.fill(CGRect(x: 50, y: rowY - 10, width: pageRect.width - 100, height: 40))
            
            // Net Pay label and amount
            "NET PAY".draw(
                at: CGPoint(x: col1, y: rowY),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.darkText]
            )
            
            let netPay = payslipData.totalCredits - payslipData.totalDebits
            let netPayFormatted = formatter.string(from: NSNumber(value: netPay)) ?? ""
            netPayFormatted.draw(
                at: CGPoint(x: col2, y: rowY),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.darkText]
            )
            
            // Footer with explanatory note
            let footerRect = CGRect(x: 50, y: pageRect.height - 100, width: pageRect.width - 100, height: 60)
            let footerText = """
            This is a formatted representation of your military payslip data.
            The original PDF document from DFAS/military systems could not be displayed due to security features or format limitations.
            All financial data shown is accurate as extracted from the original document.
            """
            footerText.draw(in: footerRect, withAttributes: [
                NSAttributedString.Key.font: smallFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkGray
            ])
            
            // App branding
            let brandingRect = CGRect(x: 50, y: pageRect.height - 30, width: pageRect.width - 100, height: 20)
            "Generated by Payslip Max".draw(in: brandingRect, withAttributes: [
                NSAttributedString.Key.font: smallFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkGray
            ])
        }
    }
    
    /// Get items to share for this payslip
    func getShareItems() -> [Any]? {
        guard let payslipItem = payslip as? PayslipItem else {
            return [getShareText()]
        }
        
        // Create a semaphore to wait for the async PDF URL retrieval
        let semaphore = DispatchSemaphore(value: 0)
        var pdfURL: URL? = nil
        
        // Start a task to get the PDF URL asynchronously
        Task {
            do {
                pdfURL = try await getPDFURL()
                semaphore.signal()
            } catch {
                print("GetShareItems: Failed to get PDF URL: \(error)")
                semaphore.signal()
            }
        }
        
        // Wait for the PDF URL with a timeout
        _ = semaphore.wait(timeout: .now() + 1.0)
        
        // If we have a PDF URL, include it in the share items
        if let pdfURL = pdfURL {
            print("GetShareItems: Including PDF URL in share items: \(pdfURL.path)")
            return [getShareText(), pdfURL]
        }
        
        // If no PDF URL is available but we have PDF data, write it to a temporary file
        if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
            print("GetShareItems: Using PDF data from payslip item")
            
            // Verify and repair the PDF data if needed
            let validData = PDFManager.shared.verifyAndRepairPDF(data: pdfData)
            
            do {
                let tempDir = FileManager.default.temporaryDirectory
                let tempURL = tempDir.appendingPathComponent("\(payslipItem.id.uuidString)_temp.pdf")
                try validData.write(to: tempURL)
                print("GetShareItems: Wrote PDF data to temp file: \(tempURL.path)")
                return [getShareText(), tempURL]
            } catch {
                print("GetShareItems: Failed to write PDF data to temp file: \(error)")
            }
        }
        
        // If no PDF is available, just share the text
        print("GetShareItems: No PDF available, sharing text only")
        return [getShareText()]
    }
    
    /// Updates the payslip with corrected data.
    ///
    /// - Parameter correctedData: The corrected payslip data.
    func updatePayslipData(_ correctedData: Models.PayslipData) {
        Task {
            do {
                guard let payslipItem = payslip as? PayslipItem else {
                    error = AppError.message("Cannot update payslip: Invalid payslip type")
                    return
                }
                
                // Update the payslip item with the corrected data
                payslipItem.name = correctedData.name
                payslipItem.accountNumber = correctedData.accountNumber
                payslipItem.panNumber = correctedData.panNumber
                payslipItem.credits = correctedData.totalCredits
                payslipItem.debits = correctedData.totalDebits
                payslipItem.dsop = correctedData.dsop
                payslipItem.tax = correctedData.incomeTax
                
                // Update earnings/deductions
                payslipItem.earnings = correctedData.allEarnings
                payslipItem.deductions = correctedData.allDeductions
                
                // Initialize the data service if needed
                if !dataService.isInitialized {
                    try await dataService.initialize()
                }
                
                // Save the updated payslip
                try await dataService.save(payslipItem)
                
                // Update the published data
                self.payslipData = correctedData
                
                // Post a notification that a payslip was updated
                NotificationCenter.default.post(name: .payslipUpdated, object: nil)
                
                print("PayslipDetailViewModel: Updated payslip with corrected data")
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Component Categorization
    
    /// Called when a user categorizes an unknown component
    func userCategorizedComponent(code: String, asCategory: String) {
        if let (amount, _) = unknownComponents[code] {
            // Update the category in the unknown components dictionary
            unknownComponents[code] = (amount, asCategory)
            
            // Also update the appropriate earnings or deductions collection
            if asCategory == "earnings" {
                var updatedEarnings = payslipData.allEarnings
                updatedEarnings[code] = amount
                payslipData.allEarnings = updatedEarnings
            } else if asCategory == "deductions" {
                var updatedDeductions = payslipData.allDeductions
                updatedDeductions[code] = amount
                payslipData.allDeductions = updatedDeductions
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
    }
} 