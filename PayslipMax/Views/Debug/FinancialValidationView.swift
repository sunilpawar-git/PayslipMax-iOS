import SwiftUI
import SwiftData

/// Debug view for validating financial calculations consistency across payslips.
/// Helps identify double-counting issues and calculation inconsistencies.
struct FinancialValidationView: View {
    @Query(sort: \PayslipItem.timestamp, order: .reverse) private var payslips: [PayslipItem]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Overall validation summary
                    validationSummaryCard
                    
                    // Per-payslip validation
                    ForEach(payslips.prefix(10), id: \.id) { payslip in
                        PayslipValidationCard(payslip: payslip)
                    }
                }
                .padding()
            }
            .navigationTitle("Financial Validation")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var validationSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(FintechColors.primaryBlue)
                
                Text("Validation Summary")
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                Text("\(payslips.count) payslips")
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }
            
            let totalIssues = payslips.reduce(0) { total, payslip in
                total + FinancialCalculationUtility.shared.validateFinancialConsistency(for: payslip).count
            }
            
            HStack {
                Text("Total Issues Found:")
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
                
                Spacer()
                
                Text("\(totalIssues)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(totalIssues > 0 ? FintechColors.dangerRed : FintechColors.successGreen)
            }
            
            // Show calculation comparison
            let legacyTotal = payslips.reduce(0) { $0 + ($1.debits + $1.tax + $1.dsop) }
            let correctTotal = FinancialCalculationUtility.shared.aggregateTotalDeductions(for: payslips)
            let difference = legacyTotal - correctTotal
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Calculation Comparison")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                
                HStack {
                    Text("Legacy (wrong) total:")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Spacer()
                    
                    Text("₹\(Formatters.formatIndianCurrency(legacyTotal))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.dangerRed)
                }
                
                HStack {
                    Text("Correct total:")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Spacer()
                    
                    Text("₹\(Formatters.formatIndianCurrency(correctTotal))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.successGreen)
                }
                
                if abs(difference) > 1.0 {
                    HStack {
                        Text("Difference (over-counted):")
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                        
                        Spacer()
                        
                        Text("₹\(Formatters.formatIndianCurrency(difference))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(FintechColors.warningAmber)
                    }
                }
            }
        }
        .fintechCardStyle()
    }
}

struct PayslipValidationCard: View {
    let payslip: PayslipItem
    
    private var validationIssues: [String] {
        return FinancialCalculationUtility.shared.validateFinancialConsistency(for: payslip)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(payslip.month) \(payslip.year)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
                
                if validationIssues.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(FintechColors.successGreen)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(FintechColors.warningAmber)
                }
            }
            
            // Financial breakdown
            VStack(alignment: .leading, spacing: 4) {
                FinancialRowView(
                    label: "Credits",
                    value: payslip.credits,
                    color: FintechColors.successGreen
                )
                
                FinancialRowView(
                    label: "Debits (total)",
                    value: payslip.debits,
                    color: FintechColors.dangerRed
                )
                
                FinancialRowView(
                    label: "DSOP (component)",
                    value: payslip.dsop,
                    color: FintechColors.textSecondary,
                    isIndented: true
                )
                
                FinancialRowView(
                    label: "Tax (component)",
                    value: payslip.tax,
                    color: FintechColors.textSecondary,
                    isIndented: true
                )
                
                let netLegacy = payslip.credits - (payslip.debits + payslip.tax + payslip.dsop)
                let netCorrect = FinancialCalculationUtility.shared.calculateNetIncome(for: payslip)
                
                Divider()
                
                FinancialRowView(
                    label: "Net (legacy - wrong)",
                    value: netLegacy,
                    color: FintechColors.dangerRed
                )
                
                FinancialRowView(
                    label: "Net (correct)",
                    value: netCorrect,
                    color: FintechColors.successGreen
                )
                
                if abs(netLegacy - netCorrect) > 1.0 {
                    FinancialRowView(
                        label: "Difference",
                        value: netLegacy - netCorrect,
                        color: FintechColors.warningAmber
                    )
                }
            }
            
            // Deductions breakdown
            if !payslip.deductions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deductions Breakdown:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    ForEach(Array(payslip.deductions.keys.sorted()), id: \.self) { key in
                        if let value = payslip.deductions[key], value > 0 {
                            HStack {
                                Text("• \(key)")
                                    .font(.caption)
                                    .foregroundColor(FintechColors.textSecondary)
                                
                                Spacer()
                                
                                Text("₹\(Formatters.formatIndianCurrency(value))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(FintechColors.textPrimary)
                            }
                            .padding(.leading, 16)
                        }
                    }
                    
                    let deductionSum = payslip.deductions.values.reduce(0, +)
                    HStack {
                        Text("Sum of breakdown:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(FintechColors.textSecondary)
                        
                        Spacer()
                        
                        Text("₹\(Formatters.formatIndianCurrency(deductionSum))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(deductionSum == payslip.debits ? FintechColors.successGreen : FintechColors.warningAmber)
                    }
                    .padding(.leading, 16)
                }
            }
            
            // Show validation issues
            if !validationIssues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Issues Found:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.dangerRed)
                    
                    ForEach(validationIssues, id: \.self) { issue in
                        HStack(alignment: .top, spacing: 4) {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(FintechColors.dangerRed)
                            
                            Text(issue)
                                .font(.caption)
                                .foregroundColor(FintechColors.dangerRed)
                        }
                        .padding(.leading, 8)
                    }
                }
            }
        }
        .fintechCardStyle()
    }
}

struct FinancialRowView: View {
    let label: String
    let value: Double
    let color: Color
    var isIndented: Bool = false
    
    var body: some View {
        HStack {
            Text(isIndented ? "  • \(label)" : label)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
            
            Spacer()
            
            Text("₹\(Formatters.formatIndianCurrency(value))")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

#Preview {
    FinancialValidationView()
} 