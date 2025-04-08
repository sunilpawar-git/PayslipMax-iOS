import Foundation

/// Represents an item in a financial breakdown (earnings or deductions)
struct BreakdownItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
} 