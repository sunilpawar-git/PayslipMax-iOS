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
            
            // Verify the file has content
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[FileAttributeKey.size] as? Int, size > 100 {
                    print("GetPDFURL: Existing PDF has valid size: \(size) bytes")
                    return url
                } else {
                    print("GetPDFURL: Existing PDF has invalid size, will regenerate")
                }
            } catch {
                print("GetPDFURL: Error checking existing PDF: \(error)")
            }
        }
        
        // If we have PDF data in the PayslipItem, save it to the PDFManager
        if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
            print("GetPDFURL: Using PDF data from payslip item (\(pdfData.count) bytes)")
            
            // Verify and repair the PDF data if needed
            let validData = PDFManager.shared.verifyAndRepairPDF(data: pdfData)
            
            // Save the PDF data
            do {
                let url = try PDFManager.shared.savePDF(data: validData, identifier: payslipItem.id.uuidString)
                print("GetPDFURL: Saved PDF data to \(url.path)")
                return url
            } catch {
                print("GetPDFURL: Failed to save PDF data: \(error)")
                throw error
            }
        }
        
        // No PDF data available, create a placeholder PDF
        print("GetPDFURL: No PDF data available, creating placeholder")
        let placeholderData = createPlaceholderPDF()
        
        do {
            let url = try PDFManager.shared.savePDF(data: placeholderData, identifier: payslipItem.id.uuidString)
            print("GetPDFURL: Saved placeholder PDF to \(url.path)")
            
            // Update the PayslipItem with the placeholder data
            if let payslipItem = payslip as? PayslipItem {
                payslipItem.pdfData = placeholderData
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
    
    /// Creates a placeholder PDF with payslip details
    private func createPlaceholderPDF() -> Data {
        guard let payslipItem = payslip as? PayslipItem else {
            return PDFManager.shared.verifyAndRepairPDF(data: Data())
        }
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headerFont = UIFont.boldSystemFont(ofSize: 18)
            let textFont = UIFont.systemFont(ofSize: 16)
            
            // Title
            let titleRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: 50)
            "Payslip Details".draw(in: titleRect, withAttributes: [
                NSAttributedString.Key.font: titleFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Month and Year
            let dateRect = CGRect(x: 50, y: 100, width: pageRect.width - 100, height: 30)
            "\(payslipItem.month) \(payslipItem.year)".draw(in: dateRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            var yPos: CGFloat = 150
            
            // Earnings section
            "Earnings:".draw(at: CGPoint(x: 50, y: yPos), withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            yPos += 30
            
            for (key, value) in payslipItem.earnings {
                let itemRect = CGRect(x: 50, y: yPos, width: 300, height: 30)
                key.draw(in: itemRect, withAttributes: [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: UIColor.darkText
                ])
                
                let valueRect = CGRect(x: pageRect.width - 150, y: yPos, width: 100, height: 30)
                String(format: "$%.2f", value).draw(in: valueRect, withAttributes: [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: UIColor.darkText
                ])
                
                yPos += 25
            }
            
            yPos += 20
            
            // Deductions section
            "Deductions:".draw(at: CGPoint(x: 50, y: yPos), withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            yPos += 30
            
            for (key, value) in payslipItem.deductions {
                let itemRect = CGRect(x: 50, y: yPos, width: 300, height: 30)
                key.draw(in: itemRect, withAttributes: [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: UIColor.darkText
                ])
                
                let valueRect = CGRect(x: pageRect.width - 150, y: yPos, width: 100, height: 30)
                String(format: "$%.2f", value).draw(in: valueRect, withAttributes: [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: UIColor.darkText
                ])
                
                yPos += 25
            }
            
            yPos += 20
            
            // Total
            let totalRect = CGRect(x: 50, y: yPos, width: 300, height: 30)
            "Net Pay:".draw(in: totalRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            let netPay = payslipItem.credits - payslipItem.debits
            let totalValueRect = CGRect(x: pageRect.width - 150, y: yPos, width: 100, height: 30)
            String(format: "$%.2f", netPay).draw(in: totalValueRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Footer
            let footerRect = CGRect(x: 50, y: pageRect.height - 50, width: pageRect.width - 100, height: 30)
            "Generated by Payslip Max App".draw(in: footerRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
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