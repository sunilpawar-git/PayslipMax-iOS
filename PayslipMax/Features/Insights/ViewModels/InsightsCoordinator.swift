import Foundation
import SwiftUI
import Combine

/// Coordinator that orchestrates all insights-related ViewModels.
/// This replaces the monolithic InsightsViewModel and follows the coordinator pattern.
@MainActor
class InsightsCoordinator: ObservableObject {

    // MARK: - Published Properties

    /// Whether the coordinator is loading data.
    @Published var isLoading = false

    /// The error to display to the user.
    @Published var error: String?

    /// The current time range.
    @Published var timeRange: TimeRange = .year {
        didSet {
            updateTimeRange(timeRange)
        }
    }

    /// The current insight type.
    @Published var insightType: InsightType = .income {
        didSet {
            updateInsightType(insightType)
        }
    }

    /// The insights to display.
    @Published var insights: [InsightItem] = []

    // MARK: - Child ViewModels

    /// Handles financial summary calculations.
    let financialSummary: FinancialSummaryViewModel

    /// Handles trend analysis.
    let trendAnalysis: TrendAnalysisViewModel

    /// Handles chart data preparation.
    let chartData: ChartDataViewModel

    // MARK: - Services

    /// Service responsible for generating insights.
    private let insightGenerator: InsightGenerationService

    // MARK: - Private Properties

    /// The payslips to analyze.
    private var payslips: [PayslipDTO] = []

    /// The repository for Sendable payslip operations.
    private let repository: SendablePayslipRepository

    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Earnings-related insights (income performance and growth).
    var earningsInsights: [InsightItem] {
        return insights.filter { insight in
            return [
                "Earnings Growth",
                "Net Remittance Rate",
                "Top Income Component"
            ].contains(insight.title)
        }
    }

    /// Deductions-related insights (tax, DSOP, AGIF).
    var deductionsInsights: [InsightItem] {
        return insights.filter { insight in
            return [
                "Tax Rate",
                "DSOP Contribution",
                "Deduction Percentage"
            ].contains(insight.title)
        }
    }

    // MARK: - Initialization

    /// Initializes a new InsightsCoordinator.
    ///
    /// - Parameter dataService: The data service to use for fetching data.
    init(dataService: DataServiceProtocol? = nil) {
        let service = dataService ?? DIContainer.shared.dataService
        self.repository = DIContainer.shared.makeSendablePayslipRepository()

        // Initialize child ViewModels
        self.financialSummary = FinancialSummaryViewModel()
        self.trendAnalysis = TrendAnalysisViewModel(dataService: service)
        self.chartData = ChartDataViewModel(dataService: service)

        // Initialize insight generation service
        self.insightGenerator = InsightGenerationService(
            financialSummary: self.financialSummary,
            trendAnalysis: self.trendAnalysis
        )

        setupBindings()
    }

    // MARK: - Public Methods

    /// Refreshes the data with the specified payslips.
    ///
    /// - Parameter payslips: The payslips to analyze (should already be filtered).
    func refreshData(payslips: [PayslipDTO]) {
        isLoading = true

        // Use the passed payslips directly (they are already filtered by the view)
        self.payslips = payslips

        // Update all child ViewModels
        updateChildViewModels()

        // Generate insights
        generateInsights()

        isLoading = false
    }

    /// Updates the time range and refreshes the data.
    ///
    /// - Parameter timeRange: The new time range.
    func updateTimeRange(_ timeRange: TimeRange) {
        chartData.updateTimeRange(timeRange)
    }

    /// Updates the insight type and refreshes the data.
    ///
    /// - Parameter insightType: The new insight type.
    func updateInsightType(_ insightType: InsightType) {
        chartData.updateInsightType(insightType)
    }

    // MARK: - Private Methods

    /// Sets up bindings between child ViewModels.
    private func setupBindings() {
        // Combine loading states
        Publishers.CombineLatest3(
            financialSummary.$isLoading,
            trendAnalysis.$isLoading,
            chartData.$isLoading
        )
        .map { $0 || $1 || $2 }
        .assign(to: &$isLoading)

        // Combine error states
        Publishers.CombineLatest3(
            financialSummary.$error,
            trendAnalysis.$error,
            chartData.$error
        )
        .map { error1, error2, error3 in
            error1 ?? error2 ?? error3
        }
        .assign(to: &$error)
    }

    /// Updates all child ViewModels with current payslips data.
    private func updateChildViewModels() {
        financialSummary.updatePayslips(payslips)
        trendAnalysis.updatePayslips(payslips)
        chartData.updatePayslips(payslips)
    }

    /// Generates insights based on the payslips data.
    private func generateInsights() {
        insights = insightGenerator.generateAllInsights(for: payslips)
    }

}
