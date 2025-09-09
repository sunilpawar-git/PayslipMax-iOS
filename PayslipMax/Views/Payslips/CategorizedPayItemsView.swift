import SwiftUI

/// A view that displays earnings and deductions categorized by type
struct CategorizedPayItemsView: View {
    @StateObject private var viewModel: CategorizedPayItemsViewModel

    init(earnings: [String: Double], deductions: [String: Double]) {
        let categorizationService = DIContainer.shared.resolve(PayItemCategorizationServiceProtocol.self)
            ?? PayItemCategorizationService()

        _viewModel = StateObject(wrappedValue: CategorizedPayItemsViewModel(
            earnings: earnings,
            deductions: deductions,
            categorizationService: categorizationService
        ))
    }

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                // Earnings Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("EARNINGS")
                        .font(.headline)
                        .foregroundColor(.primary)

                    // Categorized earnings
                    ForEach(viewModel.categorizedEarnings.keys.sorted(), id: \.self) { category in
                        if let items = viewModel.categorizedEarnings[category], !items.isEmpty {
                            CategorySection(
                                title: category,
                                items: items,
                                color: .green
                            )
                        }
                    }

                    // Total earnings
                    HStack {
                        Text("Total Earnings")
                            .font(.headline)
                        Spacer()
                        Text("₹\(CurrencyFormatter.format(viewModel.totalEarnings))")
                            .font(.headline)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Deductions Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("DEDUCTIONS")
                        .font(.headline)
                        .foregroundColor(.primary)

                    // Categorized deductions
                    ForEach(viewModel.categorizedDeductions.keys.sorted(), id: \.self) { category in
                        if let items = viewModel.categorizedDeductions[category], !items.isEmpty {
                            CategorySection(
                                title: category,
                                items: items,
                                color: .red
                            )
                        }
                    }

                    // Total deductions
                    HStack {
                        Text("Total Deductions")
                            .font(.headline)
                        Spacer()
                        Text("₹\(CurrencyFormatter.format(viewModel.totalDeductions))")
                            .font(.headline)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Net Pay Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("NET PAY")
                            .font(.headline)
                        Spacer()
                        Text("₹\(CurrencyFormatter.format(viewModel.netPay))")
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        }
    }
}


// MARK: - Preview

struct CategorizedPayItemsView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            CategorizedPayItemsView(
                earnings: [
                    "Basic Pay": 50000,
                    "Dearness Allowance": 10000,
                    "House Rent Allowance": 15000,
                    "Transport Allowance": 3000,
                    "Special Duty Allowance": 5000
                ],
                deductions: [
                    "Income Tax": 8000,
                    "DSOP Fund": 5000,
                    "AGIF": 2000,
                    "Mess Bill": 3000,
                    "Electricity Charges": 1500,
                    "Water Charges": 500
                ]
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
