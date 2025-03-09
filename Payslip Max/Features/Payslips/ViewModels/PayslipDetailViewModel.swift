import SwiftUI
import SwiftData
import Foundation
import Combine

@MainActor
final class PayslipDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published var error: AppError?
    @Published private(set) var decryptedPayslip: (any PayslipItemProtocol)?
    @Published private(set) var netAmount: Double = 0.0
    @Published private(set) var formattedNetAmount: String = ""
    @Published var showShareSheet = false
    
    // MARK: - Properties
    private let securityService: SecurityServiceProtocol
    private(set) var payslip: any PayslipItemProtocol
    private let dataService: DataServiceProtocol
    private let pdfFilename: String
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipDetailViewModel with the specified payslip and security service.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to display details for.
    ///   - securityService: The security service to use for sensitive data operations.
    ///   - dataService: The data service to use for saving data.
    init(payslip: any PayslipItemProtocol, securityService: SecurityServiceProtocol? = nil, dataService: DataServiceProtocol? = nil) {
        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        
        // Convert to PayslipItem if needed
        if let item = payslip as? PayslipItem {
            self.decryptedPayslip = item
        } else {
            // Create a new PayslipItem with the same data
            self.decryptedPayslip = PayslipItem(
                month: payslip.month,
                year: payslip.year,
                credits: payslip.credits,
                debits: payslip.debits,
                dspof: payslip.dspof,
                tax: payslip.tax,
                location: payslip.location,
                name: payslip.name,
                accountNumber: payslip.accountNumber,
                panNumber: payslip.panNumber,
                timestamp: payslip.timestamp
            )
        }
        
        // Set the PDF filename
        self.pdfFilename = "payslip_\(payslip.month.lowercased())_\(payslip.year).pdf"
        
        calculateNetAmount()
    }
    
    // MARK: - Public Methods
    
    /// Loads and decrypts sensitive data in the payslip.
    ///
    /// This method decrypts the sensitive data in the payslip and updates the decryptedPayslip property.
    func loadDecryptedData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Since PayslipItemProtocol is a protocol, we need to create a copy differently
        // For now, we'll just use the original payslip and decrypt it
        do {
            // We need to handle this differently since we can't just copy a protocol
            // For PayslipItem, we can cast and use it directly
            if let concretePayslip = payslip as? PayslipItem {
                let decrypted = concretePayslip
                try decrypted.decryptSensitiveData()
                self.decryptedPayslip = decrypted
            } else {
                // For other implementations, we'll need to decrypt the original
                try payslip.decryptSensitiveData()
                self.decryptedPayslip = payslip
            }
        } catch {
            self.error = AppError.from(error)
        }
        calculateNetAmount()
    }
    
    /// Calculates and formats the net amount.
    ///
    /// This method calculates the net amount based on the payslip's credits, debits, DSPOF, and tax,
    /// and formats it as a currency string.
    private func calculateNetAmount() {
        // Use the protocol's calculateNetAmount method
        netAmount = payslip.calculateNetAmount()
        formattedNetAmount = Formatters.formatCurrency(netAmount)
    }
    
    /// Formats a value as a currency string.
    ///
    /// - Parameter value: The value to format.
    /// - Returns: A formatted currency string.
    func formatCurrency(_ value: Double) -> String {
        return Formatters.formatCurrency(value)
    }
    
    /// Gets a formatted string representation of the payslip for sharing.
    ///
    /// - Returns: A formatted string with payslip details.
    func getShareText() -> String {
        guard let payslip = decryptedPayslip else {
            return "Payslip details not available"
        }
        
        // Use the protocol's formattedDescription method
        return payslip.formattedDescription()
    }
    
    /// Updates the payslip with corrected data.
    ///
    /// - Parameter correctedPayslip: The corrected payslip data.
    func updatePayslip(_ correctedPayslip: PayslipItem) {
        Task {
            do {
                // Initialize the data service if needed
                if !dataService.isInitialized {
                    try await dataService.initialize()
                }
                
                // Update the payslip
                try await dataService.save(correctedPayslip)
                
                // Update the published payslip
                self.decryptedPayslip = correctedPayslip
                
                print("PayslipDetailViewModel: Updated payslip with corrected data")
            } catch {
                handleError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
    }
} 