import SwiftUI
import Foundation

// MARK: - Payslip Detail Data Component Views

struct PayslipDetailEarningsView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel
    let formattedGrossPay: String

    // Display name service for clean presentation
    private let displayNameService: PayslipDisplayNameServiceProtocol =
        DIContainer.shared.makePayslipDisplayNameService()

    // X-Ray state
    @State private var selectedItemForComparison: ItemComparison?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Earnings")
                .font(.headline)

            // Use display name service for clean presentation
            ForEach(displayNameService.getDisplayEarnings(from: viewModel.payslipData.allEarnings), id: \.displayName) { item in
                HStack {
                    // Add arrow indicator for X-Ray
                    if viewModel.xRaySettings.isXRayEnabled,
                       let comparison = viewModel.comparison,
                       let itemChange = comparison.earningsChanges[item.originalKey] {
                        ChangeArrowIndicator(direction: ChangeDirection.from(itemChange), isEarning: true)
                    }

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

                    // Make amount tappable if needs attention
                    if shouldShowComparisonDetail(for: item.originalKey, isEarning: true) {
                        Button(action: {
                            selectedItemForComparison = viewModel.comparison?.earningsChanges[item.originalKey]
                        }) {
                            Text(viewModel.formatCurrency(item.value))
                                .foregroundColor(FintechColors.dangerRed)
                                .underline()
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(viewModel.formatCurrency(item.value))
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
        .sheet(item: $selectedItemForComparison) { comparison in
            ComparisonDetailModal(itemComparison: comparison, isEarning: true)
        }
    }

    // MARK: - Helper Methods

    /// Determines if comparison detail should be shown (items needing attention)
    private func shouldShowComparisonDetail(for originalKey: String, isEarning: Bool) -> Bool {
        guard viewModel.xRaySettings.isXRayEnabled,
              let comparison = viewModel.comparison else {
            return false
        }

        if isEarning {
            if let itemChange = comparison.earningsChanges[originalKey] {
                return itemChange.needsAttention
            }
        }

        return false
    }
}

struct PayslipDetailDeductionsView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel
    let formattedDeductions: String

    // Display name service for clean presentation
    private let displayNameService: PayslipDisplayNameServiceProtocol =
        DIContainer.shared.makePayslipDisplayNameService()

    // X-Ray state
    @State private var selectedItemForComparison: ItemComparison?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Total Deductions")
                .font(.headline)

            // Use display name service for clean presentation
            ForEach(displayNameService.getDisplayDeductions(from: viewModel.payslipData.allDeductions), id: \.displayName) { item in
                HStack {
                    // Add arrow indicator for X-Ray
                    if viewModel.xRaySettings.isXRayEnabled,
                       let comparison = viewModel.comparison,
                       let itemChange = comparison.deductionsChanges[item.originalKey] {
                        ChangeArrowIndicator(direction: ChangeDirection.from(itemChange), isEarning: false)
                    }

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

                    // Make amount tappable if needs attention
                    if shouldShowComparisonDetail(for: item.originalKey, isEarning: false) {
                        Button(action: {
                            selectedItemForComparison = viewModel.comparison?.deductionsChanges[item.originalKey]
                        }) {
                            Text(viewModel.formatCurrency(item.value))
                                .foregroundColor(FintechColors.dangerRed)
                                .underline()
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(viewModel.formatCurrency(item.value))
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
        .sheet(item: $selectedItemForComparison) { comparison in
            ComparisonDetailModal(itemComparison: comparison, isEarning: false)
        }
    }

    // MARK: - Helper Methods

    /// Determines if comparison detail should be shown (items needing attention)
    private func shouldShowComparisonDetail(for originalKey: String, isEarning: Bool) -> Bool {
        guard viewModel.xRaySettings.isXRayEnabled,
              let comparison = viewModel.comparison else {
            return false
        }

        if !isEarning {
            if let itemChange = comparison.deductionsChanges[originalKey] {
                return itemChange.needsAttention
            }
        }

        return false
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
