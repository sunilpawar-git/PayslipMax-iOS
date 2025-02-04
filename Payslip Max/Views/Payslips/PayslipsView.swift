import SwiftUI
import SwiftData

struct PayslipsView: View {
    @StateObject private var viewModel = PayslipsViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var payslips: [PayslipItem]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filterPayslips(payslips)) { payslip in
                    NavigationLink {
                        PayslipDetailView(payslip: payslip)
                    } label: {
                        PayslipRow(payslip: payslip)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deletePayslip(payslips[index], from: modelContext)
                    }
                }
            }
            .searchable(text: $viewModel.searchText)
            .navigationTitle("Payslips")
            .toolbar {
                Menu {
                    Picker("Sort Order", selection: $viewModel.sortOrder) {
                        Text("Date ↑").tag(PayslipsViewModel.SortOrder.dateAscending)
                        Text("Date ↓").tag(PayslipsViewModel.SortOrder.dateDescending)
                        Text("Name ↑").tag(PayslipsViewModel.SortOrder.nameAscending)
                        Text("Name ↓").tag(PayslipsViewModel.SortOrder.nameDescending)
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
    }
} 