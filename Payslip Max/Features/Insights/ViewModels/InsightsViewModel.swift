import SwiftUI
import SwiftData
import Charts

@MainActor
final class InsightsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var selectedTimeframe: Timeframe = .sixMonths
    @Published var selectedChartType: ChartType = .income
    
    // MARK: - Properties
    private let dataService: DataServiceProtocol
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
    }
    
    // MARK: - Public Methods
    func calculateMonthlyIncome(_ payslips: [PayslipItem]) -> [(month: String, amount: Double)] {
        let grouped = Dictionary(grouping: payslips) { $0.month }
        return grouped.map { (month: $0.key, amount: $0.value.reduce(0) { $0 + $1.credits }) }
            .sorted { $0.month < $1.month }
    }
    
    func calculateDeductions(_ payslips: [PayslipItem]) -> [(type: String, amount: Double)] {
        guard let latest = payslips.first else { return [] }
        return [
            ("Tax", latest.tax),
            ("DSOPF", latest.dsopf),
            ("Other", latest.debits - (latest.tax + latest.dsopf))
        ]
    }
    
    func calculateYearlyTrend(_ payslips: [PayslipItem]) -> [(month: String, net: Double)] {
        return payslips
            .map { (month: $0.month, net: $0.credits - $0.debits) }
            .sorted { $0.month < $1.month }
    }
    
    // MARK: - Supporting Types
    enum Timeframe {
        case threeMonths
        case sixMonths
        case oneYear
        case all
    }
    
    enum ChartType {
        case income
        case deductions
        case trend
    }
} 