import Foundation

/// Protocol for categorizing pay items
protocol PayItemCategorizationServiceProtocol {
    /// Categorizes pay items by type
    func categorizePayItems(_ items: [String: Double]) async -> [String: [PayItem]]

    /// Determines the category for a pay item based on its name
    func determineCategory(for itemName: String) async -> String
}
