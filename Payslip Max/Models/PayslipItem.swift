import Foundation
import SwiftData

// Adapter to make EncryptionService compatible with SensitiveDataEncryptionService
class EncryptionServiceAdapter: SensitiveDataEncryptionService {
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
protocol EncryptionServiceProtocolInternal {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ data: Data) throws -> Data
}

@Model
class PayslipItem: PayslipItemProtocol {
    var id: UUID
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var location: String
    var name: String
    var accountNumber: String
    var panNumber: String
    var timestamp: Date
    var pdfData: Data?
    
    // Add earnings and deductions dictionaries
    var earnings: [String: Double] = [:]
    var deductions: [String: Double] = [:]
    
    // Private flags for sensitive data encryption status
    private var isNameEncrypted: Bool = false
    private var isAccountNumberEncrypted: Bool = false
    private var isPanNumberEncrypted: Bool = false
    
    // Factory for creating instances of EncryptionServiceProtocol
    private static var encryptionServiceFactory: () -> Any = {
        fatalError("EncryptionService not properly configured - please set a factory before using")
    }
    
    // Reset to default factory
    static func resetEncryptionServiceFactory() {
        encryptionServiceFactory = { 
            fatalError("EncryptionService not properly configured - please set a factory before using") 
        }
        
        // Also reset the sensitive data handler factory
        PayslipSensitiveDataHandler.Factory.resetEncryptionServiceFactory()
    }
    
    // Set a custom factory for testing
    static func setEncryptionServiceFactory(_ factory: @escaping () -> Any) -> Any {
        encryptionServiceFactory = factory
        
        // Also set the factory for the sensitive data handler
        let result = PayslipSensitiveDataHandler.Factory.setEncryptionServiceFactory {
            if let encryptionService = factory() as? EncryptionServiceProtocolInternal {
                return EncryptionServiceAdapter(encryptionService: encryptionService)
            }
            fatalError("Failed to create encryption service adapter")
        }
        print("PayslipItem: Encryption service factory configured with result: \(result)")
        return result
    }
    
    init(id: UUID = UUID(),
         month: String,
         year: Int,
         credits: Double,
         debits: Double,
         dsop: Double, 
         tax: Double,
         location: String,
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
        self.location = location
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.timestamp = timestamp
        self.pdfData = pdfData
    }
    
    enum CodingKeys: String, CodingKey {
        case id, month, year, credits, debits, dsop, tax, location, name, accountNumber, panNumber, timestamp, pdfData
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
        location = try container.decode(String.self, forKey: .location)
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
        try container.encode(location, forKey: .location)
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
}

// MARK: - Sensitive Data Handling
extension PayslipItem {
    // Implementation of PayslipItemProtocol methods
    
    func encryptSensitiveData() throws {
        // Use the sensitive data handler if available
        do {
            let handler = try PayslipSensitiveDataHandler.Factory.create()
            let encrypted = try handler.encryptSensitiveFields(
                name: isNameEncrypted ? name : name,
                accountNumber: isAccountNumberEncrypted ? accountNumber : accountNumber,
                panNumber: isPanNumberEncrypted ? panNumber : panNumber
            )
            
            // Only update if not already encrypted
            if !isNameEncrypted {
                name = encrypted.name
                isNameEncrypted = true
            }
            
            if !isAccountNumberEncrypted {
                accountNumber = encrypted.accountNumber
                isAccountNumberEncrypted = true
            }
            
            if !isPanNumberEncrypted {
                panNumber = encrypted.panNumber
                isPanNumberEncrypted = true
            }
        } catch {
            // Fall back to the old implementation if the handler creation fails
            try legacyEncryptSensitiveData()
        }
    }
    
    func decryptSensitiveData() throws {
        // Use the sensitive data handler if available
        do {
            let handler = try PayslipSensitiveDataHandler.Factory.create()
            
            // Only decrypt if currently encrypted
            if isNameEncrypted && isAccountNumberEncrypted && isPanNumberEncrypted {
                let decrypted = try handler.decryptSensitiveFields(
                    name: name,
                    accountNumber: accountNumber,
                    panNumber: panNumber
                )
                
                name = decrypted.name
                accountNumber = decrypted.accountNumber
                panNumber = decrypted.panNumber
                
                isNameEncrypted = false
                isAccountNumberEncrypted = false
                isPanNumberEncrypted = false
            }
        } catch {
            // Fall back to the old implementation if the handler creation fails
            try legacyDecryptSensitiveData()
        }
    }
    
    // Legacy implementation for backward compatibility
    private func legacyEncryptSensitiveData() throws {
        guard let encryptionService = Self.encryptionServiceFactory() as? EncryptionServiceProtocolInternal else {
            fatalError("Failed to create encryption service")
        }
        
        // Only encrypt if not already encrypted
        if !isNameEncrypted {
            let nameData = name.data(using: .utf8) ?? Data()
            let encryptedNameData = try encryptionService.encrypt(nameData)
            name = encryptedNameData.base64EncodedString()
            isNameEncrypted = true
        }
        
        if !isAccountNumberEncrypted {
            let accountData = accountNumber.data(using: .utf8) ?? Data()
            let encryptedAccountData = try encryptionService.encrypt(accountData)
            accountNumber = encryptedAccountData.base64EncodedString()
            isAccountNumberEncrypted = true
        }
        
        if !isPanNumberEncrypted {
            let panData = panNumber.data(using: .utf8) ?? Data()
            let encryptedPanData = try encryptionService.encrypt(panData)
            panNumber = encryptedPanData.base64EncodedString()
            isPanNumberEncrypted = true
        }
    }
    
    private func legacyDecryptSensitiveData() throws {
        guard let encryptionService = Self.encryptionServiceFactory() as? EncryptionServiceProtocolInternal else {
            fatalError("Failed to create encryption service")
        }
        
        // Only decrypt if currently encrypted
        if isNameEncrypted {
            guard let nameData = Data(base64Encoded: name) else {
                throw NSError(domain: "PayslipItem", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 data for name"])
            }
            let decryptedNameData = try encryptionService.decrypt(nameData)
            guard let decryptedName = String(data: decryptedNameData, encoding: .utf8) else {
                throw NSError(domain: "PayslipItem", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode name data"])
            }
            name = decryptedName
            isNameEncrypted = false
        }
        
        if isAccountNumberEncrypted {
            guard let accountData = Data(base64Encoded: accountNumber) else {
                throw NSError(domain: "PayslipItem", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 data for account number"])
            }
            let decryptedAccountData = try encryptionService.decrypt(accountData)
            guard let decryptedAccount = String(data: decryptedAccountData, encoding: .utf8) else {
                throw NSError(domain: "PayslipItem", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to decode account number data"])
            }
            accountNumber = decryptedAccount
            isAccountNumberEncrypted = false
        }
        
        if isPanNumberEncrypted {
            guard let panData = Data(base64Encoded: panNumber) else {
                throw NSError(domain: "PayslipItem", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 data for PAN number"])
            }
            let decryptedPanData = try encryptionService.decrypt(panData)
            guard let decryptedPan = String(data: decryptedPanData, encoding: .utf8) else {
                throw NSError(domain: "PayslipItem", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to decode PAN number data"])
            }
            panNumber = decryptedPan
            isPanNumberEncrypted = false
        }
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
            location: "",
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
            location: "Test Location",
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
