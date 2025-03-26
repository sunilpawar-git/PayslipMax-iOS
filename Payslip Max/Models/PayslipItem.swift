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
    
    // Add encryptionService property
    private var encryptionService: SensitiveDataEncryptionService {
        let service = Self.encryptionServiceFactory()
        return EncryptionServiceAdapter(encryptionService: service)
    }
    
    // MARK: - Encryption Service Factory
    
    private static var encryptionServiceFactory: () -> EncryptionServiceProtocolInternal = {
        return EncryptionService()
    }
    
    static func setEncryptionServiceFactory(_ factory: @escaping () -> EncryptionServiceProtocolInternal) {
        encryptionServiceFactory = factory
    }
    
    static func resetEncryptionServiceFactory() {
        encryptionServiceFactory = {
            return EncryptionService()
        }
    }
    
    static func getEncryptionServiceFactory() -> () -> EncryptionServiceProtocolInternal {
        return encryptionServiceFactory
    }
    
    // MARK: - Sensitive Data Handling
    
    private func encryptSensitiveData(service: SensitiveDataEncryptionService) throws {
        // Only encrypt if not already encrypted
        if !isNameEncrypted {
            let nameData = name.data(using: .utf8) ?? Data()
            name = try String(data: service.encrypt(nameData), encoding: .utf8) ?? name
            isNameEncrypted = true
        }
        
        if !isAccountNumberEncrypted {
            let accountData = accountNumber.data(using: .utf8) ?? Data()
            accountNumber = try String(data: service.encrypt(accountData), encoding: .utf8) ?? accountNumber
            isAccountNumberEncrypted = true
        }
        
        if !isPanNumberEncrypted {
            let panData = panNumber.data(using: .utf8) ?? Data()
            panNumber = try String(data: service.encrypt(panData), encoding: .utf8) ?? panNumber
            isPanNumberEncrypted = true
        }
    }
    
    private func decryptSensitiveData(service: SensitiveDataEncryptionService) throws {
        // Only decrypt if currently encrypted
        if isNameEncrypted {
            let nameData = name.data(using: .utf8) ?? Data()
            name = try String(data: service.decrypt(nameData), encoding: .utf8) ?? name
            isNameEncrypted = false
        }
        
        if isAccountNumberEncrypted {
            let accountData = accountNumber.data(using: .utf8) ?? Data()
            accountNumber = try String(data: service.decrypt(accountData), encoding: .utf8) ?? accountNumber
            isAccountNumberEncrypted = false
        }
        
        if isPanNumberEncrypted {
            let panData = panNumber.data(using: .utf8) ?? Data()
            panNumber = try String(data: service.decrypt(panData), encoding: .utf8) ?? panNumber
            isPanNumberEncrypted = false
        }
    }
    
    func encryptSensitiveData() throws {
        try encryptSensitiveData(service: encryptionService)
    }
    
    func decryptSensitiveData() throws {
        try decryptSensitiveData(service: encryptionService)
    }
    
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
