import Foundation

/// UI extensions for ExtractionQuality enum
extension ExtractionQuality {
    /// Color representation for UI display
    var colorCode: String {
        switch self {
        case .excellent:
            return "#22C55E" // Green
        case .good:
            return "#84CC16" // Light Green
        case .fair:
            return "#EAB308" // Yellow
        case .poor:
            return "#F97316" // Orange
        case .failed:
            return "#EF4444" // Red
        }
    }
}
