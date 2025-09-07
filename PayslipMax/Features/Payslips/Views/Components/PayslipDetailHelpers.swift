import SwiftUI
import UIKit

// MARK: - Helper struct for empty state equatable views
struct PayslipDetailEmptyState: Equatable {
    static func == (lhs: PayslipDetailEmptyState, rhs: PayslipDetailEmptyState) -> Bool {
        return true
    }
}

// MARK: - Async Share Sheet View
struct AsyncShareSheetView: View {
    let viewModel: PayslipDetailViewModel
    @State private var shareItems: [Any] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView("Preparing share items...")
                        .padding()
                }
            } else {
                ShareSheet(items: shareItems.isEmpty ? [viewModel.getShareText()] : shareItems)
            }
        }
        .task {
            let items = await viewModel.getShareItems()
            await MainActor.run {
                shareItems = items
                isLoading = false
            }
        }
    }
}

// MARK: - Share Sheet UIViewControllerRepresentable
// Uses the existing ShareSheet from Views/Shared/ShareSheet.swift

// MARK: - Equatable Helper Structs for View Optimization

struct HeaderContent: Equatable {
    let payslip: AnyPayslip

    static func == (lhs: HeaderContent, rhs: HeaderContent) -> Bool {
        return lhs.payslip.month == rhs.payslip.month &&
               lhs.payslip.year == rhs.payslip.year &&
               lhs.payslip.name == rhs.payslip.name
    }
}

struct PayslipNetPayContent: Equatable {
    let netRemittance: Double
    let formattedNetPay: String

    static func == (lhs: PayslipNetPayContent, rhs: PayslipNetPayContent) -> Bool {
        return lhs.netRemittance == rhs.netRemittance &&
               lhs.formattedNetPay == rhs.formattedNetPay
    }
}

struct FinancialSummaryContent: Equatable {
    let totalCredits: Double
    let totalDebits: Double
    let formattedGrossPay: String
    let formattedDeductions: String

    static func == (lhs: FinancialSummaryContent, rhs: FinancialSummaryContent) -> Bool {
        return lhs.totalCredits == rhs.totalCredits &&
               lhs.totalDebits == rhs.totalDebits &&
               lhs.formattedGrossPay == rhs.formattedGrossPay &&
               lhs.formattedDeductions == rhs.formattedDeductions
    }
}

struct EarningsContent: Equatable {
    let earnings: [String: Double]
    let totalCredits: Double

    static func == (lhs: EarningsContent, rhs: EarningsContent) -> Bool {
        return lhs.earnings == rhs.earnings &&
               lhs.totalCredits == rhs.totalCredits
    }
}

struct DeductionsContent: Equatable {
    let deductions: [String: Double]
    let totalDebits: Double

    static func == (lhs: DeductionsContent, rhs: DeductionsContent) -> Bool {
        return lhs.deductions == rhs.deductions &&
               lhs.totalDebits == rhs.totalDebits
    }
}
