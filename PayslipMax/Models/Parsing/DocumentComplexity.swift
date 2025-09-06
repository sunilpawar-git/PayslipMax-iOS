import Foundation

/// Document complexity analysis results
struct DocumentComplexity: Codable {
    /// Total number of positional elements
    let totalElements: Int
    /// Average elements per page
    let averageElementsPerPage: Double
    /// Number of table structures detected
    let tablesDetected: Int
    /// Total number of pages
    let pageCount: Int
    
    /// Complexity classification
    var classification: ComplexityLevel {
        if averageElementsPerPage < 20 && tablesDetected == 0 {
            return .simple
        } else if averageElementsPerPage < 50 && tablesDetected <= 2 {
            return .moderate
        } else {
            return .complex
        }
    }
}

/// Document complexity levels
enum ComplexityLevel: String, Codable {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
}
