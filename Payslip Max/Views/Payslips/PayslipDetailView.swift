import SwiftUI
import SwiftData

struct PayslipDetailView: View {
    let payslip: PayslipItem
    @StateObject private var viewModel: PayslipDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(payslip: PayslipItem) {
        self.payslip = payslip
        self._viewModel = StateObject(wrappedValue: PayslipDetailViewModel(payslip: payslip))
    }
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if let decryptedPayslip = viewModel.decryptedPayslip {
                Section("Personal Details") {
                    DetailRow(title: "Name", value: decryptedPayslip.name)
                    DetailRow(title: "Account Number", value: decryptedPayslip.accountNumber)
                    DetailRow(title: "PAN", value: decryptedPayslip.panNumber)
                }
                
                Section("Financial Details") {
                    DetailRow(title: "Credits", value: String(format: "₹%.2f", decryptedPayslip.credits))
                    DetailRow(title: "Debits", value: String(format: "₹%.2f", decryptedPayslip.debits))
                    DetailRow(title: "DSOPF", value: String(format: "₹%.2f", decryptedPayslip.dsopf))
                    DetailRow(title: "Tax", value: String(format: "₹%.2f", decryptedPayslip.tax))
                }
                
                Section("Other Details") {
                    DetailRow(title: "Month", value: decryptedPayslip.month)
                    DetailRow(title: "Year", value: String(decryptedPayslip.year))
                    DetailRow(title: "Location", value: decryptedPayslip.location)
                }
            }
        }
        .navigationTitle("Payslip Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: "Payslip Details") {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task {
            await viewModel.loadDecryptedData()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

private struct DetailRow: View {
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