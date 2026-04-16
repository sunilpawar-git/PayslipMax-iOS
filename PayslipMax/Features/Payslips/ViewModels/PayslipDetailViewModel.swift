import SwiftUI
import SwiftData
import Foundation
import Combine
import PDFKit

#if canImport(Vision)
import Vision
#endif

/// Coordinator that orchestrates PayslipDetailViewModel components while
/// preserving the original public interface for Views.
///
/// Component managers are `internal` (no access modifier) so that focused
/// extension files in this module can access them without exposing them
/// beyond the PayslipMax target.
@MainActor
class PayslipDetailViewModel: ObservableObject, @preconcurrency PayslipViewModelProtocol {

    // MARK: - Component Managers
    // internal access allows extension files in this module to delegate to them
    let stateManager: PayslipDetailStateManager
    let pdfHandler: PayslipDetailPDFHandler
    let formatterService: PayslipDetailFormatterService
    private let actionsHandler: PayslipDetailActionsHandler

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
    internal private(set) var payslip: AnyPayslip
    private let securityService: SecurityServiceProtocol
    private let dataService: DataServiceProtocol
    let comparisonService: PayslipComparisonServiceProtocol
    let comparisonCacheManager: PayslipComparisonCacheManagerProtocol
    var allPayslips: [AnyPayslip]?

    // MARK: - Public Properties
    let xRaySettings: any XRaySettingsServiceProtocol

    // MARK: - Combine
    var xRayToggleCancellable: AnyCancellable?

    // MARK: - Legacy Services (for backward compatibility)
    private let shareService: PayslipShareService

    // MARK: - Computed Properties

    var pdfFilename: String {
        formatterService.pdfFilename
    }

    /// Unique identifier for view caching and identity tracking.
    var uniqueViewId: String {
        "\(payslip.id)-\(payslip.month)-\(payslip.year)"
    }

    // MARK: - Initialization

    /// Initializes the coordinator with the specified payslip and optional
    /// service overrides (all default to shared production instances).
    init(payslip: AnyPayslip,
         securityService: SecurityServiceProtocol? = nil,
         dataService: DataServiceProtocol? = nil,
         pdfService: PayslipPDFService? = nil,
         formatterService: PayslipFormatterService? = nil,
         shareService: PayslipShareService? = nil,
         comparisonService: PayslipComparisonServiceProtocol? = nil,
         comparisonCacheManager: PayslipComparisonCacheManagerProtocol? = nil,
         xRaySettings: (any XRaySettingsServiceProtocol)? = nil,
         allPayslips: [AnyPayslip]? = nil) {

        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        self.shareService = shareService ?? PayslipShareService.shared
        self.allPayslips = allPayslips

        let featureContainer = DIContainer.shared.featureContainerPublic
        self.comparisonService = comparisonService ?? featureContainer.makePayslipComparisonService()
        self.comparisonCacheManager = comparisonCacheManager ?? featureContainer.makePayslipComparisonCacheManager()
        self.xRaySettings = xRaySettings ?? featureContainer.makeXRaySettingsService()

        let resolvedPDFService = pdfService ?? PayslipPDFService.shared
        let resolvedFormatterService = formatterService ?? PayslipFormatterService.shared

        self.stateManager = PayslipDetailStateManager(payslip: payslip)
        self.pdfHandler = PayslipDetailPDFHandler(payslip: payslip, pdfService: resolvedPDFService)
        self.formatterService = PayslipDetailFormatterService(
            payslip: payslip,
            formatterService: resolvedFormatterService
        )
        self.actionsHandler = PayslipDetailActionsHandler(
            stateManager: self.stateManager,
            pdfHandler: self.pdfHandler,
            payslip: payslip
        )

        self.payslipData = stateManager.payslipData
        self.setupPropertyBindings()
        self.setupXRaySubscription()

        if self.xRaySettings.isXRayEnabled, let payslips = allPayslips {
            self.computeComparison(with: payslips)
        }
    }

    deinit {
        xRayToggleCancellable?.cancel()
    }

    // MARK: - Setup

    private func setupPropertyBindings() {
        stateManager.$isLoading.assign(to: &$isLoading)
        stateManager.$error.assign(to: &$error)
        stateManager.$payslipData.assign(to: &$payslipData)
        stateManager.$showShareSheet.assign(to: &$showShareSheet)
        stateManager.$showDiagnostics.assign(to: &$showDiagnostics)
        stateManager.$showOriginalPDF.assign(to: &$showOriginalPDF)
        stateManager.$showPrintDialog.assign(to: &$showPrintDialog)
        stateManager.$unknownComponents.assign(to: &$unknownComponents)
        pdfHandler.$pdfData.assign(to: &$pdfData)
        pdfHandler.$contactInfo.assign(to: &$contactInfo)
    }

    // MARK: - Public Methods

    func loadAdditionalData() async {
        await pdfHandler.loadAdditionalData()
    }

    func forceRegeneratePDF() async {
        await pdfHandler.forceRegeneratePDF()
        stateManager.clearCaches()
    }

    var needsPDFRegeneration: Bool {
        pdfHandler.needsPDFRegeneration
    }

    func handleAutomaticPDFRegeneration() async {
        await pdfHandler.handleAutomaticPDFRegeneration()
    }

    func enrichPayslipData(with pdfData: [String: String]) {
        stateManager.enrichPayslipData(with: pdfData)
    }

    // MARK: - Update Methods

    func updatePayslipData(_ correctedData: PayslipData) {
        stateManager.updatePayslipData(correctedData)
        formatterService.clearFormattingCache()
        invalidateComparisons()
        refreshComparisonsIfNeeded()
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
        actionsHandler.updatePayslip(payslip)
        invalidateComparisons()
        refreshComparisonsIfNeeded()
    }

    func updateOtherDeductions(_ breakdown: [String: Double]) async {
        await actionsHandler.updateOtherDeductions(breakdown)
        actionsHandler.updatePayslip(payslip)
        invalidateComparisons()
        refreshComparisonsIfNeeded()
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        stateManager.handleError(error)
    }
}
