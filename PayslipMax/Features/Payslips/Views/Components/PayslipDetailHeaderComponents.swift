import SwiftUI
import PDFKit
import Foundation

// MARK: - Payslip Detail Header Component Views

struct PayslipDetailHeaderView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel
    @State private var showConfidenceDetail = false

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Month/Year with inline confidence badge (best UX practice)
            HStack(spacing: 8) {
                Text("\(viewModel.payslip.month) \(viewModel.formatYear(viewModel.payslip.year))")
                    .font(.title)
                    .fontWeight(.bold)

                // Shield badge inline with title (like verification badges)
                if let confidenceScore = extractConfidenceScore() {
                    Button(action: {
                        showConfidenceDetail = true
                    }) {
                        ConfidenceBadgeShield(confidence: confidenceScore, showPercentage: true)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Process name to remove last initial if it's just a single character
            Text(formatName(viewModel.payslip.name))
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(FintechColors.backgroundGray)
        .cornerRadius(12)
        .sheet(isPresented: $showConfidenceDetail) {
            if let payslipItem = viewModel.payslip as? PayslipItem,
               let confidence = payslipItem.confidenceScore {
                ConfidenceDetailView(
                    overallConfidence: confidence,
                    fieldConfidences: payslipItem.fieldConfidences ?? [:],
                    source: payslipItem.source,
                    onReparse: nil,
                    onEdit: nil
                )
            }
        }
    }

    // Helper to format name (removes single-character components at the end)
    private func formatName(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1, components.last?.count == 1 {
            return components.dropLast().joined(separator: " ")
        }
        return name
    }

    // Extract confidence score from payslip
    private func extractConfidenceScore() -> Double? {
        // Use the new confidenceScore property directly
        if let payslipItem = viewModel.payslip as? PayslipItem {
            return payslipItem.confidenceScore
        }

        // Fallback to DTO if using that type
        if let payslipDTO = viewModel.payslip as? PayslipDTO {
            return payslipDTO.confidenceScore
        }

        return nil
    }
}

struct PayslipDetailNetPayView: View {
    let formattedNetPay: String

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Net Remittance")
                .font(.headline)

            Text(formattedNetPay.isEmpty ? "₹--" : formattedNetPay)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(FintechColors.backgroundGray)
        .cornerRadius(12)
    }
}

struct PayslipDetailFinancialSummaryView: View {
    let formattedGrossPay: String
    let formattedDeductions: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Summary")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Gross Pay")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedGrossPay.isEmpty ? "₹--" : formattedGrossPay)
                        .font(.title3)
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Total Deductions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedDeductions.isEmpty ? "₹--" : formattedDeductions)
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(FintechColors.backgroundGray)
        .cornerRadius(12)
    }
}
