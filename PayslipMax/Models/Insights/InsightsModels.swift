import SwiftUI
import Charts

// MARK: - Chart Data Models

/// Represents a data point in a chart.
struct ChartData: Identifiable {
    /// Unique identifier for the data point.
    let id = UUID()
    /// The label associated with the data point (e.g., month name, category).
    let label: String
    /// The numerical value of the data point.
    let value: Double
    /// The category this data point belongs to (used for grouping or color-coding).
    let category: String
}

/// Represents an item in a chart legend.
struct LegendItem {
    /// The text label for the legend item.
    let label: String
    /// The color associated with the legend item.
    let color: Color
}

// MARK: - Insight Detail Models

/// Represents a detailed breakdown item for an insight
struct InsightDetailItem: Identifiable {
    let id = UUID()
    let period: String // e.g., "April 2025", "March 2024"
    let value: Double
    let additionalInfo: String? // Optional additional information
}

/// Represents the type of insight detail being shown
enum InsightDetailType {
    case monthlyIncomes
    case monthlyTaxes
    case monthlyDeductions
    case monthlyDSOP
    case incomeComponents
    case monthlyNetIncome
    case incomeStabilityData
    
    var title: String {
        switch self {
        case .monthlyIncomes: return "Monthly Income Breakdown"
        case .monthlyTaxes: return "Monthly Tax Details"
        case .monthlyDeductions: return "Monthly Deductions"
        case .monthlyDSOP: return "DSOP Contributions"
        case .incomeComponents: return "Income Components Breakdown"
        case .monthlyNetIncome: return "Monthly Net Remittance"
        case .incomeStabilityData: return "Income Stability Data"
        }
    }
    
    var subtitle: String {
        switch self {
        case .monthlyIncomes: return "Your income across different months"
        case .monthlyTaxes: return "Tax paid each month"
        case .monthlyDeductions: return "Deductions breakdown by month"
        case .monthlyDSOP: return "DSOP contributions over time"
        case .incomeComponents: return "Breakdown of income sources"
        case .monthlyNetIncome: return "Net remittance after deductions"
        case .incomeStabilityData: return "Income variation analysis"
        }
    }
    
    var icon: String {
        switch self {
        case .monthlyIncomes: return "arrow.up.circle.fill"
        case .monthlyTaxes: return "percent"
        case .monthlyDeductions: return "minus.circle.fill"
        case .monthlyDSOP: return "building.columns.fill"
        case .incomeComponents: return "star.circle.fill"
        case .monthlyNetIncome: return "dollarsign.circle.fill"
        case .incomeStabilityData: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Insight Models

/// Represents an insight item with clickable details
struct InsightItem {
    /// The title or main text of the insight.
    let title: String
    /// A more detailed description or explanation of the insight.
    let description: String
    /// The name of the SF Symbol icon to display with the insight.
    let iconName: String
    /// The color associated with the insight for visual distinction.
    let color: Color
    /// The detailed breakdown data that supports this insight
    let detailItems: [InsightDetailItem]
    /// The type of detail being shown
    let detailType: InsightDetailType
    
    /// Whether this insight has detailed data to show
    var hasDetails: Bool {
        return !detailItems.isEmpty
    }
} 