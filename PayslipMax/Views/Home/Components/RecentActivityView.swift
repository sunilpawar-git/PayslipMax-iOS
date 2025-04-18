import SwiftUI

/// A view displaying recent payslip activity
struct RecentActivityView: View {
    let payslips: [AnyPayslip]
    
    var body: some View {
        VStack(spacing: 16) {
            // Recent Payslips in Vertical Ribbons
            ForEach(Array(payslips.prefix(3)), id: \.id) { payslip in
                NavigationLink {
                    PayslipNavigation.detailView(for: payslip)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        // Payslip Month and Year
                        Text("\(payslip.month) \(formatYear(payslip.year))")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // Credits and Debits in one line
                        HStack(spacing: 16) {
                            // Credits
                            HStack(spacing: 4) {
                                Text("Credits:")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                Text("₹\(formatCurrency(payslip.credits))/-")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                            
                            // Debits
                            HStack(spacing: 4) {
                                Text("Debits:")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                Text("₹\(formatCurrency(payslip.debits))/-")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            
            // View Previous Payslips Link
            NavigationLink(destination: PayslipsView(viewModel: DIContainer.shared.makePayslipsViewModel())) {
                Text("View Previous Payslips")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 1.0))
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 3) // Add padding to the entire VStack
    }
    
    // Helper function to format currency with Indian format
    private func formatCurrency(_ value: Double) -> String {
        // Don't format zero values as they might be actual data
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.secondaryGroupingSize = 2
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        
        let number = NSNumber(value: value)
        return formatter.string(from: number) ?? String(format: "%.0f", value)
    }
    
    // Helper function to format year without grouping
    private func formatYear(_ year: Int) -> String {
        return "\(year)"
    }
}

#Preview {
    RecentActivityView(payslips: [])
} 