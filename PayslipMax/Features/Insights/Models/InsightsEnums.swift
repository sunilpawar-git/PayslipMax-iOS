import Foundation
import SwiftUI

// MARK: - Insights Enums

/// Represents a time range for filtering data.
enum TimeRange: String, CaseIterable {
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
    case all = "All Time"
    
    var displayName: String {
        return self.rawValue
    }
}

/// Represents a type of insight to display.
enum InsightType: String, CaseIterable, Codable {
    case income = "Earnings"
    case deductions = "Deductions"
    case net = "Net Remittance"
    
    var displayName: String {
        return self.rawValue
    }
}

/// Represents a type of chart to display.
enum ChartType: String, CaseIterable {
    case bar = "Bar"
    case line = "Line"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .bar: return "chart.bar"
        case .line: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Supporting Trend Model

/// Represents a trend item for display.
struct TrendItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let value: String?
} 