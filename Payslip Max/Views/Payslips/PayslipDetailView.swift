import SwiftUI
import SwiftData

struct PayslipDetailView: View {
    let payslip: any PayslipItemProtocol
    @StateObject private var viewModel: PayslipDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    /// - Parameters:
    ///   - payslip: The payslip to display.
    ///   - viewModel: The view model.
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
                    Section {
                        DetailRow(title: "Name", value: decryptedPayslip.name)
                        DetailRow(title: "Month", value: decryptedPayslip.month)
                        DetailRow(title: "Year", value: String(decryptedPayslip.year))
                        DetailRow(title: "Location", value: decryptedPayslip.location)
                    } header: {
                        Text("Personal Details")
                    }
                    
                    Section {
                        DetailRow(title: "Credits", value: viewModel.formatCurrency(decryptedPayslip.credits))
                        DetailRow(title: "Debits", value: viewModel.formatCurrency(decryptedPayslip.debits))
                        DetailRow(title: "DSPOF", value: viewModel.formatCurrency(decryptedPayslip.dspof))
                        DetailRow(title: "Tax", value: viewModel.formatCurrency(decryptedPayslip.tax))
                        DetailRow(title: "Net Amount", value: viewModel.formattedNetAmount)
                    } header: {
                        Text("Financial Details")
                    }
                    
                    Section {
                        DetailRow(title: "Account Number", value: decryptedPayslip.accountNumber)
                        DetailRow(title: "PAN Number", value: decryptedPayslip.panNumber)
                    } header: {
                        Text("Other Details")
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Payslip Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            CustomShareSheet(text: viewModel.getShareText())
        }
        .task {
            await viewModel.loadDecryptedData()
        }
        .alert(
            "Error",
            isPresented: Binding<Bool>(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) { }
            },
            message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        )
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

