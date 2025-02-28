import SwiftUI
import Charts

/// View model for the insights screen
class InsightsViewModel: ObservableObject {
    /// Data service for fetching payslips
    private let dataService: DataServiceProtocol
    
    /// Published payslips
    @Published var payslips: [PayslipItem] = []
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message
    @Published var errorMessage: String?
    
    /// Initializes a new insights view model
    /// - Parameter dataService: The data service
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
        
        // Load placeholder data
        loadPlaceholderData()
    }
    
    /// Loads placeholder data for preview
    private func loadPlaceholderData() {
        payslips = [
            PayslipItem(id: UUID(), title: "May 2023", amount: 3250.00, date: Date()),
            PayslipItem(id: UUID(), title: "April 2023", amount: 3250.00, date: Date().addingTimeInterval(-2592000)),
            PayslipItem(id: UUID(), title: "March 2023", amount: 3100.00, date: Date().addingTimeInterval(-5184000)),
            PayslipItem(id: UUID(), title: "February 2023", amount: 3100.00, date: Date().addingTimeInterval(-7776000)),
            PayslipItem(id: UUID(), title: "January 2023", amount: 3000.00, date: Date().addingTimeInterval(-10368000)),
            PayslipItem(id: UUID(), title: "December 2022", amount: 3000.00, date: Date().addingTimeInterval(-12960000))
        ]
    }
}

/// Insights view displaying charts and statistics
struct InsightsView: View {
    /// View model for the insights screen
    @ObservedObject var viewModel: InsightsViewModel
    
    /// Navigation router
    @EnvironmentObject private var router: NavRouter
    
    /// Selected time period
    @State private var selectedPeriod = "6 Months"
    
    /// Available time periods
    private let periods = ["3 Months", "6 Months", "1 Year", "All Time"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period selector
                Picker("Time Period", selection: $selectedPeriod) {
                    ForEach(periods, id: \.self) { period in
                        Text(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Income chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Income Trend")
                        .font(.headline)
                    
                    if #available(iOS 16.0, macOS 13.0, *) {
                        Chart {
                            ForEach(viewModel.payslips) { payslip in
                                LineMark(
                                    x: .value("Month", payslip.title),
                                    y: .value("Amount", payslip.amount)
                                )
                                .foregroundStyle(.blue)
                                
                                PointMark(
                                    x: .value("Month", payslip.title),
                                    y: .value("Amount", payslip.amount)
                                )
                                .foregroundStyle(.blue)
                            }
                        }
                        .frame(height: 200)
                    } else {
                        // Fallback for older OS versions
                        Text("Charts are available on iOS 16+ and macOS 13+")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Summary statistics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary")
                        .font(.headline)
                    
                    HStack {
                        statCard(title: "Average", value: "$3,116.67")
                        statCard(title: "Highest", value: "$3,250.00")
                    }
                    
                    HStack {
                        statCard(title: "Lowest", value: "$3,000.00")
                        statCard(title: "Total", value: "$18,700.00")
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Breakdown")
                        .font(.headline)
                    
                    if #available(iOS 16.0, macOS 13.0, *) {
                        Chart {
                            SectorMark(
                                angle: .value("Value", 70),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(.blue)
                            .annotation(position: .overlay) {
                                Text("70%")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            
                            SectorMark(
                                angle: .value("Value", 20),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(.green)
                            .annotation(position: .overlay) {
                                Text("20%")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                            
                            SectorMark(
                                angle: .value("Value", 10),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(.orange)
                            .annotation(position: .overlay) {
                                Text("10%")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(height: 200)
                    } else {
                        // Fallback for older OS versions
                        Text("Charts are available on iOS 16+ and macOS 13+")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    
                    VStack(spacing: 8) {
                        legendItem(color: .blue, label: "Base Salary", value: "70%")
                        legendItem(color: .green, label: "Allowances", value: "20%")
                        legendItem(color: .orange, label: "Bonuses", value: "10%")
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Insights")
    }
    
    /// Creates a stat card
    /// - Parameters:
    ///   - title: The stat title
    ///   - value: The stat value
    /// - Returns: A stat card view
    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    /// Creates a legend item
    /// - Parameters:
    ///   - color: The item color
    ///   - label: The item label
    ///   - value: The item value
    /// - Returns: A legend item view
    private func legendItem(color: Color, label: String, value: String) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView(viewModel: InsightsViewModel(dataService: MockDataService()))
            .environmentObject(NavRouter())
    }
} 