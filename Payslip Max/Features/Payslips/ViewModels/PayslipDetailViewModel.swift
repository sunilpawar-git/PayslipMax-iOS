import SwiftUI
import SwiftData
import Foundation

@MainActor
final class PayslipDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published var error: Error?
    @Published private(set) var decryptedPayslip: PayslipItem?
    @Published private(set) var netAmount: Double = 0.0
    @Published private(set) var formattedNetAmount: String = ""
    
    // MARK: - Properties
    private let securityService: SecurityServiceProtocol
    private let payslip: PayslipItem
    
    // MARK: - Initialization
    init(payslip: PayslipItem, securityService: SecurityServiceProtocol? = nil) {
        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
        calculateNetAmount()
    }
    
    // MARK: - Public Methods
    func loadDecryptedData() async {
        isLoading = true
        defer { isLoading = false }
        
        let decrypted = payslip
        do {
            try decrypted.decryptSensitiveData()
            self.decryptedPayslip = decrypted
        } catch {
            self.error = error
        }
        calculateNetAmount()
    }
    
    // Calculate and format the net amount
    private func calculateNetAmount() {
        let credits = payslip.credits
        let debits = payslip.debits
        let dspof = payslip.dspof
        let tax = payslip.tax
        
        netAmount = credits - (debits + dspof + tax)
        formattedNetAmount = Formatters.formatCurrency(netAmount)
    }
    
    // Format currency values for display
    func formatCurrency(_ value: Double) -> String {
        return Formatters.formatCurrency(value)
    }
    
    // Get formatted personal details for sharing
    func getShareText() -> String {
        guard let payslip = decryptedPayslip else {
            return "Payslip details not available"
        }
        
        return """
        Payslip Details
        
        Name: \(payslip.name)
        Month: \(payslip.month)
        Year: \(payslip.year)
        
        Credits: \(formatCurrency(payslip.credits))
        Debits: \(formatCurrency(payslip.debits))
        DSPOF: \(formatCurrency(payslip.dspof))
        Tax: \(formatCurrency(payslip.tax))
        Net Amount: \(formattedNetAmount)
        
        Location: \(payslip.location)
        """
    }
} 