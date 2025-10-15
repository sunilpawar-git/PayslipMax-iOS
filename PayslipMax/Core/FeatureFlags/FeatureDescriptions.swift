import Foundation

/// Provides descriptions for feature flags in the UI
struct FeatureDescriptions {

    /// Gets a description for the given feature.
    /// - Parameter feature: The feature to get a description for.
    /// - Returns: A description of the feature.
    static func description(for feature: Feature) -> String {
        switch feature {
        case .optimizedMilitaryParsing:
            return "Reduces memory usage at the cost of speed"
        case .parallelizedTextExtraction:
            return "Uses multiple threads for faster PDF text extraction"
        case .enhancedPatternMatching:
            return "Improved pattern recognition for payslip data"
        case .simplifiedPayslipParsing:
            return "Focus on essential fields (BPAY, DA, MSP, DSOP, AGIF, Tax) for faster parsing and better UX"
        case .enhancedDashboard:
            return "New dashboard with graphical summaries"
        case .militaryInsights:
            return "Military-specific insights and analysis"
        case .pdfAnnotation:
            return "Markup and annotation tools for PDF documents"
        case .enhancedAnalytics:
            return "Extended application analytics"
        case .dataAggregation:
            return "Anonymized data aggregation for trends"
        case .aiCategorization:
            return "AI-powered payslip categorization"
        case .smartCapture:
            return "Automatic document capture with quality detection"
        case .cloudBackup:
            return "Secure cloud backup functionality"
        }
    }
}
