//
//  PremiumPaywallHelpers.swift
//  PayslipMax
//
//  Created by Sunil Garg on 2024
//  Refactored from PremiumPaywallView.swift to follow SOLID patterns
//  Contains helper functions and async operations for premium paywall
//

import SwiftUI

/// Helper class for managing premium paywall functionality
final class PremiumPaywallHelper {
    private weak var subscriptionManager: SubscriptionManager?

    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }

    /// Starts the automatic feature carousel with 3-second intervals
    func startFeatureCarousel(
        featureCount: Int,
        currentIndex: Binding<Int>
    ) -> Timer {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex.wrappedValue = (currentIndex.wrappedValue + 1) % featureCount
            }
        }
    }

    /// Handles subscription purchase with proper error handling
    func purchaseSubscription(
        _ tier: SubscriptionTier,
        showingLoading: Binding<Bool>,
        dismissAction: @escaping () -> Void
    ) async {
        guard let subscriptionManager = subscriptionManager else { return }

        await MainActor.run {
            showingLoading.wrappedValue = true
        }

        do {
            try await subscriptionManager.subscribeTo(tier)
            await MainActor.run {
                dismissAction()
            }
        } catch {
            // Handle error - could be expanded to show user alerts
            await MainActor.run {
                print("Purchase failed: \(error.localizedDescription)")
                // TODO: Show error alert to user
            }
        }

        await MainActor.run {
            showingLoading.wrappedValue = false
        }
    }

    /// Handles purchase restoration
    func restorePurchases() async {
        guard let subscriptionManager = subscriptionManager else { return }

        do {
            try await subscriptionManager.restorePurchases()
        } catch {
            await MainActor.run {
                print("Restore failed: \(error.localizedDescription)")
                // TODO: Show error alert to user
            }
        }
    }
}

/// Extension providing convenience methods for social proof data
extension PremiumPaywallHelper {
    static let socialProofStats = SocialProofStats(
        userCount: "10,000+",
        rating: "4.9/5",
        savings: "₹2.5Cr+",
        recommendation: "94%"
    )
}

/// Model for social proof statistics
struct SocialProofStats {
    let userCount: String
    let rating: String
    let savings: String
    let recommendation: String
}

/// Extension for benefit data
extension PremiumPaywallHelper {
    static let benefits: [BenefitItem] = [
        BenefitItem(
            icon: "checkmark.circle.fill",
            title: "Peace of Mind",
            description: "Never worry about losing your payslip data when changing phones",
            color: .green
        ),
        BenefitItem(
            icon: "arrow.up.right.circle.fill",
            title: "Seamless Switching",
            description: "Upgrade phones without the hassle of data migration",
            color: FintechColors.primaryBlue
        ),
        BenefitItem(
            icon: "shield.checkered",
            title: "Data Security",
            description: "Your data is safely backed up to your preferred cloud service",
            color: .orange
        ),
        BenefitItem(
            icon: "clock.fill",
            title: "Save Time",
            description: "Instant data restoration - no manual re-entry required",
            color: .purple
        )
    ]
}

/// Model for benefit items
struct BenefitItem {
    let icon: String
    let title: String
    let description: String
    let color: Color
}
