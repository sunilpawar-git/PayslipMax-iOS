import Foundation
import SwiftData

/// A model representing personal information that can be encrypted for security
@Model
class PersonalInfo: Codable {
    // MARK: - Properties
    
    /// Unique identifier
    var id: UUID
    
    /// Person's full name
    var name: String
    
    /// Account number
    var accountNumber: String
    
    /// PAN (Permanent Account Number)
    var panNumber: String
    
    /// Indicates if the data is currently encrypted
    private var isEncrypted: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes a new PersonalInfo instance
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - name: Person's full name
    ///   - accountNumber: Account number
    ///   - panNumber: PAN number
    init(id: UUID = UUID(), name: String, accountNumber: String, panNumber: String) {
        self.id = id
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
    }
    
    // MARK: - Codable Implementation
    
    /// Keys used for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case id, name, accountNumber, panNumber, isEncrypted
    }
    
    /// Initializes a PersonalInfo from a decoder
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: An error if decoding fails
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        accountNumber = try container.decode(String.self, forKey: .accountNumber)
        panNumber = try container.decode(String.self, forKey: .panNumber)
        isEncrypted = try container.decodeIfPresent(Bool.self, forKey: .isEncrypted) ?? false
    }
    
    /// Encodes this PersonalInfo to an encoder
    /// - Parameter encoder: The encoder to write data to
    /// - Throws: An error if encoding fails
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(accountNumber, forKey: .accountNumber)
        try container.encode(panNumber, forKey: .panNumber)
        try container.encode(isEncrypted, forKey: .isEncrypted)
    }
}

// MARK: - Encryption
extension PersonalInfo {
    /// Encrypts all sensitive fields using the provided protector
    /// - Parameter protector: The service to use for encryption
    /// - Throws: An error if encryption fails
    func encrypt(using protector: SensitiveDataProtecting) throws {
        // Only encrypt if not already encrypted
        guard !isEncrypted else { return }
        
        name = try protector.encrypt(value: name, fieldName: "name")
        accountNumber = try protector.encrypt(value: accountNumber, fieldName: "accountNumber")
        panNumber = try protector.encrypt(value: panNumber, fieldName: "panNumber")
        
        isEncrypted = true
    }
    
    /// Decrypts all sensitive fields using the provided protector
    /// - Parameter protector: The service to use for decryption
    /// - Throws: An error if decryption fails
    func decrypt(using protector: SensitiveDataProtecting) throws {
        // Only decrypt if currently encrypted
        guard isEncrypted else { return }
        
        name = try protector.decrypt(value: name, fieldName: "name")
        accountNumber = try protector.decrypt(value: accountNumber, fieldName: "accountNumber")
        panNumber = try protector.decrypt(value: panNumber, fieldName: "panNumber")
        
        isEncrypted = false
    }
    
    /// Indicates whether the data is currently encrypted
    var isDataEncrypted: Bool {
        return isEncrypted
    }
} 