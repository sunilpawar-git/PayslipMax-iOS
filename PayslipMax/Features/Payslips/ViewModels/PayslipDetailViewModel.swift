import SwiftUI
import SwiftData
import Foundation
import Combine
import PDFKit

#if canImport(Vision)
import Vision
#endif

// Adding an extension to Models.PayslipData to make it Equatable
extension Models.PayslipData: Equatable {
    public static func == (lhs: Models.PayslipData, rhs: Models.PayslipData) -> Bool {
        // Compare essential properties to determine equality
        return lhs.name == rhs.name &&
               lhs.totalCredits == rhs.totalCredits &&
               lhs.totalDebits == rhs.totalDebits &&
               lhs.dsop == rhs.dsop &&
               lhs.incomeTax == rhs.incomeTax &&
               lhs.netRemittance == rhs.netRemittance &&
               lhs.allEarnings == rhs.allEarnings &&
               lhs.allDeductions == rhs.allDeductions
    }
}

/// Coordinator that orchestrates PayslipDetailViewModel components while preserving original interface
/// This maintains backward compatibility while providing modular architecture
@MainActor
class PayslipDetailViewModel: ObservableObject, @preconcurrency PayslipViewModelProtocol {
    // MARK: - Component Managers
    private let stateManager: PayslipDetailStateManager
    private let pdfHandler: PayslipDetailPDFHandler
    private let formatterService: PayslipDetailFormatterService
    
    // MARK: - Published Properties (Delegated to StateManager)
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var payslipData: Models.PayslipData
    @Published var showShareSheet = false
    @Published var showDiagnostics = false
    @Published var showOriginalPDF = false
    @Published var showPrintDialog = false
    @Published var unknownComponents: [String: (Double, String)] = [:]
    
    // MARK: - Published Properties (Delegated to PDFHandler)
    @Published var pdfData: Data?
    @Published var contactInfo: ContactInfo = ContactInfo()
    
    // MARK: - Private Properties
    private(set) var payslip: AnyPayslip
    private let securityService: SecurityServiceProtocol
    private let dataService: DataServiceProtocol
    
    // MARK: - Legacy Services (for backward compatibility)
    private let shareService: PayslipShareService
    
    // MARK: - Public Properties
    var pdfFilename: String {
        return formatterService.pdfFilename
    }
    // Note: Unified architecture - no longer needs separate parser
    
    // Unique ID for view identification and caching
    var uniqueViewId: String {
        "\(payslip.id)-\(payslip.month)-\(payslip.year)"
    }
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipDetailViewModel with the specified payslip and services.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to display details for.
    ///   - securityService: The security service to use for sensitive data operations.
    ///   - dataService: The data service to use for saving data.
    init(payslip: AnyPayslip, 
         securityService: SecurityServiceProtocol? = nil, 
         dataService: DataServiceProtocol? = nil,
         pdfService: PayslipPDFService? = nil,
         formatterService: PayslipFormatterService? = nil,
         shareService: PayslipShareService? = nil) {
        
        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        self.shareService = shareService ?? PayslipShareService.shared
        
        // Initialize component managers
        let resolvedDataService = dataService ?? DIContainer.shared.dataService
        let resolvedPDFService = pdfService ?? PayslipPDFService.shared
        let resolvedFormatterService = formatterService ?? PayslipFormatterService.shared
        
        self.stateManager = PayslipDetailStateManager(payslip: payslip, dataService: resolvedDataService)
        self.pdfHandler = PayslipDetailPDFHandler(payslip: payslip, dataService: resolvedDataService, pdfService: resolvedPDFService)
        self.formatterService = PayslipDetailFormatterService(payslip: payslip, formatterService: resolvedFormatterService)
        
        // Set the initial payslip data from state manager
        self.payslipData = stateManager.payslipData
        
        // Set up property bindings to component managers
        self.setupPropertyBindings()
    }
    
    // MARK: - Setup Methods
    
    /// Sets up property bindings between coordinator and component managers
    private func setupPropertyBindings() {
        // Bind StateManager properties
        stateManager.$isLoading.assign(to: &$isLoading)
        stateManager.$error.assign(to: &$error)
        stateManager.$payslipData.assign(to: &$payslipData)
        stateManager.$showShareSheet.assign(to: &$showShareSheet)
        stateManager.$showDiagnostics.assign(to: &$showDiagnostics)
        stateManager.$showOriginalPDF.assign(to: &$showOriginalPDF)
        stateManager.$showPrintDialog.assign(to: &$showPrintDialog)
        stateManager.$unknownComponents.assign(to: &$unknownComponents)
        
        // Bind PDFHandler properties
        pdfHandler.$pdfData.assign(to: &$pdfData)
        pdfHandler.$contactInfo.assign(to: &$contactInfo)
    }
    
    // MARK: - Public Methods
    
    /// Loads additional data from the PDF if available.
    func loadAdditionalData() async {
        await pdfHandler.loadAdditionalData()
    }
    
    /// Forces regeneration of PDF data to apply updated formatting (useful after currency fixes)
    func forceRegeneratePDF() async {
        await pdfHandler.forceRegeneratePDF()
        stateManager.clearCaches()
    }
    
    /// Checks if this payslip is a manual entry that needs PDF regeneration
    var needsPDFRegeneration: Bool {
        return pdfHandler.needsPDFRegeneration
    }
    
    /// Automatically handles PDF regeneration if needed (for manual entries)
    func handleAutomaticPDFRegeneration() async {
        await pdfHandler.handleAutomaticPDFRegeneration()
    }
    
    /// Enriches the payslip data with additional information from parsing
    func enrichPayslipData(with pdfData: [String: String]) {
        stateManager.enrichPayslipData(with: pdfData)
    }
    
    // MARK: - Formatting Methods (Delegated to FormatterService)
    
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
        return try await pdfHandler.getPDFURL()
    }
    
    /// Get items to share for this payslip (async version that handles PDF regeneration)
    func getShareItems() async -> [Any] {
        let pdfData = await pdfHandler.getPDFDataForSharing()
        let shareItems = formatterService.getShareItems(for: payslipData, pdfData: pdfData)
        stateManager.cacheShareItems(shareItems)
        return shareItems
    }
    
    /// Get items to share for this payslip (synchronous version for compatibility)
    func getShareItemsSync() -> [Any]? {
        // Return cached items if available
        if let cachedItems = stateManager.getCachedShareItems() {
            Logger.info("Using cached share items", category: "PayslipSharing")
            return cachedItems
        }
        
        // For synchronous access, return basic items without regeneration
        let pdfData = pdfHandler.pdfData
        let shareItems = formatterService.getShareItems(for: payslipData, pdfData: pdfData)
        stateManager.cacheShareItems(shareItems)
        return shareItems
    }
    
    /// Updates the payslip with corrected data.
    ///
    /// - Parameter correctedData: The corrected payslip data.
    func updatePayslipData(_ correctedData: Models.PayslipData) {
        stateManager.updatePayslipData(correctedData)
        formatterService.clearFormattingCache()
    }
    
    // MARK: - Component Categorization
    
    /// Called when a user categorizes an unknown component
    func userCategorizedComponent(code: String, asCategory: String) {
        stateManager.userCategorizedComponent(code: code, asCategory: asCategory)
    }
    
    // MARK: - Error Handling (Delegated to StateManager)
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        stateManager.handleError(error)
    }
    
    // MARK: - Computed Properties (Delegated to FormatterService)
    
    /// Gets a formatted breakdown of earnings
    var earningsBreakdown: [BreakdownItem] {
        return formatterService.getEarningsBreakdown(from: payslipData)
    }
    
    /// Gets a formatted breakdown of deductions
    var deductionsBreakdown: [BreakdownItem] {
        return formatterService.getDeductionsBreakdown(from: payslipData)
    }
    
    /// Prints the payslip PDF using the system print dialog
    /// - Parameter presentingVC: The view controller from which to present the print dialog
    func printPDF(from presentingVC: UIViewController) {
        // Use cached data if available
        if let pdfData = self.pdfData {
            let jobName = "Payslip - \(payslip.month) \(payslip.year)"
            PrintService.shared.printPDF(pdfData: pdfData, jobName: jobName, from: presentingVC) {
                                        self.stateManager.dismissPrintDialog()
            }
            return
        }
        
        // If no cached data, try to get data from URL
        Task {
            do {
                let url = try await getPDFURL()
                if let url = url {
                    let jobName = "Payslip - \(payslip.month) \(payslip.year)"
                    PrintService.shared.printPDF(url: url, jobName: jobName, from: presentingVC) {
                        self.stateManager.dismissPrintDialog()
                    }
                } else {
                    self.stateManager.handleError(AppError.message("No PDF data available for printing"))
                }
            } catch {
                self.stateManager.handleError(error)
            }
        }
    }
}
