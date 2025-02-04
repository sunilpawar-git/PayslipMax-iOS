import SwiftUI
import SwiftData
import Foundation

@MainActor
final class PayslipDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published var error: Error?
    @Published private(set) var decryptedPayslip: PayslipItem?
    
    // MARK: - Properties
    private let securityService: SecurityServiceProtocol
    private let payslip: PayslipItem
    
    // MARK: - Initialization
    init(payslip: PayslipItem, securityService: SecurityServiceProtocol? = nil) {
        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
    }
    
    // MARK: - Public Methods
    func loadDecryptedData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let decrypted = payslip
            try decrypted.decryptSensitiveData()
            self.decryptedPayslip = decrypted
        } catch {
            self.error = error
        }
    }
} 