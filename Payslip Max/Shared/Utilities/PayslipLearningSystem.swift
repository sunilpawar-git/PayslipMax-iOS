import Foundation

/// A class for learning and categorizing unknown payslip components based on user feedback.
class PayslipLearningSystem {
    /// Shared instance for singleton access
    static let shared = PayslipLearningSystem()
    
    /// UserDefaults key for storing user categorized components
    private let userCategoriesKey = "userCategorizedComponents"
    
    /// Dictionary of user-categorized components [code: category]
    private var userCategories: [String: String] = [:]
    
    /// Initialize the learning system and load saved categories
    init() {
        loadUserCategories()
    }
    
    /// Load user categories from UserDefaults
    private func loadUserCategories() {
        if let data = UserDefaults.standard.data(forKey: userCategoriesKey),
           let categories = try? JSONDecoder().decode([String: String].self, from: data) {
            userCategories = categories
        }
    }
    
    /// Save user categories to UserDefaults
    private func saveUserCategories() {
        if let data = try? JSONEncoder().encode(userCategories) {
            UserDefaults.standard.set(data, forKey: userCategoriesKey)
        }
    }
    
    /// Attempt to categorize an unknown component based on patterns and previous learning
    ///
    /// - Parameters:
    ///   - code: The component code to categorize
    ///   - amount: The amount associated with the component
    ///   - inEarningsSection: Whether the component was found in the earnings section
    /// - Returns: The suggested category ("earnings" or "deductions")
    func categorizeComponent(code: String, amount: Double, inEarningsSection: Bool) -> String {
        // First check if user has categorized this before
        if let category = userCategories[code] {
            return category
        }
        
        // Check for common prefixes/patterns
        if code.hasPrefix("ARR-") {
            // This is likely an arrears component
            return "earnings"
        }
        
        if code.hasPrefix("RH") && code.count == 3 {
            // This is likely a Risk & Hardship allowance
            return "earnings"
        }
        
        // Check for keywords in the code
        let earningsKeywords = ["PAY", "ALLOW", "BONUS", "SALARY", "WAGE", "TA", "DA"]
        let deductionsKeywords = ["TAX", "FUND", "FEE", "RECOVERY", "LOAN", "ADVANCE", "INS"]
        
        for keyword in earningsKeywords {
            if code.contains(keyword) {
                return "earnings"
            }
        }
        
        for keyword in deductionsKeywords {
            if code.contains(keyword) {
                return "deductions"
            }
        }
        
        // Use the section it appears in as a fallback
        return inEarningsSection ? "earnings" : "deductions"
    }
    
    /// Learn from user categorization
    ///
    /// - Parameters:
    ///   - code: The component code
    ///   - category: The category assigned by the user
    func learnUserCategorization(code: String, category: String) {
        userCategories[code] = category
        saveUserCategories()
    }
    
    /// Get all known user categories
    ///
    /// - Returns: Dictionary of [code: category]
    func getKnownUserCategories() -> [String: String] {
        return userCategories
    }
} 