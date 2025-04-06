import Foundation
// Remove the unnecessary import that's causing the warning
// import struct Payslip_Max.ExtractorPattern

/// Category for organizing patterns by their purpose
enum PatternCategory: String, Codable, CaseIterable, Identifiable {
    case personal
    case earnings
    case deductions
    case banking
    case taxInfo
    case custom
    
    var id: String { self.rawValue }
    
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
    let id: UUID
    var name: String
    var key: String  // The field name where extracted value will be stored
    var category: PatternCategory
    var patterns: [ExtractorPattern]
    
    // Metadata
    var isCore: Bool  // If true, this is a system pattern that can't be deleted
    var dateCreated: Date
    var lastModified: Date
    var userCreated: Bool
    var successRate: Double = 0.0  // 0.0-1.0 indicating success rate
    
    // Optional sample data for testing
    var sampleInput: String?
    var expectedOutput: String?
    
    /// Creates a new user-defined pattern
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
    
    /// Creates a new system-defined pattern
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