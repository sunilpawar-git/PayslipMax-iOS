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
    
    // Filter payslips based on selected timeframe
    func filterPayslipsByTimeframe(_ payslips: [PayslipItem]) -> [PayslipItem] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case .threeMonths:
            guard let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) else {
                return payslips
            }
            return payslips.filter { $0.timestamp >= threeMonthsAgo }
            
        case .sixMonths:
            guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) else {
                return payslips
            }
            return payslips.filter { $0.timestamp >= sixMonthsAgo }
            
        case .oneYear:
            guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) else {
                return payslips
            }
            return payslips.filter { $0.timestamp >= oneYearAgo }
            
        case .all:
            return payslips
        }
    }
    
    func calculateMonthlyIncome(_ payslips: [PayslipItem]) -> [(month: String, amount: Double)] {
        let grouped = Dictionary(grouping: payslips) { $0.month }
        return grouped.map { (month: String($0.key), amount: $0.value.reduce(0) { $0 + $1.credits }) }
            .sorted { $0.month < $1.month }
    }
    
    func calculateDeductions(_ payslips: [PayslipItem]) -> [(type: String, amount: Double)] {
        guard let latest = payslips.first else { return [] }
        return [
            ("Tax", latest.tax),
            ("DSPOF", latest.dspof),
            ("Other", latest.debits - (latest.tax + latest.dspof))
        ]
    }
    
    func calculateYearlyTrend(_ payslips: [PayslipItem]) -> [(month: String, net: Double)] {
        return payslips
            .map { (month: String($0.month), net: $0.credits - $0.debits) }
            .sorted { $0.month < $1.month }
    }
    
    // Get color for deduction type
    func colorForDeductionType(_ type: String) -> Color {
        switch type {
        case "Tax":
            return .red
        case "DSPOF":
            return .blue
        default:
            return .orange
        }
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