//
//  FinancialOverviewTypes.swift
//  PayslipMax
//
//  Created by GlobalDataTech on 2024
//  Architecture: MVVM-SOLID compliant
//  Lines: ~45 (well under 300-line limit)

import Foundation

/// Represents different time ranges for financial analysis
/// Architecture: Value type following SOLID principles
enum FinancialTimeRange: CaseIterable {
    case last3Months, last6Months, lastYear, all

    /// Short display name for UI components
    var displayName: String {
        switch self {
        case .last3Months: return "3M"
        case .last6Months: return "6M"
        case .lastYear: return "1Y"
        case .all: return "All"
        }
    }

    /// Full descriptive name for detailed displays
    var fullDisplayName: String {
        switch self {
        case .last3Months: return "Last 3 Months"
        case .last6Months: return "Last 6 Months"
        case .lastYear: return "Last Year"
        case .all: return "All Time"
        }
    }
}

/// Represents trend direction for financial data visualization
/// Architecture: Value type with clear single responsibility
enum TrendDirection {
    case up, down, neutral
}
