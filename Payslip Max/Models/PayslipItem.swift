import Foundation
import SwiftData

/// Protocol for encryption service used internally by models
protocol EncryptionServiceProtocolInternal {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ data: Data) throws -> Data
}

/// A model representing a payslip item with financial and personal information
@Model
class PayslipItem: Identifiable, Codable {
    // MARK: - Properties
    
    /// Unique identifier for the payslip
    var id: UUID
    
    /// Month of the payslip (e.g., "January")
    var month: String
    
    /// Year of the payslip (e.g., 2025)
    var year: Int
    
    /// Location/branch information
    var location: String
    
    /// Timestamp when the payslip was created or processed
    var timestamp: Date
    
    /// Personal information (name, account number, PAN)
    @Relationship(deleteRule: .cascade)
    var personalInfo: PersonalInfo
    
    /// Financial data (credits, debits, dspof, tax)
    @Relationship(deleteRule: .cascade)
    var financialData: FinancialData
    
    // MARK: - Encryption Service Factory
    
    /// Factory for creating instances of EncryptionServiceProtocol
    private static var encryptionServiceFactory: () -> Any = {
        fatalError("EncryptionService not properly configured - please set a factory before using")
    }
    
    /// Resets the encryption service factory to its default state
    static func resetEncryptionServiceFactory() {
        encryptionServiceFactory = { 
            fatalError("EncryptionService not properly configured - please set a factory before using") 
        }
    }
    
    /// Sets a custom factory for creating encryption service instances
    /// - Parameter factory: A closure that returns an encryption service
    static func setEncryptionServiceFactory(_ factory: @escaping () -> Any) {
        encryptionServiceFactory = factory
    }
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipItem with the provided values
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - month: Month of the payslip
    ///   - year: Year of the payslip
    ///   - location: Location/branch information
    ///   - personalInfo: Personal information
    ///   - financialData: Financial data
    ///   - timestamp: Timestamp (defaults to current date/time)
    init(id: UUID = UUID(),
         month: String,
         year: Int,
         location: String,
         personalInfo: PersonalInfo,
         financialData: FinancialData,
         timestamp: Date = Date()) {
        self.id = id
        self.month = month
        self.year = year
        self.location = location
        self.personalInfo = personalInfo
        self.financialData = financialData
        self.timestamp = timestamp
    }
    
    /// Initializes a new PayslipItem with individual values
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - month: Month of the payslip
    ///   - year: Year of the payslip
    ///   - credits: Total credits/income amount
    ///   - debits: Total debits/deductions amount
    ///   - dspof: DSPOF amount
    ///   - tax: Tax amount
    ///   - location: Location/branch information
    ///   - name: Employee name
    ///   - accountNumber: Account number
    ///   - panNumber: PAN number
    ///   - timestamp: Timestamp (defaults to current date/time)
    convenience init(id: UUID = UUID(),
                     month: String,
                     year: Int,
                     credits: Double,
                     debits: Double,
                     dspof: Double,
                     tax: Double,
                     location: String,
                     name: String,
                     accountNumber: String,
                     panNumber: String,
                     timestamp: Date = Date()) {
        let personalInfo = PersonalInfo(
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber
        )
        
        let financialData = FinancialData(
            credits: credits,
            debits: debits,
            dspof: dspof,
            tax: tax
        )
        
        self.init(
            id: id,
            month: month,
            year: year,
            location: location,
            personalInfo: personalInfo,
            financialData: financialData,
            timestamp: timestamp
        )
    }
    
    // MARK: - Codable Implementation
    
    /// Keys used for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case id, month, year, location, timestamp, personalInfo, financialData
    }
    
    /// Initializes a PayslipItem from a decoder
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: An error if decoding fails
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        month = try container.decode(String.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        location = try container.decode(String.self, forKey: .location)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        personalInfo = try container.decode(PersonalInfo.self, forKey: .personalInfo)
        financialData = try container.decode(FinancialData.self, forKey: .financialData)
    }
    
    /// Encodes this PayslipItem to an encoder
    /// - Parameter encoder: The encoder to write data to
    /// - Throws: An error if encoding fails
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(location, forKey: .location)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(personalInfo, forKey: .personalInfo)
        try container.encode(financialData, forKey: .financialData)
    }
}

// MARK: - Sensitive Data Handling
extension PayslipItem {
    /// Encrypts sensitive data fields in the payslip
    /// - Throws: An error if encryption fails
    func encryptSensitiveData() throws {
        guard let encryptionService = Self.encryptionServiceFactory() as? EncryptionServiceProtocolInternal else {
            throw SensitiveDataError.encryptionServiceNotConfigured
        }
        
        let protector = SensitiveDataProtector(encryptionService: encryptionService)
        try personalInfo.encrypt(using: protector)
    }
    
    /// Decrypts sensitive data fields in the payslip
    /// - Throws: An error if decryption fails
    func decryptSensitiveData() throws {
        guard let encryptionService = Self.encryptionServiceFactory() as? EncryptionServiceProtocolInternal else {
            throw SensitiveDataError.encryptionServiceNotConfigured
        }
        
        let protector = SensitiveDataProtector(encryptionService: encryptionService)
        try personalInfo.decrypt(using: protector)
    }
    
    /// Indicates whether this payslip contains encrypted sensitive data
    var containsEncryptedData: Bool {
        return personalInfo.isDataEncrypted
    }
}

// MARK: - Computed Properties
extension PayslipItem {
    /// Calculates the net amount (credits minus all deductions)
    var netAmount: Double {
        return financialData.netAmount
    }
    
    /// Returns a formatted string representation of the month and year
    var periodString: String {
        return "\(month) \(year)"
    }
    
    /// Employee name (convenience accessor)
    var name: String {
        return personalInfo.name
    }
    
    /// Account number (convenience accessor)
    var accountNumber: String {
        return personalInfo.accountNumber
    }
    
    /// PAN number (convenience accessor)
    var panNumber: String {
        return personalInfo.panNumber
    }
    
    /// Credits amount (convenience accessor)
    var credits: Double {
        return financialData.credits
    }
    
    /// Debits amount (convenience accessor)
    var debits: Double {
        return financialData.debits
    }
    
    /// DSPOF amount (convenience accessor)
    var dspof: Double {
        return financialData.dspof
    }
    
    /// Tax amount (convenience accessor)
    var tax: Double {
        return financialData.tax
    }
} 
