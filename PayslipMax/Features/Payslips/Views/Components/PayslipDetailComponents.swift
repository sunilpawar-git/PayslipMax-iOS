import SwiftUI
import PDFKit
import Foundation

// MARK: - Payslip Detail Component Views

struct PayslipDetailHeaderView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Month/Year with inline confidence badge (best UX practice)
            HStack(spacing: 8) {
                Text("\(viewModel.payslip.month) \(viewModel.formatYear(viewModel.payslip.year))")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Shield badge inline with title (like verification badges)
                if let confidenceScore = extractConfidenceScore() {
                    ConfidenceBadgeShield(confidence: confidenceScore, showPercentage: true)
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
    }

    // Helper to format name (removes single-character components at the end)
    private func formatName(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1, components.last?.count == 1 {
            return components.dropLast().joined(separator: " ")
        }
        return name
    }
    
    // Extract confidence score from payslip metadata
    private func extractConfidenceScore() -> Double? {
        // Try to cast to PayslipItem to access metadata
        if let payslipItem = viewModel.payslip as? PayslipItem,
           let confidenceStr = payslipItem.metadata["parsingConfidence"],
           let confidence = Double(confidenceStr) {
            return confidence
        }
        
        // Try to cast to PayslipDTO to access metadata
        if let payslipDTO = viewModel.payslip as? PayslipDTO,
           let confidenceStr = payslipDTO.metadata["parsingConfidence"],
           let confidence = Double(confidenceStr) {
            return confidence
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

struct PayslipDetailEarningsView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel
    let formattedGrossPay: String

    // Display name service for clean presentation
    private let displayNameService: PayslipDisplayNameServiceProtocol =
        DIContainer.shared.makePayslipDisplayNameService()

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Earnings")
                .font(.headline)

            // Use display name service for clean presentation
            ForEach(displayNameService.getDisplayEarnings(from: viewModel.payslipData.allEarnings), id: \.displayName) { item in
                HStack {
                    Text(item.displayName)
                        .frame(width: 120, alignment: .leading)
                    
                    // Add plus icon for "Other Earnings"
                    if item.displayName.contains("Other") {
                        Button(action: {
                            viewModel.showOtherEarningsEditor = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    Text(viewModel.formatCurrency(item.value))
                }
            }

            Divider()

            HStack {
                Text("Total")
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .leading)
                Spacer()
                Text(formattedGrossPay.isEmpty ? "₹--" : formattedGrossPay)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(FintechColors.backgroundGray)
        .cornerRadius(12)
    }
}

struct PayslipDetailDeductionsView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel
    let formattedDeductions: String

    // Display name service for clean presentation
    private let displayNameService: PayslipDisplayNameServiceProtocol =
        DIContainer.shared.makePayslipDisplayNameService()

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Total Deductions")
                .font(.headline)

            // Use display name service for clean presentation
            ForEach(displayNameService.getDisplayDeductions(from: viewModel.payslipData.allDeductions), id: \.displayName) { item in
                HStack {
                    Text(item.displayName)
                        .frame(width: 120, alignment: .leading)
                    
                    // Add plus icon for "Other Deductions"
                    if item.displayName.contains("Other") {
                        Button(action: {
                            viewModel.showOtherDeductionsEditor = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    Text(viewModel.formatCurrency(item.value))
                }
            }

            Divider()

            HStack {
                Text("Total")
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .leading)
                Spacer()
                Text(formattedDeductions.isEmpty ? "₹--" : formattedDeductions)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(FintechColors.backgroundGray)
        .cornerRadius(12)
    }
}

struct PayslipDetailActionsView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel

    var body: some View {
        HStack(spacing: 20) {
            Button(action: {
                viewModel.showShareSheet = true
            }) {
                VStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 22))
                    Text("Share")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            }

            Button(action: {
                viewModel.showOriginalPDF = true
            }) {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 22))
                    Text("View PDF")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            }

            Button(action: {
                viewModel.showPrintDialog = true
            }) {
                VStack {
                    Image(systemName: "printer")
                        .font(.system(size: 22))
                    Text("Print")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(FintechColors.backgroundGray)
        .cornerRadius(12)
    }
}
