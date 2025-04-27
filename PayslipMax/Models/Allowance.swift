import Foundation
import SwiftData

/// Represents an allowance item within a payslip.
///
/// This model stores details about a specific allowance, such as its name, amount, and category.
/// It is designed to be persisted using SwiftData.
@Model
final class Allowance {
    /// The unique identifier for the allowance.
    @Attribute(.unique) var id: UUID
    /// The descriptive name of the allowance (e.g., "House Rent Allowance").
    var name: String
    /// The monetary value of the allowance.
    var amount: Double
    /// The category or type of the allowance (e.g., "Standard", "Taxable").
    var category: String
    
    /// Initializes a new allowance item.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - name: The name of the allowance.
    ///   - amount: The monetary amount of the allowance.
    ///   - category: The category of the allowance.
    init(id: UUID = UUID(), name: String, amount: Double, category: String) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
    }
} 