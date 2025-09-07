import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    @StateObject private var coordinator: InsightsCoordinator
    @State private var selectedTimeRange: FinancialTimeRange = .last3Months
    
    init(coordinator: InsightsCoordinator? = nil) {
        // Use provided coordinator or create one from DIContainer
        let model = coordinator ?? DIContainer.shared.makeInsightsCoordinator()
        self._coordinator = StateObject(wrappedValue: model)
    }
    
    // Computed property to filter payslips based on selected time range
    private var filteredPayslips: [PayslipItem] {
        return InsightsChartHelpers.filterPayslips(Array(payslips), for: selectedTimeRange)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                FintechColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Time range picker - Controls entire screen data
                        InsightsTimeRangePicker(selectedTimeRange: $selectedTimeRange)
                        
                        // Enhanced integrated financial overview with charts
                        InsightsFinancialOverviewSection(
                            coordinator: coordinator,
                            filteredPayslips: filteredPayslips,
                            selectedTimeRange: selectedTimeRange
                        )
                        
                        // Key insights
                        InsightsKeyInsightsSection(coordinator: coordinator)
                        
                        // Detailed analysis
                        InsightsDetailedAnalysisSection(coordinator: coordinator)
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print("🔍 InsightsView onAppear: Refreshing with \(filteredPayslips.count) filtered payslips")
                coordinator.refreshData(payslips: filteredPayslips)
            }
            .onChange(of: selectedTimeRange) {
                print("🔍 InsightsView time range changed to \(selectedTimeRange): Refreshing with \(filteredPayslips.count) filtered payslips")
                // Update coordinator when time range changes
                coordinator.refreshData(payslips: filteredPayslips)
            }
        }
    }
    
}
