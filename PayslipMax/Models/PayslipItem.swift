import Foundation
import SwiftData

// Adapter to make EncryptionService compatible with SensitiveDataEncryptionService
class EncryptionServiceAdapter: EncryptionServiceProtocolInternal {
    private let encryptionService: EncryptionServiceProtocolInternal
    
    init(encryptionService: EncryptionServiceProtocolInternal) {
        self.encryptionService = encryptionService
    }
    
    func encrypt(_ data: Data) throws -> Data {
        return try encryptionService.encrypt(data)
    }
    
    func decrypt(_ data: Data) throws -> Data {
        return try encryptionService.decrypt(data)
    }
}

// Define the protocol here to avoid import issues
typealias EncryptionServiceProtocolInternal = EncryptionServiceProtocol

@Model
class PayslipItem: PayslipItemProtocol {
    var id: UUID
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var name: String
    var accountNumber: String
    var panNumber: String
    var timestamp: Date
    var pdfData: Data?
    
    // Add earnings and deductions dictionaries
    var earnings: [String: Double] = [:]
    var deductions: [String: Double] = [:]
    
    // Internal flags for sensitive data encryption status
    internal var isNameEncrypted: Bool = false
    internal var isAccountNumberEncrypted: Bool = false
    internal var isPanNumberEncrypted: Bool = false
    
    // MARK: - PayslipItemProtocol Methods
    
    /// Encrypts sensitive data in the payslip.
    /// This method now uses the PayslipEncryptionService instead of direct implementation.
    func encryptSensitiveData() throws {
        // Create a copy of self that can be passed as inout
        var payslipCopy: any PayslipItemProtocol = PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            timestamp: timestamp,
            pdfData: pdfData
        )
        payslipCopy.earnings = earnings
        payslipCopy.deductions = deductions
        
        // Use the service to encrypt the copy
        let service = Self.resolveEncryptionService()
        let result = try service.encryptSensitiveData(in: &payslipCopy)
        
        // Update encryption flags based on the result
        isNameEncrypted = result.nameEncrypted
        isAccountNumberEncrypted = result.accountNumberEncrypted
        isPanNumberEncrypted = result.panNumberEncrypted
        
        // Update fields with the encrypted versions
        name = payslipCopy.name
        accountNumber = payslipCopy.accountNumber
        panNumber = payslipCopy.panNumber
    }
    
    /// Decrypts sensitive data in the payslip.
    /// This method now uses the PayslipEncryptionService instead of direct implementation.
    func decryptSensitiveData() throws {
        // Only attempt to decrypt if fields are encrypted
        if !isNameEncrypted && !isAccountNumberEncrypted && !isPanNumberEncrypted {
            return
        }
        
        // Create a copy of self that can be passed as inout
        var payslipCopy: any PayslipItemProtocol = PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            timestamp: timestamp,
            pdfData: pdfData
        )
        payslipCopy.earnings = earnings
        payslipCopy.deductions = deductions
        
        // Use the service to decrypt the copy
        let service = Self.resolveEncryptionService()
        let result = try service.decryptSensitiveData(in: &payslipCopy)
        
        // Update encryption flags based on the result
        isNameEncrypted = !result.nameDecrypted
        isAccountNumberEncrypted = !result.accountNumberDecrypted
        isPanNumberEncrypted = !result.panNumberDecrypted
        
        // Update fields with the decrypted versions
        name = payslipCopy.name
        accountNumber = payslipCopy.accountNumber
        panNumber = payslipCopy.panNumber
    }
    
    // MARK: - Encryption Service Resolution
    
    /// Resolves the appropriate PayslipEncryptionService.
    /// This method provides a migration path from the old approach to the new service-based approach.
    private static func resolveEncryptionService() -> PayslipEncryptionServiceProtocol {
        // Try to get from DIContainer
        if let container = try? DIContainerResolver.resolve() {
            return container.makePayslipEncryptionService()
        }
        
        // Fallback: Create using the factory
        do {
            return try PayslipEncryptionService.Factory.create()
        } catch {
            // Log error and return fallback
            print("Error resolving PayslipEncryptionService: \(error.localizedDescription)")
            return FallbackPayslipEncryptionService(error: error)
        }
    }
    
    // MARK: - Initialization and Other Methods
    
    init(id: UUID = UUID(),
         month: String,
         year: Int,
         credits: Double,
         debits: Double,
         dsop: Double, 
         tax: Double,
         name: String,
         accountNumber: String,
         panNumber: String,
         timestamp: Date = Date(),
         pdfData: Data? = nil) {
        
        self.id = id
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits
        self.dsop = dsop
        self.tax = tax
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.timestamp = timestamp
        self.pdfData = pdfData
    }
    
    enum CodingKeys: String, CodingKey {
        case id, month, year, credits, debits, dsop, tax, name, accountNumber, panNumber, timestamp, pdfData
        case isNameEncrypted, isAccountNumberEncrypted, isPanNumberEncrypted
        case earnings, deductions
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        month = try container.decode(String.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        credits = try container.decode(Double.self, forKey: .credits)
        debits = try container.decode(Double.self, forKey: .debits)
        dsop = try container.decode(Double.self, forKey: .dsop)
        tax = try container.decode(Double.self, forKey: .tax)
        name = try container.decode(String.self, forKey: .name)
        accountNumber = try container.decode(String.self, forKey: .accountNumber)
        panNumber = try container.decode(String.self, forKey: .panNumber)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        pdfData = try container.decodeIfPresent(Data.self, forKey: .pdfData)
        
        earnings = try container.decodeIfPresent([String: Double].self, forKey: .earnings) ?? [:]
        deductions = try container.decodeIfPresent([String: Double].self, forKey: .deductions) ?? [:]
        
        isNameEncrypted = try container.decodeIfPresent(Bool.self, forKey: .isNameEncrypted) ?? false
        isAccountNumberEncrypted = try container.decodeIfPresent(Bool.self, forKey: .isAccountNumberEncrypted) ?? false
        isPanNumberEncrypted = try container.decodeIfPresent(Bool.self, forKey: .isPanNumberEncrypted) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(credits, forKey: .credits)
        try container.encode(debits, forKey: .debits)
        try container.encode(dsop, forKey: .dsop)
        try container.encode(tax, forKey: .tax)
        try container.encode(name, forKey: .name)
        try container.encode(accountNumber, forKey: .accountNumber)
        try container.encode(panNumber, forKey: .panNumber)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(pdfData, forKey: .pdfData)
        try container.encode(earnings, forKey: .earnings)
        try container.encode(deductions, forKey: .deductions)
        try container.encode(isNameEncrypted, forKey: .isNameEncrypted)
        try container.encode(isAccountNumberEncrypted, forKey: .isAccountNumberEncrypted)
        try container.encode(isPanNumberEncrypted, forKey: .isPanNumberEncrypted)
    }
    
    // MARK: - Derived Fields Calculation
    
    /// Calculates derived fields based on the current values of earnings and deductions.
    func calculateDerivedFields() {
        // Calculate total credits from earnings
        credits = earnings.values.reduce(0, +)
        
        // Calculate total debits from deductions
        debits = deductions.values.reduce(0, +)
        
        // Calculate tax from deductions if not already set
        if tax == 0 {
            tax = deductions["ITAX"] ?? deductions["Income Tax"] ?? deductions["Tax"] ?? 0
        }
        
        // Calculate DSOP from deductions if not already set
        if dsop == 0 {
            dsop = deductions["DSOP"] ?? deductions["PF"] ?? deductions["Provident Fund"] ?? 0
        }
    }
}

// MARK: - DIContainer Resolver Helper

/// Helper for resolving the DIContainer.
/// This avoids direct dependency on DIContainer.shared.
private enum DIContainerResolver {
    static func resolve() throws -> DIContainerProtocol {
        guard let container = findContainerInApp() else {
            throw NSError(
                domain: "PayslipItem",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Could not resolve DIContainer"]
            )
        }
        return container
    }
    
    private static func findContainerInApp() -> DIContainerProtocol? {
        // Try to get the shared container - without explicit dependency
        let containerClass = NSClassFromString("Payslip_Max.DIContainer") as? NSObject.Type
        let container = containerClass?.value(forKey: "shared") as? DIContainerProtocol
        return container
    }
}

// MARK: - Factory Implementation
class PayslipItemFactory: PayslipItemFactoryProtocol {
    /// Creates an empty payslip item.
    ///
    /// - Returns: An empty payslip item.
    static func createEmpty() -> any PayslipItemProtocol {
        let payslip = PayslipItem(
            month: "",
            year: Calendar.current.component(.year, from: Date()),
            credits: 0,
            debits: 0,
            dsop: 0,
            tax: 0,
            name: "",
            accountNumber: "",
            panNumber: "",
            pdfData: nil
        )
        
        payslip.earnings = [:]
        payslip.deductions = [:]
        
        return payslip
    }
    
    /// Creates a sample payslip item for testing or preview.
    ///
    /// - Returns: A sample payslip item.
    static func createSample() -> any PayslipItemProtocol {
        let payslip = PayslipItem(
            month: "January",
            year: 2025,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 800.0,
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            pdfData: nil
        )
        
        // Add sample earnings
        payslip.earnings = [
            "Basic Pay": 3000.0,
            "DA": 1500.0,
            "MSP": 500.0
        ]
        
        // Add sample deductions
        payslip.deductions = [
            "DSOP": 500.0,
            "ITAX": 800.0,
            "AGIF": 200.0
        ]
        
        return payslip
    }
} 


