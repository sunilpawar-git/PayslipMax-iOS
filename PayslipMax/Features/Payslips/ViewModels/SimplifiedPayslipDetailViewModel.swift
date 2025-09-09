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
    @Published var payslipData: PayslipData
    @Published var showShareSheet = false
    @Published var showDiagnostics = false
    @Published var showOriginalPDF = false
    @Published var unknownComponents: [String: (Double, String)] = [:]

    // MARK: - Private Properties
    private(set) var payslip: AnyPayslip
    private let securityService: SecurityServiceProtocol
    private let dataService: DataServiceProtocol
    private let sharingService: PayslipSharingServiceProtocol
    private let dataEnrichmentService: PayslipDataEnrichmentServiceProtocol
    private let categorizationService: ComponentCategorizationServiceProtocol
    private let errorHandler: ErrorHandlingUtility

    // MARK: - Public Properties
    var pdfFilename: String

    // MARK: - Properties
    // Note: Unified architecture - no longer needs separate parser

    // MARK: - Initialization

    /// Initializes a new PayslipDetailViewModel with the specified payslip and services.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to display details for.
    ///   - securityService: The security service to use for sensitive data operations.
    ///   - dataService: The data service to use for saving data.
    ///   - sharingService: The sharing service for payslip sharing functionality.
    ///   - dataEnrichmentService: The service for enriching payslip data.
    ///   - categorizationService: The service for component categorization.
    ///   - errorHandler: The utility for error handling.
    init(
        payslip: AnyPayslip,
        securityService: SecurityServiceProtocol? = nil,
        dataService: DataServiceProtocol? = nil,
        sharingService: PayslipSharingServiceProtocol? = nil,
        dataEnrichmentService: PayslipDataEnrichmentServiceProtocol? = nil,
        categorizationService: ComponentCategorizationServiceProtocol? = nil,
        errorHandler: ErrorHandlingUtility? = nil
    ) {
        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        self.sharingService = sharingService ?? DIContainer.shared.makePayslipSharingService()
        self.dataEnrichmentService = dataEnrichmentService ?? DIContainer.shared.makePayslipDataEnrichmentService()
        self.categorizationService = categorizationService ?? DIContainer.shared.makeComponentCategorizationService()
        self.errorHandler = errorHandler ?? DIContainer.shared.makeErrorHandlingUtility()

        // Set the PDF filename
        let month = payslip.month
        let year = String(payslip.year)
        self.pdfFilename = "Payslip_\(month)_\(year).pdf"

        // Set the initial payslip data
        self.payslipData = PayslipData(from: payslip)

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

        guard let payslipItem = payslip as? PayslipItem,
              let pdfData = payslipItem.pdfData,
              PDFDocument(data: pdfData) != nil else {
            return
        }

        // Use the unified PDF processing service to extract additional data
        let pdfService = DIContainer.shared.makePDFService()
        let extractedData = pdfService.extract(pdfData)

        // Update the payslipData with additional info from parsing
        payslipData = dataEnrichmentService.enrichPayslipData(payslipData, with: extractedData)
    }

    /// Enriches the payslip data with additional information from parsing
    func enrichPayslipData(with pdfData: [String: String]) {
        payslipData = dataEnrichmentService.enrichPayslipData(payslipData, with: pdfData)
    }

    /// Formats a value as a currency string.
    ///
    /// - Parameter value: The value to format.
    /// - Returns: A formatted currency string.
    func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "0" }
        return CurrencyFormatter.format(value)
    }

    /// Formats a year value without group separators
    func formatYear(_ year: Int) -> String {
        return "\(year)" // Simple string conversion without formatting
    }

    /// Gets a formatted string representation of the payslip for sharing.
    ///
    /// - Returns: A formatted string with payslip details.
    func getShareText() -> String {
        return sharingService.getShareText(for: payslipData)
    }

    /// Gets both text and PDF data for sharing if available
    /// - Returns: An array of items to share
    func getShareItems() async -> [Any] {
        return await sharingService.getShareItems(for: payslipData, payslip: payslip)
    }

    /// Get the URL for sharing the PDF
    func getPDFURL() async throws -> URL? {
        return try await sharingService.getPDFURL(for: payslip)
    }

    /// Updates the payslip with corrected data.
    ///
    /// - Parameter correctedData: The corrected payslip data.
    func updatePayslipData(_ correctedData: PayslipData) {
        Task {
            do {
                guard let payslipItem = payslip as? PayslipItem else {
                    self.error = AppError.message("Cannot update payslip: Invalid payslip type")
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
                errorHandler.handleAndUpdateError(error, errorProperty: &self.error)
            }
        }
    }

    // MARK: - Private Methods

    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        errorHandler.handleAndUpdateError(error, errorProperty: &self.error)
    }

    // MARK: - Component Categorization

    /// Called when a user categorizes an unknown component
    func userCategorizedComponent(code: String, asCategory: String) {
        categorizationService.categorizeComponent(
            code: code,
            asCategory: asCategory,
            unknownComponents: &unknownComponents,
            payslipData: &payslipData
        )
    }
}
