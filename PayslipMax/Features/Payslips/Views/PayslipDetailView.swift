import SwiftUI
import UIKit
import PDFKit
import Foundation
import Combine

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
                
                // Net Pay
                netPayView
                    .id("netpay-\(viewModel.payslip.id)")
                
                // Financial summary
                financialSummaryView
                    .id("summary-\(viewModel.payslip.id)")
                
                // Earnings
                if !viewModel.payslipData.allEarnings.isEmpty {
                    earningsView
                        .id("earnings-\(viewModel.payslip.id)")
                }
                
                // Deductions
                if !viewModel.payslipData.allDeductions.isEmpty {
                    deductionsView
                        .id("deductions-\(viewModel.payslip.id)")
                }
                
                // Actions (share, export, view PDF)
                actionsView
                    .id("actions-\(viewModel.payslip.id)")
                
                Spacer(minLength: 30)
            }
            .padding()
        }
        .trackRenderTime(name: "PayslipDetailView")
        .trackPerformance(name: "PayslipDetailView")
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
            precalculateFormattedValues()
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
    }
    
    // Pre-compute expensive formatted values
    private func precalculateFormattedValues() {
        formattedNetPay = viewModel.formatCurrency(viewModel.payslipData.netRemittance)
        formattedGrossPay = viewModel.formatCurrency(viewModel.payslipData.totalCredits)
        let totalDeductions = viewModel.payslipData.totalDebits + viewModel.payslipData.dsop + viewModel.payslipData.incomeTax
        formattedDeductions = viewModel.formatCurrency(totalDeductions)
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("\(viewModel.payslip.month) \(viewModel.payslip.year)")
                .font(.title)
                .fontWeight(.bold)
            
            Text(viewModel.payslip.name)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var netPayView: some View {
        VStack(spacing: 8) {
            Text("Net Pay")
                .font(.headline)
            
            Text(formattedNetPay)
                .font(.system(size: 36, weight: .bold))
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
                Text("Gross Pay")
                    .frame(width: 120, alignment: .leading)
                Spacer()
                Text(formattedGrossPay)
            }
            
            HStack {
                Text("Deductions")
                    .frame(width: 120, alignment: .leading)
                Spacer()
                Text(formattedDeductions)
            }
            
            HStack {
                Text("Net Pay")
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .leading)
                Spacer()
                Text(formattedNetPay)
                    .fontWeight(.bold)
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
                Text(formattedGrossPay)
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
            
            if viewModel.payslipData.dsop > 0 {
                HStack {
                    Text("DSOP")
                        .frame(width: 120, alignment: .leading)
                    Spacer()
                    Text(viewModel.formatCurrency(viewModel.payslipData.dsop))
                }
            }
            
            if viewModel.payslipData.incomeTax > 0 {
                HStack {
                    Text("Income Tax")
                        .frame(width: 120, alignment: .leading)
                    Spacer()
                    Text(viewModel.formatCurrency(viewModel.payslipData.incomeTax))
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .fontWeight(.bold)
                    .frame(width: 120, alignment: .leading)
                Spacer()
                Text(formattedDeductions)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var actionsView: some View {
        VStack {
            Button(action: {
                viewModel.showShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Payslip")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                viewModel.showOriginalPDF = true
            }) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("View PDF")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
        }
        .padding(.vertical)
    }
} 