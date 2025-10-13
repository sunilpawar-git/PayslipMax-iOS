import SwiftUI
import UIKit
import PDFKit
import Foundation
import Combine

// MARK: - PayslipDetailView
struct PayslipDetailView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel

    // Cache expensive computations
    @State private var formattedNetPay: String = ""
    @State private var formattedGrossPay: String = ""
    @State private var formattedDeductions: String = ""

    // Track visible sections to improve performance
    @State private var visibleSections = Set<String>()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header with month/year and name
                PayslipDetailHeaderView(viewModel: viewModel)
                    .id("header-\(viewModel.payslip.id)")

                // Net Pay
                PayslipDetailNetPayView(formattedNetPay: formattedNetPay)
                    .id("netpay-\(viewModel.payslip.id)")

                // Financial summary
                PayslipDetailFinancialSummaryView(
                    formattedGrossPay: formattedGrossPay,
                    formattedDeductions: formattedDeductions
                )
                .id("summary-\(viewModel.payslip.id)")

                // Earnings
                if !viewModel.payslipData.allEarnings.isEmpty {
                    PayslipDetailEarningsView(
                        viewModel: viewModel,
                        formattedGrossPay: formattedGrossPay
                    )
                    .id("earnings-\(viewModel.payslip.id)")
                }

                // Deductions
                if !viewModel.payslipData.allDeductions.isEmpty {
                    PayslipDetailDeductionsView(
                        viewModel: viewModel,
                        formattedDeductions: formattedDeductions
                    )
                    .id("deductions-\(viewModel.payslip.id)")
                }

                // Contact information (only displayed if not empty)
                if !viewModel.contactInfo.isEmpty {
                    PayslipContactView(contactInfo: viewModel.contactInfo)
                        .id("contact-\(viewModel.payslip.id)")
                }

                // Actions (share, export, view PDF)
                PayslipDetailActionsView(viewModel: viewModel)
                    .id("actions-\(viewModel.payslip.id)")

                Spacer(minLength: 30)
            }
            .padding()
        }
        .trackRenderTime(name: "PayslipDetailView")
        .trackPerformance(name: "PayslipDetailView")
        .navigationTitle("Payslip Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            PerformanceMetrics.shared.recordViewRedraw(for: "PayslipDetailView")
            precalculateFormattedValues()
            Task {
                await viewModel.loadAdditionalData()
            }
        }
        .onChange(of: viewModel.payslipData) { _, _ in
            // Update formatted values immediately on the main actor
            formattedNetPay = formatCurrency(viewModel.payslipData.netRemittance)
            formattedGrossPay = formatCurrency(viewModel.payslipData.totalCredits)
            
            // Calculate total deductions directly from the deduction items to avoid double counting
            let actualDeductions = viewModel.payslipData.allDeductions.values.reduce(0, +)
            formattedDeductions = formatCurrency(actualDeductions)
        }
        .fullScreenCover(isPresented: $viewModel.showOriginalPDF) {
            PDFViewerScreen(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            AsyncShareSheetView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showPrintDialog) {
            // Using PrintController in a fullScreenCover, which will be dismissed
            // automatically when printing is complete
            PrintController(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $viewModel.showOtherEarningsEditor) {
            if let payslipItem = viewModel.payslip as? PayslipItem {
                MiscellaneousEarningsEditor(
                    amount: payslipItem.earnings["Other Earnings"] ?? 0,
                    breakdown: viewModel.extractBreakdownFromPayslip(payslipItem.earnings),
                    onSave: { breakdown in
                        Task {
                            await viewModel.updateOtherEarnings(breakdown)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showOtherDeductionsEditor) {
            if let payslipItem = viewModel.payslip as? PayslipItem {
                MiscellaneousDeductionsEditor(
                    amount: payslipItem.deductions["Other Deductions"] ?? 0,
                    breakdown: viewModel.extractBreakdownFromPayslip(payslipItem.deductions),
                    onSave: { breakdown in
                        Task {
                            await viewModel.updateOtherDeductions(breakdown)
                        }
                    }
                )
            }
        }
    }
    
    // Pre-compute expensive formatted values
    private func precalculateFormattedValues() {
        formattedNetPay = formatCurrency(viewModel.payslipData.netRemittance)
        formattedGrossPay = formatCurrency(viewModel.payslipData.totalCredits)

        // Calculate total deductions directly from the deduction items to avoid double counting
        let actualDeductions = viewModel.payslipData.allDeductions.values.reduce(0, +)
        formattedDeductions = formatCurrency(actualDeductions)
    }

    // Helper function for currency formatting
    private func formatCurrency(_ value: Double) -> String {
        // Use the ViewModel's formatter to maintain consistency
        return viewModel.formatCurrency(value)
    }
    
}
