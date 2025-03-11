import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

// Define a notification name for payslip deletion
extension Notification.Name {
    static let payslipDeleted = Notification.Name("PayslipDeleted")
}

struct PayslipDetailView: View {
    let payslip: any PayslipItemProtocol
    @StateObject private var viewModel: PayslipDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var showingDeleteConfirmation = false
    
    init(payslip: any PayslipItemProtocol, viewModel: PayslipDetailViewModel? = nil) {
        self.payslip = payslip
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: PayslipDetailViewModel(payslip: payslip))
        }
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let decryptedPayslip = viewModel.decryptedPayslip {
                List {
                    Section(header: Text("PERSONAL DETAILS")) {
                        DetailRow(title: "Name", value: decryptedPayslip.name)
                        DetailRow(title: "PCDA Account Number", value: decryptedPayslip.accountNumber)
                        DetailRow(title: "PAN Number", value: decryptedPayslip.panNumber)
                        DetailRow(title: "Month", value: decryptedPayslip.month)
                        DetailRow(title: "Year", value: String(decryptedPayslip.year))
                    }
                    
                    Section(header: Text("FINANCIAL DETAILS")) {
                        DetailRow(title: "Credits", value: viewModel.formatCurrency(decryptedPayslip.credits))
                        DetailRow(title: "Debits", value: viewModel.formatCurrency(decryptedPayslip.debits))
                        DetailRow(title: "DSOP", value: viewModel.formatCurrency(decryptedPayslip.dsop))
                        DetailRow(title: "Income Tax", value: viewModel.formatCurrency(decryptedPayslip.tax))
                        DetailRow(title: "Net Amount", value: viewModel.formattedNetAmount)
                    }
                    
                    // Add Earnings Breakdown Section
                    if let payslipItem = decryptedPayslip as? PayslipItem, !payslipItem.earnings.isEmpty {
                        Section(header: Text("EARNINGS BREAKDOWN")) {
                            ForEach(Array(payslipItem.earnings.keys.sorted()), id: \.self) { key in
                                if let value = payslipItem.earnings[key], value > 0 {
                                    DetailRow(title: key, value: viewModel.formatCurrency(value))
                                }
                            }
                        }
                    }
                    
                    // Add Deductions Breakdown Section
                    if let payslipItem = decryptedPayslip as? PayslipItem, !payslipItem.deductions.isEmpty {
                        Section(header: Text("DEDUCTIONS BREAKDOWN")) {
                            ForEach(Array(payslipItem.deductions.keys.sorted()), id: \.self) { key in
                                if let value = payslipItem.deductions[key], value > 0 {
                                    DetailRow(title: key, value: viewModel.formatCurrency(value))
                                }
                            }
                        }
                    }
                    
                    // Add Statement Period Section
                    if !viewModel.extractedData.isEmpty {
                        Section(header: Text("ADDITIONAL DETAILS")) {
                            if let statementPeriod = viewModel.extractedData["statementPeriod"], !statementPeriod.isEmpty {
                                DetailRow(title: "Statement Period", value: statementPeriod)
                            }
                            
                            if let dsopOpeningBalance = viewModel.extractedData["dsopOpeningBalance"], !dsopOpeningBalance.isEmpty {
                                DetailRow(title: "DSOP Opening Balance", value: "₹\(dsopOpeningBalance)/-")
                            }
                            
                            if let dsopSubscription = viewModel.extractedData["dsopSubscription"], !dsopSubscription.isEmpty {
                                DetailRow(title: "DSOP Subscription", value: "₹\(dsopSubscription)/-")
                            }
                            
                            if let dsopClosingBalance = viewModel.extractedData["dsopClosingBalance"], !dsopClosingBalance.isEmpty {
                                DetailRow(title: "DSOP Closing Balance", value: "₹\(dsopClosingBalance)/-")
                            }
                            
                            if let incomeTaxDeducted = viewModel.extractedData["incomeTaxDeducted"], !incomeTaxDeducted.isEmpty {
                                DetailRow(title: "Income Tax Deducted", value: "₹\(incomeTaxDeducted)/-")
                            }
                            
                            if let edCessDeducted = viewModel.extractedData["edCessDeducted"], !edCessDeducted.isEmpty {
                                DetailRow(title: "Ed. Cess Deducted", value: "₹\(edCessDeducted)/-")
                            }
                            
                            if let totalTaxPayable = viewModel.extractedData["totalTaxPayable"], !totalTaxPayable.isEmpty {
                                DetailRow(title: "Total Tax Payable", value: "₹\(totalTaxPayable)/-")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Payslip Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        Task {
                            do {
                                if let url = try await viewModel.getPDFURL() {
                                    pdfURL = url
                                    ShareSheet.share(items: [url] as [Any]) {
                                        showShareSheet = false
                                    }
                                }
                            } catch {
                                viewModel.error = error as? AppError ?? AppError.message("Failed to prepare PDF for sharing")
                            }
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .alert(
            "Delete Payslip",
            isPresented: $showingDeleteConfirmation,
            actions: {
                Button("Delete", role: .destructive) {
                    deletePayslip()
                }
                Button("Cancel", role: .cancel) {}
            },
            message: {
                Text("Are you sure you want to delete this payslip? This action cannot be undone.")
            }
        )
        .errorAlert(error: $viewModel.error)
        .task {
            await viewModel.loadDecryptedData()
        }
    }
    
    private func deletePayslip() {
        if let payslipItem = payslip as? PayslipItem {
            // First, try to delete any associated PDF file
            let pdfId = payslipItem.id.uuidString
            do {
                try PDFManager.shared.deletePDF(identifier: pdfId)
                print("Successfully deleted PDF file for payslip: \(pdfId)")
            } catch {
                print("Error deleting PDF file: \(error.localizedDescription)")
            }
            
            // Use the DataService to delete the payslip
            Task {
                do {
                    // Initialize the data service if needed
                    if !viewModel.dataService.isInitialized {
                        try await viewModel.dataService.initialize()
                    }
                    
                    // Delete the payslip using the data service
                    try await viewModel.dataService.delete(payslipItem)
                    print("Successfully deleted payslip using DataService")
                    
                    // Also delete from local context to ensure UI updates immediately
                    modelContext.delete(payslipItem)
                    try modelContext.save()
                    
                    // Post a notification that a payslip was deleted
                    NotificationCenter.default.post(name: .payslipDeleted, object: nil)
                    
                    // Dismiss the view after successful deletion
                    dismiss()
                } catch {
                    print("Error deleting payslip: \(error.localizedDescription)")
                    viewModel.error = AppError.message("Failed to delete payslip: \(error.localizedDescription)")
                }
            }
        } else {
            viewModel.error = AppError.message("Cannot delete this type of payslip")
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
