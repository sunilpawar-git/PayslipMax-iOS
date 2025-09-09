import Foundation

/// Represents a pay item with a name and amount
struct PayItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
}
