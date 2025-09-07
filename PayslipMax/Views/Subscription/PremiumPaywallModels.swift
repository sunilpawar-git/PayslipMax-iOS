//
//  PremiumPaywallModels.swift
//  PayslipMax
//
//  Created by Sunil Garg on 2024
//  Refactored from PremiumPaywallView.swift to follow SOLID patterns
//  Contains models and data constants for premium paywall feature
//

import SwiftUI

/// Model representing a feature highlight in the premium paywall carousel
struct FeatureHighlight {
    let icon: String
    let title: String
    let description: String
    let benefit: String
    let gradient: [Color]

    static let cloudBackup = FeatureHighlight(
        icon: "icloud.and.arrow.up",
        title: "Cloud Backup",
        description: "Backup your payslip data to your preferred cloud service (Google Drive, iCloud, Dropbox, etc.)",
        benefit: "Never lose your financial data",
        gradient: [Color.blue, Color.cyan]
    )

    static let crossDeviceTransfer = FeatureHighlight(
        icon: "arrow.clockwise.icloud",
        title: "Cross-Device Transfer",
        description: "Easily transfer your data when you change phones - seamless device switching",
        benefit: "Take your data anywhere",
        gradient: [Color.green, Color.mint]
    )

    static let dataPortability = FeatureHighlight(
        icon: "shield.checkered",
        title: "Data Portability",
        description: "Your data remains yours - export and import across devices with complete control",
        benefit: "Complete data ownership",
        gradient: [Color.purple, Color.pink]
    )
}

/// Extension providing static feature highlights collection
extension FeatureHighlight {
    static let allFeatures: [FeatureHighlight] = [
        .cloudBackup,
        .crossDeviceTransfer,
        .dataPortability
    ]
}

/// Protocol for paywall view models to ensure consistent behavior
protocol PremiumPaywallViewModelProtocol {
    var featureHighlights: [FeatureHighlight] { get }
    var currentFeatureIndex: Int { get set }
    var selectedTier: SubscriptionTier? { get set }
    var showingPurchaseLoading: Bool { get set }

    func startFeatureCarousel()
    func purchaseSubscription(_ tier: SubscriptionTier) async
}
