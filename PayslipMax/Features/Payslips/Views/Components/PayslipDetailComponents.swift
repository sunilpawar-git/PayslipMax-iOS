import SwiftUI
import PDFKit
import Foundation

// MARK: - Payslip Detail Component Views

struct PayslipDetailHeaderView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Format year without comma and keep month as is
            Text("\(viewModel.payslip.month) \(viewModel.formatYear(viewModel.payslip.year))")
                .font(.title)
                .fontWeight(.bold)

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

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Earnings")
                .font(.headline)

            ForEach(Array(viewModel.payslipData.allEarnings.keys.sorted()), id: \.self) { key in
                if let value = viewModel.payslipData.allEarnings[key], value > 0 {
                    HStack {
                        Text(key)
                            .frame(width: 120, alignment: .leading)
                        Spacer()
                        Text(viewModel.formatCurrency(value))
                    }
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

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Total Deductions")
                .font(.headline)

            ForEach(Array(viewModel.payslipData.allDeductions.keys.sorted()), id: \.self) { key in
                if let value = viewModel.payslipData.allDeductions[key], value > 0 {
                    HStack {
                        Text(key)
                            .frame(width: 120, alignment: .leading)
                        Spacer()
                        Text(viewModel.formatCurrency(value))
                    }
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
