import SwiftUI

/// Optimized unified row component with better state handling and Apple design principles
struct UnifiedPayslipRowView: View {
    let payslip: AnyPayslip
    let sectionTitle: String
    let isFirstInSection: Bool
    let viewModel: PayslipsViewModel

    // Cache expensive calculations
    @State private var formattedNetAmount: String = ""

    var body: some View {
        NavigationLink {
            PayslipDetailView(viewModel: PayslipDetailViewModel(payslip: payslip))
        } label: {
            VStack(spacing: 0) {
                // Section header (only show for first item in section)
                if isFirstInSection {
                    HStack {
                        Text(sectionTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.textPrimary)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }

                // Unified payslip card
                HStack(spacing: 16) {
                    // Left side: Icon and basic info
                    HStack(spacing: 12) {
                        // Document icon with subtle background
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(FintechColors.primaryBlue.opacity(0.1))
                                .frame(width: 40, height: 40)

                            Image(systemName: "doc.text.fill")
                                .foregroundColor(FintechColors.primaryBlue)
                                .font(.system(size: 18))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            // Employee name or fallback
                            Text(payslip.name.isEmpty ? "Payslip" : formatName(payslip.name))
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(FintechColors.textPrimary)
                                .lineLimit(1)

                            // Subtle subtitle
                            Text("Net Remittance")
                                .font(.subheadline)
                                .foregroundColor(FintechColors.textSecondary)
                        }
                    }

                    Spacer()

                    // Right side: Financial amount with trend styling
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedNetAmount)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(FintechColors.getAccessibleColor(for: getNetAmount(for: payslip)))

                        // Subtle indicator for positive/negative
                        HStack(spacing: 4) {
                            Image(systemName: getNetAmount(for: payslip) >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                                .foregroundColor(getNetAmount(for: payslip) >= 0 ? FintechColors.successGreen : FintechColors.dangerRed)

                            Text(getNetAmount(for: payslip) >= 0 ? "Credit" : "Debit")
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FintechColors.backgroundGray)
                        .shadow(
                            color: FintechColors.shadow,
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            self.formattedNetAmount = formatCurrency(getNetAmount(for: payslip))
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

    // Helper methods to work with AnyPayslip
    private func getNetAmount(for payslip: AnyPayslip) -> Double {
        return payslip.credits - payslip.debits
    }

    // Format currency to avoid dependency on ViewModel
    private func formatCurrency(_ value: Double) -> String {
        let absValue = abs(value)

        if absValue >= 1_00_000 { // 1 Lakh or more
            let lakhs = absValue / 1_00_000
            if lakhs >= 10 {
                return "₹\(String(format: "%.0f", lakhs))L"
            } else {
                // Truncate to 2 decimal places instead of rounding
                let truncatedLakhs = floor(lakhs * 100) / 100
                return "₹\(String(format: "%.2f", truncatedLakhs))L"
            }
        } else if absValue >= 1_000 { // 1 Thousand or more
            let thousands = absValue / 1_000
            if thousands >= 10 {
                return "₹\(String(format: "%.0f", thousands))K"
            } else {
                // Truncate to 2 decimal places instead of rounding
                let truncatedThousands = floor(thousands * 100) / 100
                return "₹\(String(format: "%.2f", truncatedThousands))K"
            }
        } else {
            return "₹\(String(format: "%.0f", absValue))"
        }
    }
}

// MARK: - Equatable Helper Structs

struct PayslipRowContent: Equatable {
    let payslip: AnyPayslip

    static func == (lhs: PayslipRowContent, rhs: PayslipRowContent) -> Bool {
        return lhs.payslip.id == rhs.payslip.id &&
               lhs.payslip.month == rhs.payslip.month &&
               lhs.payslip.year == rhs.payslip.year &&
               lhs.payslip.credits == rhs.payslip.credits &&
               lhs.payslip.debits == rhs.payslip.debits &&
               lhs.payslip.name == rhs.payslip.name
    }
}

struct SectionContent: Equatable {
    let payslips: [AnyPayslip]

    static func == (lhs: SectionContent, rhs: SectionContent) -> Bool {
        guard lhs.payslips.count == rhs.payslips.count else { return false }

        for (index, lhsPayslip) in lhs.payslips.enumerated() {
            let rhsPayslip = rhs.payslips[index]
            if lhsPayslip.id != rhsPayslip.id {
                return false
            }
        }

        return true
    }
}
