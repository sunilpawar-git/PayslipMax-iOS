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

// MARK: - Insight Models

/// Represents an insight item.
struct InsightItem {
    /// The title or main text of the insight.
    let title: String
    /// A more detailed description or explanation of the insight.
    let description: String
    /// The name of the SF Symbol icon to display with the insight.
    let iconName: String
    /// The color associated with the insight for visual distinction.
    let color: Color
} 