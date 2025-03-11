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
                    // PERSONAL DETAILS SECTION
                    Section(header: Text("PERSONAL DETAILS")) {
                        DetailRow(title: "Name", value: decryptedPayslip.name)
                        DetailRow(title: "PCDA Account Number", value: decryptedPayslip.accountNumber)
                        DetailRow(title: "PAN Number", value: decryptedPayslip.panNumber)
                        DetailRow(title: "Month", value: decryptedPayslip.month)
                        DetailRow(title: "Year", value: String(decryptedPayslip.year))
                    }
                    
                    // FINANCIAL DETAILS SECTION
                    Section(header: Text("FINANCIAL DETAILS")) {
                        DetailRow(title: "Credits", value: viewModel.formatCurrency(decryptedPayslip.credits))
                        DetailRow(title: "Debits", value: viewModel.formatCurrency(decryptedPayslip.debits))
                        DetailRow(title: "DSOP", value: viewModel.formatCurrency(decryptedPayslip.dsop))
                        DetailRow(title: "Income Tax", value: viewModel.formatCurrency(decryptedPayslip.tax))
                        DetailRow(title: "Net Amount", value: viewModel.formattedNetAmount)
                    }
                    
                    // EARNINGS BREAKDOWN SECTION
                    if let payslipItem = decryptedPayslip as? PayslipItem, !payslipItem.earnings.isEmpty {
                        Section(header: Text("EARNINGS BREAKDOWN")) {
                            ForEach(Array(payslipItem.earnings.keys.sorted()), id: \.self) { key in
                                if let value = payslipItem.earnings[key], value > 0 {
                                    DetailRow(title: key, value: viewModel.formatCurrency(value))
                                }
                            }
                            // Add total earnings row
                            let totalEarnings = payslipItem.earnings.values.reduce(0, +)
                            DetailRow(title: "Gross Pay", value: viewModel.formatCurrency(totalEarnings))
                                .fontWeight(.bold)
                        }
                    }
                    
                    // DEDUCTIONS BREAKDOWN SECTION
                    if let payslipItem = decryptedPayslip as? PayslipItem, !payslipItem.deductions.isEmpty {
                        Section(header: Text("DEDUCTIONS BREAKDOWN")) {
                            ForEach(Array(payslipItem.deductions.keys.sorted()), id: \.self) { key in
                                if let value = payslipItem.deductions[key], value > 0 {
                                    DetailRow(title: key, value: viewModel.formatCurrency(value))
                                }
                            }
                            // Add total deductions row
                            let totalDeductions = payslipItem.deductions.values.reduce(0, +)
                            DetailRow(title: "Total Deductions", value: viewModel.formatCurrency(totalDeductions))
                                .fontWeight(.bold)
                        }
                    }
                    
                    // INCOME TAX DETAILS SECTION
                    if !viewModel.extractedData.isEmpty {
                        Section(header: Text("INCOME TAX DETAILS")) {
                            if let statementPeriod = viewModel.extractedData["statementPeriod"], !statementPeriod.isEmpty {
                                DetailRow(title: "Statement Period", value: statementPeriod)
                            }
                            
                            if let incomeTaxDeducted = viewModel.extractedData["incomeTaxDeducted"], !incomeTaxDeducted.isEmpty {
                                DetailRow(title: "Income Tax Deducted", value: "₹\(incomeTaxDeducted)")
                            }
                            
                            if let edCessDeducted = viewModel.extractedData["edCessDeducted"], !edCessDeducted.isEmpty {
                                DetailRow(title: "Ed. Cess Deducted", value: "₹\(edCessDeducted)")
                            }
                            
                            if let totalTaxPayable = viewModel.extractedData["totalTaxPayable"], !totalTaxPayable.isEmpty {
                                DetailRow(title: "Total Tax Payable", value: "₹\(totalTaxPayable)")
                            }
                            
                            // Add additional tax details from the screenshot
                            if let grossSalary = viewModel.extractedData["grossSalary"], !grossSalary.isEmpty {
                                DetailRow(title: "Gross Salary", value: "₹\(grossSalary)")
                            }
                            
                            if let standardDeduction = viewModel.extractedData["standardDeduction"], !standardDeduction.isEmpty {
                                DetailRow(title: "Standard Deduction", value: "₹\(standardDeduction)")
                            }
                            
                            if let netTaxableIncome = viewModel.extractedData["netTaxableIncome"], !netTaxableIncome.isEmpty {
                                DetailRow(title: "Net Taxable Income", value: "₹\(netTaxableIncome)")
                            }
                        }
                    }
                    
                    // DSOP DETAILS SECTION
                    if !viewModel.extractedData.isEmpty {
                        Section(header: Text("DSOP DETAILS")) {
                            if let dsopOpeningBalance = viewModel.extractedData["dsopOpeningBalance"], !dsopOpeningBalance.isEmpty {
                                DetailRow(title: "Opening Balance", value: "₹\(dsopOpeningBalance)")
                            }
                            
                            if let dsopSubscription = viewModel.extractedData["dsopSubscription"], !dsopSubscription.isEmpty {
                                DetailRow(title: "Subscription", value: "₹\(dsopSubscription)")
                            }
                            
                            if let dsopMiscAdj = viewModel.extractedData["dsopMiscAdj"], !dsopMiscAdj.isEmpty {
                                DetailRow(title: "Misc Adj", value: "₹\(dsopMiscAdj)")
                            }
                            
                            if let dsopWithdrawal = viewModel.extractedData["dsopWithdrawal"], !dsopWithdrawal.isEmpty {
                                DetailRow(title: "Withdrawal", value: "₹\(dsopWithdrawal)")
                            }
                            
                            if let dsopRefund = viewModel.extractedData["dsopRefund"], !dsopRefund.isEmpty {
                                DetailRow(title: "Refund", value: "₹\(dsopRefund)")
                            }
                            
                            if let dsopClosingBalance = viewModel.extractedData["dsopClosingBalance"], !dsopClosingBalance.isEmpty {
                                DetailRow(title: "Closing Balance", value: "₹\(dsopClosingBalance)")
                            }
                        }
                    }
                    
                    // CONTACT DETAILS SECTION
                    if !viewModel.extractedData.isEmpty {
                        Section(header: Text("CONTACT DETAILS")) {
                            if let contactSAOLW = viewModel.extractedData["contactSAOLW"], !contactSAOLW.isEmpty {
                                DetailRow(title: "SAO(LW)", value: contactSAOLW)
                            }
                            
                            if let contactAAOLW = viewModel.extractedData["contactAAOLW"], !contactAAOLW.isEmpty {
                                DetailRow(title: "AAO(LW)", value: contactAAOLW)
                            }
                            
                            if let contactSAOTW = viewModel.extractedData["contactSAOTW"], !contactSAOTW.isEmpty {
                                DetailRow(title: "SAO(TW)", value: contactSAOTW)
                            }
                            
                            if let contactAAOTW = viewModel.extractedData["contactAAOTW"], !contactAAOTW.isEmpty {
                                DetailRow(title: "AAO(TW)", value: contactAAOTW)
                            }
                            
                            if let contactProCivil = viewModel.extractedData["contactProCivil"], !contactProCivil.isEmpty {
                                DetailRow(title: "PRO CIVIL", value: contactProCivil)
                            }
                            
                            if let contactProArmy = viewModel.extractedData["contactProArmy"], !contactProArmy.isEmpty {
                                DetailRow(title: "PRO ARMY", value: contactProArmy)
                            }
                            
                            if let contactWebsite = viewModel.extractedData["contactWebsite"], !contactWebsite.isEmpty {
                                DetailRow(title: "Website", value: contactWebsite)
                            }
                            
                            if let contactEmailTADA = viewModel.extractedData["contactEmailTADA"], !contactEmailTADA.isEmpty {
                                DetailRow(title: "TA/DA Email", value: contactEmailTADA)
                            }
                            
                            if let contactEmailLedger = viewModel.extractedData["contactEmailLedger"], !contactEmailLedger.isEmpty {
                                DetailRow(title: "Ledger Email", value: contactEmailLedger)
                            }
                            
                            if let contactEmailRankPay = viewModel.extractedData["contactEmailRankPay"], !contactEmailRankPay.isEmpty {
                                DetailRow(title: "Rank Pay Email", value: contactEmailRankPay)
                            }
                            
                            if let contactEmailGeneral = viewModel.extractedData["contactEmailGeneral"], !contactEmailGeneral.isEmpty {
                                DetailRow(title: "General Query Email", value: contactEmailGeneral)
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
