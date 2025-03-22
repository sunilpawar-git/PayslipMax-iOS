import SwiftUI
import SwiftData
import Foundation
import Combine
import PDFKit

/// A simplified ViewModel for PayslipDetailView that uses PayslipData as the single source of truth
@MainActor
class SimplifiedPayslipDetailViewModel: ObservableObject, @preconcurrency PayslipViewModelProtocol {
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
    
    // MARK: - Properties
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
    
    /// Loads additional data from the PDF if available
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
        formatter.usesGroupingSeparator = true
        
        if let formattedValue = formatter.string(from: NSNumber(value: value)) {
            return formattedValue
        }
        
        return String(format: "%.0f", value)
    }
    
    /// Formats a year value without group separators
    func formatYear(_ year: Int) -> String {
        return "\(year)" // Simple string conversion without formatting
    }
    
    /// Gets a formatted string representation of the payslip for sharing.
    ///
    /// - Returns: A formatted string with payslip details.
    func getShareText() -> String {
        // Create a formatted description from PayslipData
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        
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
    
    /// Gets both text and PDF data for sharing if available
    /// - Returns: An array of items to share, or nil if only text is available
    func getShareItems() -> [Any]? {
        let shareText = getShareText()
        
        // Check if we have PDF data to share
        guard let payslipItem = payslip as? PayslipItem,
              let pdfData = payslipItem.pdfData,
              !pdfData.isEmpty else {
            // Return nil to indicate we only have text
            return nil
        }
        
        // Create temporary URL for the PDF
        let tempFileName = "\(payslipData.month)_\(payslipData.year)_Payslip.pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(tempFileName)
        
        do {
            // Write PDF data to temp file for sharing
            try pdfData.write(to: tempURL)
            // Return both text and PDF URL
            return [shareText, tempURL]
        } catch {
            print("Error preparing PDF for sharing: \(error)")
            // Return just text if we couldn't prepare the PDF
            return [shareText]
        }
    }
    
    /// Get the URL for sharing the PDF
    func getPDFURL() async throws -> URL? {
        guard let payslipItem = payslip as? PayslipItem else { 
            throw AppError.message("Cannot share PDF: Invalid payslip type")
        }
        
        // Check if PDF is already stored
        if let url = PDFManager.shared.getPDFURL(for: payslipItem.id.uuidString) {
            print("PDF found at: \(url.path)")
            return url
        }
        
        // If not stored, get the PDF data and save it
        guard let pdfData = payslipItem.pdfData else { 
            throw AppError.message("Cannot share PDF: No PDF data available")
        }
        
        do {
            print("Saving PDF data of size: \(pdfData.count) bytes")
            let url = try PDFManager.shared.savePDF(
                data: pdfData,
                identifier: payslipItem.id.uuidString
            )
            print("PDF saved successfully at: \(url.path)")
            return url
        } catch {
            print("Error saving PDF: \(error.localizedDescription)")
            throw AppError.message("Failed to save PDF: \(error.localizedDescription)")
        }
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
                
                // Post notification to trigger UI update
                NotificationCenter.default.post(name: AppNotification.payslipUpdated, object: nil)
                
                print("SimplifiedPayslipDetailViewModel: Updated payslip with corrected data")
            } catch {
                handleError(error)
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
} 