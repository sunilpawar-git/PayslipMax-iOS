import Foundation
import SwiftData

/// A model representing financial data from a payslip
@Model
class FinancialData: Codable {
    // MARK: - Properties
    
    /// Unique identifier
    var id: UUID
    
    /// Total credits/income amount
    var credits: Double
    
    /// Total debits/deductions amount
    var debits: Double
    
    /// DSPOF (Defined Specific Purpose Outflow Funds) amount
    var dspof: Double
    
    /// Tax amount
    var tax: Double
    
    // MARK: - Initialization
    
    /// Initializes a new FinancialData instance
    /// - Parameters:
    ///   - id: Unique identifier (defaults to a new UUID)
    ///   - credits: Total credits/income amount
    ///   - debits: Total debits/deductions amount
    ///   - dspof: DSPOF amount
    ///   - tax: Tax amount
    init(id: UUID = UUID(), credits: Double, debits: Double, dspof: Double, tax: Double) {
        self.id = id
        self.credits = credits
        self.debits = debits
        self.dspof = dspof
        self.tax = tax
    }
    
    // MARK: - Codable Implementation
    
    /// Keys used for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case id, credits, debits, dspof, tax
    }
    
    /// Initializes a FinancialData from a decoder
    /// - Parameter decoder: The decoder to read data from
    /// - Throws: An error if decoding fails
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        credits = try container.decode(Double.self, forKey: .credits)
        debits = try container.decode(Double.self, forKey: .debits)
        dspof = try container.decode(Double.self, forKey: .dspof)
        tax = try container.decode(Double.self, forKey: .tax)
    }
    
    /// Encodes this FinancialData to an encoder
    /// - Parameter encoder: The encoder to write data to
    /// - Throws: An error if encoding fails
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(credits, forKey: .credits)
        try container.encode(debits, forKey: .debits)
        try container.encode(dspof, forKey: .dspof)
        try container.encode(tax, forKey: .tax)
    }
}

// MARK: - Calculations
extension FinancialData {
    /// Calculates the net amount (credits minus all deductions)
    var netAmount: Double {
        return credits - (debits + dspof + tax)
    }
    
    /// Calculates the total deductions (debits + dspof + tax)
    var totalDeductions: Double {
        return debits + dspof + tax
    }
    
    /// Calculates the tax percentage relative to credits
    var taxPercentage: Double {
        guard credits > 0 else { return 0 }
        return (tax / credits) * 100
    }
} 