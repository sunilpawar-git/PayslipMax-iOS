import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    @StateObject private var viewModel = InsightsViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Timeframe Picker
                    Picker("Timeframe", selection: $viewModel.selectedTimeframe) {
                        Text("3 Months").tag(InsightsViewModel.Timeframe.threeMonths)
                        Text("6 Months").tag(InsightsViewModel.Timeframe.sixMonths)
                        Text("1 Year").tag(InsightsViewModel.Timeframe.oneYear)
                        Text("All").tag(InsightsViewModel.Timeframe.all)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Monthly Income Chart
                    ChartSection(title: "Monthly Income") {
                        Chart(viewModel.calculateMonthlyIncome(filteredPayslips), id: \.month) { item in
                            BarMark(
                                x: .value("Month", item.month),
                                y: .value("Credits", item.amount)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                    }
                    
                    // Deductions Breakdown
                    ChartSection(title: "Deductions Breakdown") {
                        Chart(viewModel.calculateDeductions(filteredPayslips), id: \.type) { item in
                            SectorMark(
                                angle: .value("Amount", item.amount),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .foregroundStyle(viewModel.colorForDeductionType(item.type).gradient)
                        }
                    }
                    
                    // Yearly Summary
                    ChartSection(title: "Yearly Summary") {
                        Chart(viewModel.calculateYearlyTrend(filteredPayslips), id: \.month) { item in
                            LineMark(
                                x: .value("Month", item.month),
                                y: .value("Net", item.net)
                            )
                            .foregroundStyle(.green.gradient)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }
    
    // Use the ViewModel's filtering method
    private var filteredPayslips: [PayslipItem] {
        return viewModel.filterPayslipsByTimeframe(payslips)
    }
}

private struct ChartSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            content
                .frame(height: 200)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: PayslipItem.self, inMemory: true)
} 