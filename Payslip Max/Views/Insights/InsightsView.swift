import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Monthly Income Chart
                    ChartSection(title: "Monthly Income") {
                        Chart(payslips.prefix(6)) { payslip in
                            BarMark(
                                x: .value("Month", payslip.month),
                                y: .value("Credits", payslip.credits)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                    }
                    
                    // Deductions Breakdown
                    ChartSection(title: "Deductions Breakdown") {
                        Chart(payslips.prefix(1)) { payslip in
                            SectorMark(
                                angle: .value("Amount", payslip.tax),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .foregroundStyle(.red.gradient)
                            
                            SectorMark(
                                angle: .value("Amount", payslip.dsopf),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                    }
                    
                    // Yearly Summary
                    ChartSection(title: "Yearly Summary") {
                        Chart(payslips) { payslip in
                            LineMark(
                                x: .value("Month", payslip.month),
                                y: .value("Net", payslip.credits - payslip.debits)
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