import Foundation
import SwiftData

/// Represents a deduction item within a payslip.
///
/// This model stores details about a specific deduction, such as its name, amount, and category.
/// It is designed to be persisted using SwiftData.
@Model
final class Deduction {
    /// The unique identifier for the deduction.
    @Attribute(.unique) var id: UUID
    /// The descriptive name of the deduction (e.g., "Income Tax").
    var name: String
    /// The monetary value of the deduction.
    var amount: Double
    /// The category or type of the deduction (e.g., "Statutory", "Voluntary").
    var category: String
    
    /// Initializes a new deduction item.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - name: The name of the deduction.
    ///   - amount: The monetary amount of the deduction.
    ///   - category: The category of the deduction.
    init(id: UUID = UUID(), name: String, amount: Double, category: String) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
    }
} 