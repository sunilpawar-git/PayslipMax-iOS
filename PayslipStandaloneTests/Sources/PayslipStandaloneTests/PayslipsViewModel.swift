import Foundation

@MainActor
class PayslipsViewModel: ObservableObject {
    @Published var payslips: [StandalonePayslipItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }
    
    func loadPayslips() async {
        isLoading = true
        error = nil
        
        do {
            // Ensure the service is initialized
            if !dataService.isInitialized {
                try await dataService.initialize()
            }
            
            // Fetch payslips
            payslips = try await dataService.fetch(StandalonePayslipItem.self)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func addPayslip(_ payslip: StandalonePayslipItem) async {
        isLoading = true
        error = nil
        
        do {
            // Ensure the service is initialized
            if !dataService.isInitialized {
                try await dataService.initialize()
            }
            
            // Save the payslip
            try await dataService.save(payslip)
            
            // Reload payslips
            await loadPayslips()
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func deletePayslip(_ payslip: StandalonePayslipItem) async {
        isLoading = true
        error = nil
        
        do {
            // Ensure the service is initialized
            if !dataService.isInitialized {
                try await dataService.initialize()
            }
            
            // Delete the payslip
            try await dataService.delete(payslip)
            
            // Reload payslips
            await loadPayslips()
        } catch {
            self.error = error
            isLoading = false
        }
    }
} 