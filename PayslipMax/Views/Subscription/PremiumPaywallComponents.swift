//
//  PremiumPaywallComponents.swift
//  PayslipMax
//
//  Created by Sunil Garg on 2024
//  Refactored from PremiumPaywallView.swift to follow SOLID/MVVM patterns
//  All UI components extracted to maintain single responsibility per file
//

import SwiftUI

/// Component for displaying individual feature highlights in the carousel
struct FeatureCard: View {
    let feature: FeatureHighlight

    var body: some View {
        VStack(spacing: 20) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: feature.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: feature.icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                Text(feature.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)

                Text(feature.benefit)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(feature.gradient.first ?? .blue)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }
}

/// Component for displaying subscription pricing tiers
struct PricingCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let subscriptionManager: SubscriptionManager
    let isFullWidth: Bool
    let onSelect: () -> Void

    init(tier: SubscriptionTier, isSelected: Bool, subscriptionManager: SubscriptionManager, isFullWidth: Bool = false, onSelect: @escaping () -> Void) {
        self.tier = tier
        self.isSelected = isSelected
        self.subscriptionManager = subscriptionManager
        self.isFullWidth = isFullWidth
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 16) {
                // Header with badge
                pricingHeader

                // Pricing information
                pricingDetails

                // Features list
                featuresList
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? FintechColors.primaryBlue : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var pricingHeader: some View {
        VStack(spacing: 8) {
            if tier.id.contains("yearly") {
                HStack {
                    Text("MOST POPULAR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(8)

                    Spacer()
                }
            } else if tier.id.contains("pro") {
                HStack {
                    Text("PROFESSIONAL")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.purple)
                        .cornerRadius(8)

                    Spacer()
                }
            }

            HStack {
                Text(tier.name.replacingOccurrences(of: " Monthly", with: "").replacingOccurrences(of: " Yearly", with: ""))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)

                Spacer()
            }
        }
    }

    private var pricingDetails: some View {
        VStack(spacing: 4) {
            Text(subscriptionManager.formattedPrice(for: tier))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(FintechColors.primaryBlue)

            if tier.id.contains("yearly") {
                Text(subscriptionManager.monthlyEquivalent(for: tier))
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)

                if let monthlyTier = subscriptionManager.availableSubscriptions.first(where: { $0.id.contains("monthly") && !$0.id.contains("pro") }) {
                    Text(subscriptionManager.savings(for: tier, comparedTo: monthlyTier))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            } else if tier.id.contains("monthly") {
                Text("per month")
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
            }
        }
    }

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(tier.features.prefix(isFullWidth ? 6 : 4)), id: \.id) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)

                    Text(feature.name)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)

                    Spacer()
                }
            }

            if tier.features.count > (isFullWidth ? 6 : 4) {
                Text("+ \(tier.features.count - (isFullWidth ? 6 : 4)) more features")
                    .font(.caption2)
                    .foregroundColor(FintechColors.primaryBlue)
            }
        }
    }
}

/// Component for displaying benefit rows in the benefits section
struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
