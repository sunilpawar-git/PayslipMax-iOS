import Foundation
import SwiftData

@Model
final class PayslipItem: Codable {
    var id: UUID
    var timestamp: Date
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsopf: Double
    var tax: Double
    var location: String
    var name: String
    var accountNumber: String
    var panNumber: String
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         month: String,
         year: Int,
         credits: Double,
         debits: Double,
         dsopf: Double,
         tax: Double,
         location: String,
         name: String,
         accountNumber: String,
         panNumber: String) {
        self.id = id
        self.timestamp = timestamp
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits
        self.dsopf = dsopf
        self.tax = tax
        self.location = location
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
    }
    
    // Codable requirements
    enum CodingKeys: String, CodingKey {
        case id, timestamp, month, year, credits, debits, dsopf, tax, location, name, accountNumber, panNumber
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        month = try container.decode(String.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        credits = try container.decode(Double.self, forKey: .credits)
        debits = try container.decode(Double.self, forKey: .debits)
        dsopf = try container.decode(Double.self, forKey: .dsopf)
        tax = try container.decode(Double.self, forKey: .tax)
        location = try container.decode(String.self, forKey: .location)
        name = try container.decode(String.self, forKey: .name)
        accountNumber = try container.decode(String.self, forKey: .accountNumber)
        panNumber = try container.decode(String.self, forKey: .panNumber)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(credits, forKey: .credits)
        try container.encode(debits, forKey: .debits)
        try container.encode(dsopf, forKey: .dsopf)
        try container.encode(tax, forKey: .tax)
        try container.encode(location, forKey: .location)
        try container.encode(name, forKey: .name)
        try container.encode(accountNumber, forKey: .accountNumber)
        try container.encode(panNumber, forKey: .panNumber)
    }
}

// Extension for sensitive data handling
extension PayslipItem {
    var sensitiveFields: [String: String] {
        [
            "accountNumber": accountNumber,
            "panNumber": panNumber,
            "name": name
        ]
    }
    
    func encryptSensitiveData() throws {
        // Get encryption service
        let encryptionService = EncryptionService()
        
        // Encrypt each sensitive field
        for (key, value) in sensitiveFields {
            let data = value.data(using: .utf8) ?? Data()
            let encryptedData = try encryptionService.encrypt(data)
            
            // Store encrypted value based on field
            switch key {
            case "accountNumber":
                self.accountNumber = encryptedData.base64EncodedString()
            case "panNumber":
                self.panNumber = encryptedData.base64EncodedString()
            case "name":
                self.name = encryptedData.base64EncodedString()
            default:
                break
            }
        }
    }
    
    func decryptSensitiveData() throws {
        // Get encryption service
        let encryptionService = EncryptionService()
        
        // Decrypt each sensitive field
        for key in sensitiveFields.keys {
            let encryptedValue: String
            
            // Get encrypted value based on field
            switch key {
            case "accountNumber":
                encryptedValue = accountNumber
            case "panNumber":
                encryptedValue = panNumber
            case "name":
                encryptedValue = name
            default:
                continue
            }
            
            // Decrypt the value
            guard let data = Data(base64Encoded: encryptedValue) else {
                continue
            }
            
            let decryptedData = try encryptionService.decrypt(data)
            guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                continue
            }
            
            // Store decrypted value
            switch key {
            case "accountNumber":
                self.accountNumber = decryptedString
            case "panNumber":
                self.panNumber = decryptedString
            case "name":
                self.name = decryptedString
            default:
                break
            }
        }
    }
} 