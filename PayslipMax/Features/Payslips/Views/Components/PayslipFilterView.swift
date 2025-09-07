import SwiftUI

// Filter model for payslips
struct PayslipFilter {
    let searchText: String
    let sortOrder: PayslipSortOrder
}

// Simple filter view
struct PayslipFilterView: View {
    let onApplyFilter: (PayslipFilter) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    TextField("Search by name, month, or year", text: $searchText)
                }

                Section(header: Text("Sort By")) {
                    Picker("Sort Order", selection: $sortOrder) {
                        ForEach(PayslipSortOrder.allCases) { order in
                            Text(order.displayName).tag(order)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section {
                    Button("Apply Filters") {
                        onApplyFilter(PayslipFilter(searchText: searchText, sortOrder: sortOrder))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.accentColor)

                    Button("Cancel") {
                        onDismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter Payslips")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @State private var searchText: String = ""
    @State private var sortOrder: PayslipSortOrder = .dateDescending
}
