import SwiftUI
import Charts

// MARK: - Chart Data Models

/// Represents a data point in a chart.
struct ChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let category: String
}

/// Represents an item in a chart legend.
struct LegendItem {
    let label: String
    let color: Color
}

// MARK: - Insight Models

/// Represents an insight item.
struct InsightItem {
    let title: String
    let description: String
    let iconName: String
    let color: Color
} 