import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    @StateObject private var viewModel = DIContainer.shared.makeInsightsViewModel()
    
    @State private var selectedTimeRange: TimeRange = .year
    @State private var selectedInsightType: InsightType = .income
    @State private var selectedChartType: ChartType = .bar
    
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
                        
                        if viewModel.chartData.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("No data available")
                                    .font(.headline)
                                
                                Text("Upload more payslips to see insights")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                        } else {
                            if #available(iOS 16.0, *) {
                                Chart {
                                    ForEach(viewModel.chartData, id: \.id) { item in
                                        switch selectedChartType {
                                        case .bar:
                                            BarMark(
                                                x: .value("Period", item.label),
                                                y: .value("Amount", item.value)
                                            )
                                            .foregroundStyle(by: .value("Category", item.category))
                                        
                                        case .line:
                            LineMark(
                                                x: .value("Period", item.label),
                                                y: .value("Amount", item.value)
                                            )
                                            .foregroundStyle(by: .value("Category", item.category))
                                            .symbol(by: .value("Category", item.category))
                                        
                                        case .area:
                                            AreaMark(
                                                x: .value("Period", item.label),
                                                y: .value("Amount", item.value)
                                            )
                                            .foregroundStyle(by: .value("Category", item.category))
                                            .opacity(0.7)
                                        
                                        case .pie:
                                            if selectedInsightType == .breakdown {
                                                SectorMark(
                                                    angle: .value("Amount", item.value),
                                                    innerRadius: .ratio(0.5),
                                                    angularInset: 1.5
                                                )
                                                .foregroundStyle(by: .value("Category", item.category))
                                            } else {
                                                BarMark(
                                                    x: .value("Period", item.label),
                                                    y: .value("Amount", item.value)
                                                )
                                                .foregroundStyle(by: .value("Category", item.category))
                                            }
                                        }
                                    }
                                }
                                .frame(height: 250)
                            } else {
                                // Fallback for iOS 15
                                Text("Charts require iOS 16 or later")
                                    .frame(height: 250)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // Legend
                        HStack(spacing: 16) {
                            ForEach(viewModel.legendItems, id: \.label) { item in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 10, height: 10)
                                    
                                    Text(item.label)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Insights section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Insights")
                            .font(.headline)
                        
                        if viewModel.insights.isEmpty {
                            Text("Not enough data to generate insights")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(viewModel.insights, id: \.title) { insight in
                                HStack(spacing: 16) {
                                    Image(systemName: insight.iconName)
                                        .font(.title2)
                                        .foregroundColor(insight.color)
                                        .frame(width: 40, height: 40)
                                        .background(insight.color.opacity(0.2))
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(insight.title)
                                            .font(.headline)
                                        
                                        Text(insight.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Trends section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trends & Predictions")
                            .font(.headline)
                        
                        if viewModel.trends.isEmpty {
                            Text("Not enough data to analyze trends")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(viewModel.trends, id: \.title) { trend in
                                HStack(spacing: 16) {
                                    Image(systemName: trend.iconName)
                                        .font(.title2)
                                        .foregroundColor(trend.color)
                                        .frame(width: 40, height: 40)
                                        .background(trend.color.opacity(0.2))
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(trend.title)
                                            .font(.headline)
                                        
                                        Text(trend.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        if let value = trend.value {
                                            Text(value)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(trend.color.opacity(0.2))
                                                .cornerRadius(4)
                                                .padding(.top, 4)
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Financial Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshData(payslips: payslips.map { $0 as any PayslipItemProtocol })
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.error?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            viewModel.refreshData(payslips: payslips.map { $0 as any PayslipItemProtocol })
        }
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let value: String
    let trend: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                
                Spacer()
                
                if trend != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: trend > 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        
                        Text("\(String(format: "%.1f", abs(trend)))%")
                            .font(.caption2)
                    }
                    .foregroundColor(trend > 0 ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(trend > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    )
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: PayslipItem.self, inMemory: true)
} 