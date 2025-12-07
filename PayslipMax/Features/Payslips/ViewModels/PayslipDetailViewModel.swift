import SwiftUI
import SwiftData
import Foundation
import Combine
import PDFKit

#if canImport(Vision)
import Vision
#endif

// Adding an extension to PayslipData to make it Equatable
extension PayslipData: Equatable {
    public static func == (lhs: PayslipData, rhs: PayslipData) -> Bool {
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
    private let actionsHandler: PayslipDetailActionsHandler
    private let formatterService: PayslipDetailFormatterService

    // MARK: - Published Properties (Delegated to StateManager)
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var payslipData: PayslipData
    @Published var showShareSheet = false
    @Published var showDiagnostics = false
    @Published var showOriginalPDF = false
    @Published var showPrintDialog = false
    @Published var unknownComponents: [String: (Double, String)] = [:]

    // MARK: - Editor State
    @Published var showOtherEarningsEditor = false
    @Published var showOtherDeductionsEditor = false

    // MARK: - Published Properties (Delegated to PDFHandler)
    @Published var pdfData: Data?
    @Published var contactInfo: ContactInfo = ContactInfo()

    // MARK: - X-Ray Comparison
    @Published var comparison: PayslipComparison?

    // MARK: - Private Properties
    private(set) var payslip: AnyPayslip
    private let securityService: SecurityServiceProtocol
    private let dataService: DataServiceProtocol
    private let comparisonService: PayslipComparisonServiceProtocol
    private var allPayslips: [AnyPayslip]?

    // MARK: - Public Properties
    let xRaySettings: any XRaySettingsServiceProtocol

    // MARK: - Combine
    private var xRayToggleCancellable: AnyCancellable?

    // MARK: - Legacy Services (for backward compatibility)
    private let shareService: PayslipShareService

    // MARK: - Public Properties
    var pdfFilename: String {
        return formatterService.pdfFilename
    }

    // Unique ID for view identification and caching
    var uniqueViewId: String {
        "\(payslip.id)-\(payslip.month)-\(payslip.year)"
    }

    // MARK: - Initialization

    /// Initializes a new PayslipDetailViewModel with the specified payslip and services.
    init(payslip: AnyPayslip,
         securityService: SecurityServiceProtocol? = nil,
         dataService: DataServiceProtocol? = nil,
         pdfService: PayslipPDFService? = nil,
         formatterService: PayslipFormatterService? = nil,
         shareService: PayslipShareService? = nil,
         comparisonService: PayslipComparisonServiceProtocol? = nil,
         xRaySettings: (any XRaySettingsServiceProtocol)? = nil,
         allPayslips: [AnyPayslip]? = nil) {

        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        self.shareService = shareService ?? PayslipShareService.shared
        self.allPayslips = allPayslips

        // X-Ray services
        let featureContainer = DIContainer.shared.featureContainerPublic
        self.comparisonService = comparisonService ?? featureContainer.makePayslipComparisonService()
        self.xRaySettings = xRaySettings ?? featureContainer.makeXRaySettingsService()

        // Initialize component managers
        let resolvedPDFService = pdfService ?? PayslipPDFService.shared
        let resolvedFormatterService = formatterService ?? PayslipFormatterService.shared

        self.stateManager = PayslipDetailStateManager(payslip: payslip)
        self.pdfHandler = PayslipDetailPDFHandler(payslip: payslip, pdfService: resolvedPDFService)
        self.formatterService = PayslipDetailFormatterService(payslip: payslip, formatterService: resolvedFormatterService)

        // Initialize ActionsHandler with dependencies
        self.actionsHandler = PayslipDetailActionsHandler(
            stateManager: self.stateManager,
            pdfHandler: self.pdfHandler,
            payslip: payslip
        )

        // Set the initial payslip data from state manager
        self.payslipData = stateManager.payslipData

        // Set up property bindings to component managers
        self.setupPropertyBindings()

        // Subscribe to X-Ray toggle changes
        setupXRaySubscription()

        // Compute comparison if X-Ray is enabled
        if self.xRaySettings.isXRayEnabled, let payslips = allPayslips {
            self.computeComparison(with: payslips)
        }
    }

    deinit {
        // Clean up Combine subscriptions
        xRayToggleCancellable?.cancel()
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

    /// Forces regeneration of PDF data to apply updated formatting
    func forceRegeneratePDF() async {
        await pdfHandler.forceRegeneratePDF()
        stateManager.clearCaches()
    }

    /// Checks if this payslip is a manual entry that needs PDF regeneration
    var needsPDFRegeneration: Bool {
        return pdfHandler.needsPDFRegeneration
    }

    /// Automatically handles PDF regeneration if needed
    func handleAutomaticPDFRegeneration() async {
        await pdfHandler.handleAutomaticPDFRegeneration()
    }

    /// Enriches the payslip data with additional information from parsing
    func enrichPayslipData(with pdfData: [String: String]) {
        stateManager.enrichPayslipData(with: pdfData)
    }

    // MARK: - Formatting Methods (Delegated to FormatterService)

    func formatCurrency(_ value: Double?) -> String {
        return formatterService.formatCurrency(value)
    }

    func formatYear(_ year: Int) -> String {
        return formatterService.formatYear(year)
    }

    func getShareText() -> String {
        return formatterService.getShareText(for: payslipData)
    }

    // MARK: - Sharing Methods

    func getPDFURL() async throws -> URL? {
        return try await pdfHandler.getPDFURL()
    }

    func getShareItems() async -> [Any] {
        let pdfData = await pdfHandler.getPDFDataForSharing()
        let shareItems = formatterService.getShareItems(for: payslipData, pdfData: pdfData)
        stateManager.cacheShareItems(shareItems)
        return shareItems
    }

    func getShareItemsSync() -> [Any]? {
        if let cachedItems = stateManager.getCachedShareItems() {
            return cachedItems
        }
        let pdfData = pdfHandler.pdfData
        let shareItems = formatterService.getShareItems(for: payslipData, pdfData: pdfData)
        stateManager.cacheShareItems(shareItems)
        return shareItems
    }

    // MARK: - Update Methods

    func updatePayslipData(_ correctedData: PayslipData) {
        stateManager.updatePayslipData(correctedData)
        formatterService.clearFormattingCache()

        // Update local payslip reference after state manager updates it
        // Note: In a real app, we might want to observe the repository or use a more reactive approach
        // For now, we rely on the fact that stateManager updates the data
    }

    func userCategorizedComponent(code: String, asCategory: String) {
        stateManager.userCategorizedComponent(code: code, asCategory: asCategory)
    }

    // MARK: - Action Methods (Delegated to ActionsHandler)

    func printPDF(from presentingVC: UIViewController) {
        actionsHandler.printPDF(from: presentingVC)
    }

    func updateOtherEarnings(_ breakdown: [String: Double]) async {
        await actionsHandler.updateOtherEarnings(breakdown)
        // Update actions handler with current payslip
        self.actionsHandler.updatePayslip(self.payslip)
    }

    func updateOtherDeductions(_ breakdown: [String: Double]) async {
        await actionsHandler.updateOtherDeductions(breakdown)
        // Update actions handler with current payslip
        self.actionsHandler.updatePayslip(self.payslip)
    }

    // MARK: - Helper Methods

    func extractBreakdownFromPayslip(_ dict: [String: Double]) -> [String: Double] {
        var breakdown: [String: Double] = [:]
        let standardFields = ["Basic Pay", "Dearness Allowance", "Military Service Pay",
                             "Other Earnings", "DSOP", "AGIF", "Income Tax",
                             "Other Deductions"]

        for (key, value) in dict {
            if !standardFields.contains(key) {
                breakdown[key] = value
            }
        }
        return breakdown
    }

    // MARK: - Computed Properties (Delegated to FormatterService)

    var earningsBreakdown: [BreakdownItem] {
        return formatterService.getEarningsBreakdown(from: payslipData)
    }

    var deductionsBreakdown: [BreakdownItem] {
        return formatterService.getDeductionsBreakdown(from: payslipData)
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        stateManager.handleError(error)
    }

    // MARK: - X-Ray Comparison

    /// Sets up subscription to X-Ray toggle changes
    private func setupXRaySubscription() {
        xRayToggleCancellable = xRaySettings.xRayEnabledPublisher
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if let payslips = self.allPayslips {
                        self.computeComparison(with: payslips)
                    }
                }
            }
    }

    /// Computes comparison for the current payslip
    private func computeComparison(with allPayslips: [AnyPayslip]) {
        guard xRaySettings.isXRayEnabled else {
            // Clear comparison if X-Ray is disabled
            self.comparison = nil
            return
        }

        // Check cache first
        if let cached = PayslipComparisonCacheManager.shared.getComparison(for: payslip.id) {
            self.comparison = cached
            return
        }

        // Compute and cache
        let previous = comparisonService.findPreviousPayslip(for: payslip, in: allPayslips)
        let comparison = comparisonService.comparePayslips(current: payslip, previous: previous)
        self.comparison = comparison
        PayslipComparisonCacheManager.shared.setComparison(comparison, for: payslip.id)
    }
}
