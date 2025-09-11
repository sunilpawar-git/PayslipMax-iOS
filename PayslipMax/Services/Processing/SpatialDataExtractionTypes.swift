import Foundation

// MARK: - Supporting Types

/// Section-aware financial data result
struct SectionAwareFinancialData {
    let earnings: [String: Double]
    let deductions: [String: Double]
    let sectionConfidence: Double
    let metadata: [String: String]
}

/// Error types for spatial extraction
enum SpatialExtractionError: Error, LocalizedError {
    case noElementsFound
    case insufficientElements(count: Int)
    case spatialAnalysisFailure(String)
    case sectionClassificationFailure(String)

    var errorDescription: String? {
        switch self {
        case .noElementsFound:
            return "No positional elements found for extraction"
        case .insufficientElements(let count):
            return "Insufficient elements for spatial extraction: \(count)"
        case .spatialAnalysisFailure(let message):
            return "Spatial analysis failed: \(message)"
        case .sectionClassificationFailure(let message):
            return "Section classification failed: \(message)"
        }
    }
}
