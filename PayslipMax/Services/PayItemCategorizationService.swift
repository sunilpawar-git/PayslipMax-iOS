import Foundation

/// Service for categorizing pay items
final class PayItemCategorizationService: PayItemCategorizationServiceProtocol {

    // MARK: - PayItemCategorizationServiceProtocol

    /// Categorizes pay items by type
    func categorizePayItems(_ items: [String: Double]) async -> [String: [PayItem]] {
        var categorized: [String: [PayItem]] = [:]

        for (name, amount) in items {
            let category = await determineCategory(for: name)
            var categoryItems = categorized[category] ?? []
            categoryItems.append(PayItem(name: name, amount: amount))
            categorized[category] = categoryItems
        }

        // Sort items within each category by amount (descending)
        for (category, items) in categorized {
            categorized[category] = items.sorted { $0.amount > $1.amount }
        }

        return categorized
    }

    /// Determines the category for a pay item based on its name
    func determineCategory(for itemName: String) async -> String {
        let normalizedName = itemName.lowercased()

        // Standard earnings components
        if itemName == "BPAY" || normalizedName.contains("basic") || normalizedName == "pay" || normalizedName == "salary" {
            return "Basic Pay"
        }

        if itemName == "DA" || normalizedName.contains("dearness") {
            return "Dearness Allowance"
        }

        // Commented out HRA categorization as it's now in blacklisted terms
        // if itemName == "HRA" || normalizedName.contains("house rent") || normalizedName.contains("housing") {
        //     return "Housing Allowance"
        // }

        if itemName == "MSP" || normalizedName.contains("military service") {
            return "Military Service Pay"
        }

        // Standard deductions components
        if itemName == "DSOP" || normalizedName.contains("provident") || normalizedName.contains("fund") {
            return "Provident Fund"
        }

        if itemName == "AGIF" || normalizedName.contains("insurance") {
            return "Insurance"
        }

        if itemName == "ITAX" || normalizedName.contains("tax") || normalizedName.contains("tds") {
            return "Tax Deductions"
        }

        // Allowances
        if normalizedName.contains("allowance") ||
           normalizedName.contains("ta") ||
           itemName == "TPTA" ||
           itemName == "TPTADA" {
            return "Allowances"
        }

        // Special Pay
        if normalizedName.contains("special") ||
           normalizedName.contains("bonus") ||
           normalizedName.contains("incentive") {
            return "Special Pay"
        }

        // Retirement Contributions
        if normalizedName.contains("pension") ||
           normalizedName.contains("pf") {
            return "Retirement Contributions"
        }

        // Loans and Advances
        if normalizedName.contains("loan") ||
           normalizedName.contains("advance") ||
           normalizedName.contains("recovery") ||
           itemName == "FUR" ||
           itemName == "LF" {
            return "Loans & Advances"
        }

        // Accommodation
        if normalizedName.contains("accommodation") ||
           normalizedName.contains("quarters") ||
           normalizedName.contains("rent") {
            return "Accommodation"
        }

        // Utilities
        if normalizedName.contains("electricity") ||
           normalizedName.contains("water") ||
           normalizedName.contains("utility") ||
           normalizedName.contains("gas") ||
           itemName == "WATER" {
            return "Utilities"
        }

        // Mess and Food
        if normalizedName.contains("mess") ||
           normalizedName.contains("food") ||
           normalizedName.contains("ration") {
            return "Mess & Food"
        }

        // Default category
        return "Other"
    }
}
