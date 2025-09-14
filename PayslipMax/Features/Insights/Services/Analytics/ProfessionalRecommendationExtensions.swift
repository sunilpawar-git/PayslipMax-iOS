import Foundation

// MARK: - ProfessionalRecommendation Extensions

extension ProfessionalRecommendation.Priority {
    var rawValue: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
