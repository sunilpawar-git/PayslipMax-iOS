import SwiftUI

/// A view displaying recent payslip activity
struct RecentActivityView: View {
    let payslips: [AnyPayslip]
    
    // Cache for formatted currency values
    @State private var formattedValues: [String: String] = [:]
    
    var body: some View {
        VStack(spacing: 16) {
            // Recent Payslips in Vertical Ribbons
            ForEach(Array(payslips.prefix(3)), id: \.id) { payslip in
                NavigationLink {
                    PayslipNavigation.detailView(for: payslip)
                } label: {
                    PayslipActivityCard(
                        payslip: payslip,
                        formattedCredits: getCachedFormattedValue(for: "credits-\(payslip.id)", value: payslip.credits),
                        formattedDebits: getCachedFormattedValue(for: "debits-\(payslip.id)", value: payslip.debits)
                    )
                    .equatable(PayslipActivityCardContent(payslip: payslip))
                    .stableId(id: "payslip-card-\(payslip.id)")
                }
                .buttonStyle(ScaleButtonStyle()) // Custom button style that reduces redraw
            }
            
            // View Previous Payslips Link
            NavigationLink(destination: PayslipsView(viewModel: DIContainer.shared.makePayslipsViewModel())) {
                Text("View Previous Payslips")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 1.0))
                    .padding(.top, 8)
            }
            .buttonStyle(PlainButtonStyle()) // Prevent default button styling
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 3) // Add padding to the entire VStack
        .onAppear {
            // Precompute all formatted values on background thread
            precalculateFormattedValues()
        }
    }
    
    // Precalculate all formatted values to avoid doing it during rendering
    private func precalculateFormattedValues() {
        BackgroundQueue.shared.async {
            var newValues: [String: String] = [:]
            
            for payslip in self.payslips.prefix(3) {
                let creditsKey = "credits-\(payslip.id)"
                let debitsKey = "debits-\(payslip.id)"
                
                newValues[creditsKey] = formatCurrency(payslip.credits)
                newValues[debitsKey] = formatCurrency(payslip.debits)
            }
            
            DispatchQueue.main.async {
                self.formattedValues = newValues
            }
        }
    }
    
    // Get cached formatted value or calculate it if not available
    private func getCachedFormattedValue(for key: String, value: Double) -> String {
        if let cached = formattedValues[key] {
            return cached
        }
        
        let formatted = formatCurrency(value)
        // Store for future use
        DispatchQueue.main.async {
            self.formattedValues[key] = formatted
        }
        return formatted
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

// Extracted card component for better performance
struct PayslipActivityCard: View {
    let payslip: AnyPayslip
    let formattedCredits: String
    let formattedDebits: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Payslip Month and Year
            Text("\(payslip.month) \(payslip.year)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            // Credits and Debits in one line
            HStack(spacing: 16) {
                // Credits
                HStack(spacing: 4) {
                    Text("Credits:")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Text("₹\(formattedCredits)/-")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                
                // Debits
                HStack(spacing: 4) {
                    Text("Debits:")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Text("₹\(formattedDebits)/-")
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

// Custom button style that scales the view on press but doesn't trigger redraws
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Helper struct for equatable comparison
struct PayslipActivityCardContent: Equatable {
    let payslip: AnyPayslip
    
    static func == (lhs: PayslipActivityCardContent, rhs: PayslipActivityCardContent) -> Bool {
        return lhs.payslip.id == rhs.payslip.id &&
               lhs.payslip.month == rhs.payslip.month &&
               lhs.payslip.year == rhs.payslip.year &&
               lhs.payslip.credits == rhs.payslip.credits &&
               lhs.payslip.debits == rhs.payslip.debits
    }
}

#Preview {
    RecentActivityView(payslips: [])
} 