import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    @StateObject private var viewModel: InsightsViewModel
    
    @State private var selectedTimeRange: TimeRange = .year
    @State private var selectedInsightType: InsightType = .income
    @State private var selectedChartType: ChartType = .bar
    
    init(viewModel: InsightsViewModel? = nil) {
        // Use provided viewModel or create one from DIContainer
        let model = viewModel ?? DIContainer.shared.makeInsightsViewModel()
        self._viewModel = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range selector
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTimeRange) { _, newValue in
                        viewModel.updateTimeRange(newValue)
                    }
                    
                    // Summary cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            SummaryCard(
                                title: "Total Income",
                                value: "₹\(String(format: "%.2f", viewModel.totalIncome))",
                                trend: viewModel.incomeTrend,
                                icon: "arrow.up.right",
                                color: .green
                            )
                            
                            SummaryCard(
                                title: "Total Deductions",
                                value: "₹\(String(format: "%.2f", viewModel.totalDeductions))",
                                trend: viewModel.deductionsTrend,
                                icon: "arrow.down.right",
                                color: .red
                            )
                            
                            SummaryCard(
                                title: "Net Income",
                                value: "₹\(String(format: "%.2f", viewModel.netIncome))",
                                trend: viewModel.netIncomeTrend,
                                icon: "creditcard",
                                color: .blue
                            )
                            
                            SummaryCard(
                                title: "Tax Paid",
                                value: "₹\(String(format: "%.2f", viewModel.totalTax))",
                                trend: viewModel.taxTrend,
                                icon: "building.columns",
                                color: .purple
                            )
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    // Chart section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Financial Overview")
                                .font(.headline)
                            
                            Spacer()
                            
                            Picker("Chart Type", selection: $selectedChartType) {
                                ForEach(ChartType.allCases, id: \.self) { type in
                                    Label(type.displayName, systemImage: type.iconName).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Data Type", selection: $selectedInsightType) {
                                ForEach(InsightType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        InsightsChartView(
                            chartData: viewModel.chartData,
                            legendItems: viewModel.legendItems,
                            selectedChartType: selectedChartType
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Insights section
                    InsightsListView(insights: viewModel.insights)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Insights")
            .onAppear {
                viewModel.refreshData(payslips: payslips)
            }
        }
    }
} 