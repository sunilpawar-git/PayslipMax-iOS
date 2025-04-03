import Foundation
import PDFKit
import SwiftUI

/// Service class responsible for PDF-related operations for payslips
@MainActor
class PayslipPDFService {
    // MARK: - Singleton Instance
    static let shared = PayslipPDFService()
    
    // MARK: - Dependencies
    private let dataService: DataServiceProtocol
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
    }
    
    // MARK: - Public Methods
    
    /// Checks if the provided data is a valid PDF
    func isPDFValid(data: Data) -> Bool {
        // Quick check for PDF header
        let pdfHeaderCheck = data.prefix(5).map { UInt8($0) }
        let validHeader: [UInt8] = [37, 80, 68, 70, 45] // %PDF-
        
        if pdfHeaderCheck != validHeader {
            Logger.warning("Invalid PDF header", category: "PDFValidation")
            return false
        }
        
        // Try creating a PDFDocument
        if let document = PDFDocument(data: data), document.pageCount > 0 {
            Logger.info("Valid PDF with \(document.pageCount) pages", category: "PDFValidation")
            
            // Check if the document has any text content to ensure it's not corrupt
            let firstPageText = document.page(at: 0)?.string ?? ""
            
            // If the document has suspicious encoded characters, treat as invalid
            for pattern in PDFValidationConfig.suspiciousPatterns {
                if firstPageText.contains(pattern) {
                    Logger.warning("PDF contains suspicious encoded content: \(pattern)", category: "PDFValidation")
                    return false
                }
            }
            
            // Check if there's any readable text
            if !firstPageText.isEmpty && firstPageText.count > 20 {
                // Count readable characters (alphanumeric, punctuation, spaces)
                let readableCharCount = firstPageText.filter { $0.isLetter || $0.isNumber || $0.isPunctuation || $0.isWhitespace }.count
                let readableRatio = Double(readableCharCount) / Double(firstPageText.count)
                
                // Check if the ratio meets the minimum threshold
                if readableRatio < PDFValidationConfig.minimumReadableRatio {
                    Logger.warning("PDF has low readable text ratio (\(readableRatio)), likely corrupted", category: "PDFValidation")
                    return false
                }
            }
            
            return true
        }
        
        Logger.warning("Could not create PDF document from data", category: "PDFValidation")
        return false
    }
    
    /// Check if this is a military PDF format
    func checkForMilitaryPDFFormat(_ data: Data) -> Bool {
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
    func createFormattedPlaceholderPDF(from payslipData: Models.PayslipData, payslip: any PayslipItemProtocol) -> Data {
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
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            formatter.usesGroupingSeparator = true
            
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
    
    /// Get the URL for the original PDF, creating or repairing it if needed
    func getPDFURL(for payslip: any PayslipItemProtocol) async throws -> URL? {
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
                            
                            // Create and save a formatted PDF
                            let payslipData = Models.PayslipData.from(payslipItem: payslip)
                            let formattedPDF = createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)
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
                
                // Create a formatted PDF
                let payslipData = Models.PayslipData.from(payslipItem: payslip)
                let formattedPDF = createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)
                let url = try PDFManager.shared.savePDF(data: formattedPDF, identifier: payslipItem.id.uuidString)
                
                // Update the PayslipItem with the formatted PDF
                payslipItem.pdfData = formattedPDF
                try? await dataService.save(payslipItem)
                
                return url
            }
        }
        
        // No PDF data available, create a placeholder PDF
        print("GetPDFURL: No PDF data available, creating formatted placeholder")
        
        // Create a formatted PDF
        let payslipData = Models.PayslipData.from(payslipItem: payslip)
        let formattedPDF = createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)
        
        do {
            let url = try PDFManager.shared.savePDF(data: formattedPDF, identifier: payslipItem.id.uuidString)
            print("GetPDFURL: Saved placeholder PDF to \(url.path)")
            
            // Update the PayslipItem with the placeholder data
            if let payslipItem = payslip as? PayslipItem {
                payslipItem.pdfData = formattedPDF
                try? await dataService.save(payslipItem)
                Logger.info("Updated PayslipItem with placeholder PDF data", category: "PDFValidation")
            }
            
            return url
        } catch {
            Logger.error("Failed to save placeholder PDF: \(error)", category: "PDFValidation")
            throw error
        }
    }
    
    // MARK: - Private Properties
    
    /// Configuration for PDF validation
    private struct PDFValidationConfig {
        /// Patterns that indicate corrupted or specially encoded military PDFs
        static let suspiciousPatterns = [
            "MILPDF:", "jZUdqY", "BaXSGIz", "cmCV3wK", "MG/9Qxz", "k8eUKJd"
        ]
        
        /// Minimum ratio of readable text to total text to consider a PDF valid
        /// Lower values allow more encoded content, higher values require more readable text
        static let minimumReadableRatio: Double = 0.6
    }
} 