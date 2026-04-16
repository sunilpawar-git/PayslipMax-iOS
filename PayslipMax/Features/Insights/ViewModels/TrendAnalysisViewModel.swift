import Foundation
import SwiftUI
import Combine

/// ViewModel responsible for trend analysis and income stability calculations.
/// Extracted from InsightsViewModel to follow single responsibility principle.
@MainActor
class TrendAnalysisViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Whether the view model is loading data.
    @Published var isLoading = false

    /// The error to display to the user.
    @Published var error: String?

    /// The trends to display.
    @Published var trends: [TrendItem] = []

    // MARK: - Properties

    /// The payslips to analyze.
    var payslips: [PayslipDTO] = []

    /// The data service to use for fetching data.
    let dataService: DataServiceProtocol

    /// The cancellables for managing subscriptions.
    var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Income stability description.
    var incomeStabilityDescription: String {
        let variation = incomeVariation
        let avgIncome = payslips.map { $0.credits }.average ?? 0

        guard avgIncome > 0 else { return "Insufficient Data" }

        let variationPercentage = (variation / avgIncome) * 100

        if variationPercentage < 5 {
            return "Very Stable"
        } else if variationPercentage < 15 {
            return "Moderately Stable"
        } else {
            return "Variable"
        }
    }

    /// Income stability color.
    var incomeStabilityColor: Color {
        let description = incomeStabilityDescription
        switch description {
        case "Very Stable": return FintechColors.successGreen
        case "Moderately Stable": return FintechColors.primaryBlue
        case "Variable": return FintechColors.warningAmber
        default: return FintechColors.textSecondary
        }
    }

    /// Income variation amount.
    var incomeVariation: Double {
        let incomes = payslips.map { $0.credits }
        guard let stdDev = incomes.standardDeviation else { return 0 }
        return stdDev
    }

    /// Stability analysis text.
    var stabilityAnalysis: String {
        let variation = incomeVariation
        let avgIncome = payslips.map { $0.credits }.average ?? 0

        guard avgIncome > 0 else { return "Need more data for analysis" }

        let variationPercentage = (variation / avgIncome) * 100

        if variationPercentage < 5 {
            return "Your income is very consistent month to month, indicating stable employment."
        } else if variationPercentage < 15 {
            return "Your income has some variation, which is normal for most jobs with variable components."
        } else {
            return "Your income varies significantly. Consider reviewing variable pay components."
        }
    }

    // MARK: - Initialization

    /// Initializes a new TrendAnalysisViewModel.
    ///
    /// - Parameter dataService: The data service to use for fetching data.
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
    }

    // MARK: - Public Methods

    /// Updates the payslips data for analysis.
    ///
    /// - Parameter payslips: The payslips to analyze.
    func updatePayslips(_ payslips: [PayslipDTO]) {
        self.payslips = payslips
        generateTrends()
    }

}

