import Foundation
import CoreGraphics

// MARK: - Section Classification Types

/// Result of section classification for earnings vs deductions
struct SectionClassificationResult {
    let earningsElements: [PositionalElement]
    let deductionsElements: [PositionalElement]
    let otherElements: [PositionalElement]
    let confidence: Double
}

/// Types of financial elements for classification
enum FinancialElementType {
    case earnings
    case deductions
    case unknown
}

/// Represents a section of elements with type classification
struct ElementSection {
    let elements: [PositionalElement]
    let sectionType: SectionType
    let confidence: Double
    let metadata: [String: String]
}

/// Types of document sections
enum SectionType: String, Codable {
    case earnings = "earnings"
    case deductions = "deductions"
    case header = "header"
    case personalInfo = "personal_info"
    case table = "table"
    case unknown = "unknown"
    case footer = "footer"
    
    var description: String {
        switch self {
        case .earnings:
            return "Earnings"
        case .deductions:
            return "Deductions"
        case .header:
            return "Header"
        case .personalInfo:
            return "Personal Information"
        case .table:
            return "Table"
        case .unknown:
            return "Unknown"
        case .footer:
            return "Footer"
        }
    }
}
