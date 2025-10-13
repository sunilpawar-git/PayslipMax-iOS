import SwiftUI

/// Simplified payslip detail view focused on essential financial insights
/// Shows: Core earnings, Core deductions, Net remittance, Investment returns
struct SimplifiedPayslipDetailView: View {
    @ObservedObject var viewModel: SimplifiedPayslipViewModel
    @State private var showEarningsEditor = false
    @State private var showDeductionsEditor = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                headerSection
                
                // Net Remittance Card (Prominent)
                netRemittanceCard
                
                // Earnings Section
                earningsSection
                
                // Deductions Section
                deductionsSection
                
                // Investment Returns Insight
                InvestmentReturnsCard(
                    dsop: viewModel.payslip.dsop,
                    agif: viewModel.payslip.agif
                )
                
                // Confidence Indicator
                ConfidenceIndicator(score: viewModel.payslip.parsingConfidence)
                
                Spacer(minLength: 30)
            }
            .padding()
        }
        .navigationTitle("Payslip Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEarningsEditor) {
            MiscellaneousEarningsEditor(
                amount: viewModel.payslip.otherEarnings,
                breakdown: viewModel.payslip.otherEarningsBreakdown,
                onSave: { newBreakdown in
                    Task {
                        await viewModel.updateOtherEarnings(newBreakdown)
                    }
                }
            )
        }
        .sheet(isPresented: $showDeductionsEditor) {
            MiscellaneousDeductionsEditor(
                amount: viewModel.payslip.otherDeductions,
                breakdown: viewModel.payslip.otherDeductionsBreakdown,
                onSave: { newBreakdown in
                    Task {
                        await viewModel.updateOtherDeductions(newBreakdown)
                    }
                }
            )
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.payslip.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(viewModel.payslip.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Net Remittance Card
    
    private var netRemittanceCard: some View {
        VStack(spacing: 12) {
            Text("Net Remittance")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("₹\(viewModel.payslip.netRemittance, specifier: "%.0f")")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Take-home pay")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    // MARK: - Earnings Section
    
    private var earningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earnings")
                .font(.headline)
                .padding(.bottom, 4)
            
            earningsRow(label: "Basic Pay", amount: viewModel.payslip.basicPay)
            earningsRow(label: "Dearness Allowance", amount: viewModel.payslip.dearnessAllowance)
            earningsRow(label: "Military Service Pay", amount: viewModel.payslip.militaryServicePay)
            
            HStack {
                Text("Other Earnings")
                    .foregroundColor(.secondary)
                Spacer()
                Text("₹\(viewModel.payslip.otherEarnings, specifier: "%.0f")")
                    .fontWeight(.medium)
                Button {
                    showEarningsEditor = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            HStack {
                Text("Gross Pay")
                    .fontWeight(.semibold)
                Spacer()
                Text("₹\(viewModel.payslip.grossPay, specifier: "%.0f")")
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func earningsRow(label: String, amount: Double) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text("₹\(amount, specifier: "%.0f")")
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Deductions Section
    
    private var deductionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deductions")
                .font(.headline)
                .padding(.bottom, 4)
            
            deductionsRow(label: "DSOP", amount: viewModel.payslip.dsop)
            deductionsRow(label: "AGIF", amount: viewModel.payslip.agif)
            deductionsRow(label: "Income Tax", amount: viewModel.payslip.incomeTax)
            
            HStack {
                Text("Other Deductions")
                    .foregroundColor(.secondary)
                Spacer()
                Text("₹\(viewModel.payslip.otherDeductions, specifier: "%.0f")")
                    .fontWeight(.medium)
                Button {
                    showDeductionsEditor = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            HStack {
                Text("Total Deductions")
                    .fontWeight(.semibold)
                Spacer()
                Text("₹\(viewModel.payslip.totalDeductions, specifier: "%.0f")")
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func deductionsRow(label: String, amount: Double) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text("₹\(amount, specifier: "%.0f")")
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SimplifiedPayslipDetailView(
            viewModel: SimplifiedPayslipViewModel(
                payslip: .createSample(),
                dataService: MockDataService()
            )
        )
    }
}

// MARK: - Mock Data Service for Preview

private class MockDataService: SimplifiedPayslipDataService {
    func save(_ payslip: SimplifiedPayslip) async throws {}
    func fetchAll() async -> [SimplifiedPayslip] { [] }
    func delete(_ payslip: SimplifiedPayslip) async throws {}
}

