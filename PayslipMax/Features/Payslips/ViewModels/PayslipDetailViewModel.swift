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
    @Published var pdfData: Data?
    
    // MARK: - Private Properties
    private(set) var payslip: any PayslipItemProtocol
    private let securityService: SecurityServiceProtocol
    private let dataService: DataServiceProtocol
    
    // MARK: - Services
    private let pdfService: PayslipPDFService
    private let formatterService: PayslipFormatterService
    private let shareService: PayslipShareService
    
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
    init(payslip: any PayslipItemProtocol, 
         securityService: SecurityServiceProtocol? = nil, 
         dataService: DataServiceProtocol? = nil,
         pdfService: PayslipPDFService? = nil,
         formatterService: PayslipFormatterService? = nil,
         shareService: PayslipShareService? = nil) {
        
        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        self.pdfService = pdfService ?? PayslipPDFService.shared
        self.formatterService = formatterService ?? PayslipFormatterService.shared
        self.shareService = shareService ?? PayslipShareService.shared
        self.parser = PayslipWhitelistParser()
        
        // Set the PDF filename
        let month = payslip.month
        let year = String(payslip.year)
        self.pdfFilename = "Payslip_\(month)_\(year).pdf"
        
        // Set the initial payslip data
        var initialData = Models.PayslipData()
        initialData.name = payslip.name
        initialData.month = payslip.month
        initialData.year = payslip.year
        initialData.totalCredits = payslip.credits
        initialData.totalDebits = payslip.debits
        initialData.dsop = payslip.dsop
        initialData.incomeTax = payslip.tax
        initialData.accountNumber = payslip.accountNumber
        initialData.panNumber = payslip.panNumber
        initialData.allEarnings = payslip.earnings
        initialData.allDeductions = payslip.deductions
        initialData.netRemittance = payslip.credits - (payslip.debits + payslip.dsop + payslip.tax)
        
        self.payslipData = initialData
        
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
            // Set the pdfData property
            self.pdfData = pdfData
            
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
    func formatCurrency(_ value: Double?) -> String {
        return formatterService.formatCurrency(value)
    }
    
    /// Formats a year value without group separators
    func formatYear(_ year: Int) -> String {
        return formatterService.formatYear(year)
    }
    
    /// Gets a formatted string representation of the payslip for sharing.
    ///
    /// - Returns: A formatted string with payslip details.
    func getShareText() -> String {
        return formatterService.getShareText(for: payslipData)
    }
    
    /// Get the URL for the original PDF, creating or repairing it if needed
    func getPDFURL() async throws -> URL? {
        return try await pdfService.getPDFURL(for: payslip)
    }
    
    /// Get items to share for this payslip
    func getShareItems() -> [Any]? {
        // Create a semaphore to wait for the async share items retrieval
        let semaphore = DispatchSemaphore(value: 0)
        var items: [Any] = []
        
        // Start a task to get the share items asynchronously
        Task {
            items = await shareService.getShareItems(for: payslip, payslipData: payslipData)
                semaphore.signal()
        }
        
        // Wait for the share items with a timeout
        _ = semaphore.wait(timeout: .now() + 1.0)
        
        return items
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
    
    // MARK: - Computed Properties
    
    /// Gets a formatted breakdown of earnings
    var earningsBreakdown: [BreakdownItem] {
        var items: [BreakdownItem] = []
        
        for (key, value) in payslipData.allEarnings {
            if value > 0 {
                items.append(BreakdownItem(
                    label: key,
                    value: formatCurrency(value)
                ))
            }
        }
        
        return items.sorted(by: { $0.label < $1.label })
    }
    
    /// Gets a formatted breakdown of deductions
    var deductionsBreakdown: [BreakdownItem] {
        var items: [BreakdownItem] = []
        
        for (key, value) in payslipData.allDeductions {
            if value > 0 {
                items.append(BreakdownItem(
                    label: key,
                    value: formatCurrency(value)
                ))
            }
        }
        
        // Add tax and DSOP as separate deductions
        if payslipData.incomeTax > 0 {
            items.append(BreakdownItem(
                label: "Income Tax",
                value: formatCurrency(payslipData.incomeTax)
            ))
        }
        
        if payslipData.dsop > 0 {
            items.append(BreakdownItem(
                label: "DSOP",
                value: formatCurrency(payslipData.dsop)
            ))
        }
        
        return items.sorted(by: { $0.label < $1.label })
    }
} 