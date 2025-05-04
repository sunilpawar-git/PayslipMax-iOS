import Foundation
// Remove the unnecessary import that's causing the warning
// import struct PayslipMax.ExtractorPattern

/// Category for organizing patterns by their purpose
enum PatternCategory: String, Codable, CaseIterable, Identifiable {
    /// Patterns related to the payslip owner's personal information.
    case personal
    /// Patterns related to income or earnings.
    case earnings
    /// Patterns related to deductions or expenses.
    case deductions
    /// Patterns related to bank account or payment details.
    case banking
    /// Patterns related to tax identification numbers or amounts.
    case taxInfo
    /// Patterns defined by the user.
    case custom
    
    /// Provides the raw string value as the identifier.
    var id: String { self.rawValue }
    
    /// Provides a user-friendly display name for the category.
    var displayName: String {
        switch self {
        case .personal: return "Personal Details"
        case .earnings: return "Earnings"
        case .deductions: return "Deductions"
        case .banking: return "Banking Details"
        case .taxInfo: return "Tax Information"
        case .custom: return "Custom Fields"
        }
    }
}

/// Defines how a specific piece of information should be extracted from a document
struct PatternDefinition: Identifiable, Codable, Equatable {
    // Core properties
    /// Unique identifier for the pattern definition.
    let id: UUID
    /// User-friendly name for the pattern (e.g., "Employee Name").
    var name: String
    /// The dictionary key used to store the extracted value (e.g., "employeeName").
    var key: String  // The field name where extracted value will be stored
    /// The category this pattern belongs to.
    var category: PatternCategory
    /// An array of `ExtractorPattern` objects defining the actual extraction logic (e.g., regex).
    var patterns: [ExtractorPattern]
    
    // Metadata
    /// Flag indicating if this is a system-defined pattern (cannot be deleted by user).
    var isCore: Bool  // If true, this is a system pattern that can't be deleted
    /// The date when this pattern definition was created.
    var dateCreated: Date
    /// The date when this pattern definition was last modified.
    var lastModified: Date
    /// Flag indicating if this pattern was created by the user.
    var userCreated: Bool
    /// A score (0.0 to 1.0) indicating the historical success rate of this pattern.
    var successRate: Double = 0.0  // 0.0-1.0 indicating success rate
    
    // Optional sample data for testing
    /// Optional sample text input to test the pattern against.
    var sampleInput: String?
    /// Optional expected output when testing against `sampleInput`.
    var expectedOutput: String?
    
    /// Creates a new user-defined pattern definition.
    /// - Parameters:
    ///   - name: The display name of the pattern.
    ///   - key: The key for storing the extracted value.
    ///   - category: The category of the pattern.
    ///   - patterns: The array of `ExtractorPattern` logic.
    /// - Returns: A new `PatternDefinition` instance configured as a user pattern.
    static func createUserPattern(
        name: String,
        key: String,
        category: PatternCategory,
        patterns: [ExtractorPattern]
    ) -> PatternDefinition {
        let now = Date()
        return PatternDefinition(
            id: UUID(),
            name: name,
            key: key,
            category: category,
            patterns: patterns,
            isCore: false,
            dateCreated: now,
            lastModified: now,
            userCreated: true
        )
    }
    
    /// Creates a new system-defined (core) pattern definition.
    /// - Parameters:
    ///   - name: The display name of the pattern.
    ///   - key: The key for storing the extracted value.
    ///   - category: The category of the pattern.
    ///   - patterns: The array of `ExtractorPattern` logic.
    /// - Returns: A new `PatternDefinition` instance configured as a core pattern.
    static func createCorePattern(
        name: String,
        key: String,
        category: PatternCategory,
        patterns: [ExtractorPattern]
    ) -> PatternDefinition {
        let now = Date()
        return PatternDefinition(
            id: UUID(),
            name: name,
            key: key,
            category: category,
            patterns: patterns,
            isCore: true,
            dateCreated: now,
            lastModified: now,
            userCreated: false
        )
    }
} 