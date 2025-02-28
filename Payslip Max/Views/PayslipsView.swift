import SwiftUI

/// View model for the payslips screen
class PayslipsViewModel: ObservableObject {
    /// Data service for fetching payslips
    private let dataService: DataServiceProtocol
    
    /// Published payslips
    @Published var payslips: [PayslipItem] = []
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message
    @Published var errorMessage: String?
    
    /// Initializes a new payslips view model
    /// - Parameter dataService: The data service
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }
    
    /// Loads payslips from the data service
    func loadPayslips() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real implementation, this would fetch from the data service
            // For now, we'll just use placeholder data
            payslips = [
                PayslipItem(id: UUID(), title: "May 2023", amount: 3250.00, date: Date()),
                PayslipItem(id: UUID(), title: "April 2023", amount: 3250.00, date: Date().addingTimeInterval(-2592000)),
                PayslipItem(id: UUID(), title: "March 2023", amount: 3100.00, date: Date().addingTimeInterval(-5184000))
            ]
            isLoading = false
        } catch {
            errorMessage = "Failed to load payslips: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

/// Payslips view displaying a list of payslips
struct PayslipsView: View {
    /// View model for the payslips screen
    @ObservedObject var viewModel: PayslipsViewModel
    
    /// Navigation router
    @EnvironmentObject private var router: NavRouter
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading payslips...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("Error")
                        .font(.title)
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Retry") {
                        Task {
                            await viewModel.loadPayslips()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.payslips.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Payslips Found")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Add your first payslip to get started")
                        .foregroundColor(.secondary)
                    
                    Button("Add Payslip") {
                        router.presentSheet(.addPayslip)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.payslips) { payslip in
                        Button {
                            router.navigate(to: .payslipDetail(id: payslip.id))
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(payslip.title)
                                        .font(.headline)
                                    
                                    Text(payslip.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("$\(String(format: "%.2f", payslip.amount))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Payslips")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    router.presentSheet(.addPayslip)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadPayslips()
        }
    }
}

/// Simple payslip item model
struct PayslipItem: Identifiable {
    let id: UUID
    let title: String
    let amount: Double
    let date: Date
}

#Preview {
    NavigationStack {
        PayslipsView(viewModel: PayslipsViewModel(dataService: MockDataService()))
            .environmentObject(NavRouter())
    }
}

/// Mock data service for previews
class MockDataService: DataServiceProtocol {
    var isInitialized: Bool = true
    
    func initialize() async throws {
        // No-op for mock
    }
    
    func save<T: Codable>(_ item: T) async throws {
        // No-op for mock
    }
    
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T] {
        return []
    }
    
    func delete<T: Codable>(_ item: T) async throws {
        // No-op for mock
    }
} 