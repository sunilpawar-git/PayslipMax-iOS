//
//  AppTab.swift
//  PayslipMax
//
//  Type-safe enum for main app tabs
//  Replaces magic number indices throughout the codebase
//

import Foundation

/// Main app tab definitions
enum AppTab: Int, CaseIterable, Identifiable {
    case home = 0
    case payslips = 1
    case insights = 2
    case settings = 3

    var id: Int { rawValue }

    /// Display title for the tab
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .payslips:
            return "Payslips"
        case .insights:
            return "Insights"
        case .settings:
            return "Settings"
        }
    }

    /// SF Symbol icon name for the tab
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .payslips:
            return "doc.text.fill"
        case .insights:
            return "chart.bar.fill"
        case .settings:
            return "gearshape.fill"
        }
    }

    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        switch self {
        case .home:
            return "Home tab"
        case .payslips:
            return "Payslips tab"
        case .insights:
            return "Insights tab"
        case .settings:
            return "Settings tab"
        }
    }
}

