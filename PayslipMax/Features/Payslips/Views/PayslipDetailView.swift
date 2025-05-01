import SwiftUI
import UIKit
import PDFKit
import Foundation
import Combine

// Helper struct for empty state equatable views
struct PayslipDetailEmptyState: Equatable {
    static func == (lhs: PayslipDetailEmptyState, rhs: PayslipDetailEmptyState) -> Bool {
        return true
    }
}

// MARK: - PayslipDetailView
struct PayslipDetailView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel
    @State private var isEditing = false
    
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
                headerView
                    .id("header-\(viewModel.payslip.id)")
                    .equatable(HeaderContent(payslip: viewModel.payslip))
                
                // Net Pay
                netPayView
                    .id("netpay-\(viewModel.payslip.id)")
                    .equatable(PayslipNetPayContent(netRemittance: viewModel.payslipData.netRemittance, formattedNetPay: formattedNetPay))
                
                // Financial summary
                financialSummaryView
                    .id("summary-\(viewModel.payslip.id)")
                    .equatable(FinancialSummaryContent(totalCredits: viewModel.payslipData.totalCredits, totalDebits: viewModel.payslipData.totalDebits, formattedGrossPay: formattedGrossPay, formattedDeductions: formattedDeductions))
                
                // Earnings
                if !viewModel.payslipData.allEarnings.isEmpty {
                    earningsView
                        .id("earnings-\(viewModel.payslip.id)")
                        .equatable(EarningsContent(earnings: viewModel.payslipData.allEarnings, totalCredits: viewModel.payslipData.totalCredits))
                }
                
                // Deductions
                if !viewModel.payslipData.allDeductions.isEmpty {
                    deductionsView
                        .id("deductions-\(viewModel.payslip.id)")
                        .equatable(DeductionsContent(deductions: viewModel.payslipData.allDeductions, totalDebits: viewModel.payslipData.totalDebits))
                }
                
                // Actions (share, export, view PDF)
                actionsView
                    .id("actions-\(viewModel.payslip.id)")
                    .equatable(PayslipDetailEmptyState())
                
                Spacer(minLength: 30)
            }
            .padding()
        }
        .trackRenderTime(name: "PayslipDetailView")
        .trackPerformance(viewName: "PayslipDetailView")
        .navigationTitle("Payslip Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                }
            }
        }
        .onAppear {
            PerformanceMetrics.shared.recordViewRedraw(for: "PayslipDetailView")
            precalculateFormattedValues()
            Task {
                await viewModel.loadAdditionalData()
            }
        }
        .onChange(of: viewModel.payslipData) { _, _ in
            // Use background thread for formatting to avoid UI stutter
            BackgroundQueue.shared.async {
                let net = formatCurrency(viewModel.payslipData.netRemittance)
                let gross = formatCurrency(viewModel.payslipData.totalCredits)
                
                // Calculate total deductions directly from the deduction items to avoid double counting
                let actualDeductions = viewModel.payslipData.allDeductions.values.reduce(0, +)
                let deductions = formatCurrency(actualDeductions)
                
                DispatchQueue.main.async {
                    formattedNetPay = net
                    formattedGrossPay = gross
                    formattedDeductions = deductions
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showOriginalPDF) {
            PDFViewerScreen(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let items = viewModel.getShareItems() {
                ShareSheet(items: items)
            } else {
                ShareSheet(items: [viewModel.getShareText()])
            }
        }
        .fullScreenCover(isPresented: $viewModel.showPrintDialog) {
            // Using PrintController in a fullScreenCover, which will be dismissed
            // automatically when printing is complete
            PrintController(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    // Pre-compute expensive formatted values
    private func precalculateFormattedValues() {
        BackgroundQueue.shared.async {
            let net = formatCurrency(viewModel.payslipData.netRemittance)
            let gross = formatCurrency(viewModel.payslipData.totalCredits)
            
            // Calculate total deductions directly from the deduction items to avoid double counting
            let actualDeductions = viewModel.payslipData.allDeductions.values.reduce(0, +)
            let deductions = formatCurrency(actualDeductions)
            
            DispatchQueue.main.async {
                formattedNetPay = net
                formattedGrossPay = gross
                formattedDeductions = deductions
            }
        }
    }
    
    // Helper function for currency formatting
    private func formatCurrency(_ value: Double) -> String {
        // Use the ViewModel's formatter to maintain consistency
        return viewModel.formatCurrency(value)
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
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
        .background(Color(UIColor.secondarySystemBackground))
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
    
    private var netPayView: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Net Pay")
                .font(.headline)
            
            Text(formattedNetPay.isEmpty ? "₹--" : formattedNetPay)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var financialSummaryView: some View {
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
                    Text("Deductions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedDeductions.isEmpty ? "₹--" : formattedDeductions)
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var earningsView: some View {
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
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var deductionsView: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Deductions")
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
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var actionsView: some View {
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
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Equatable Helper Structs

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