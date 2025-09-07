//
//  PremiumPaywallSections.swift
//  PayslipMax
//
//  Created by Sunil Garg on 2024
//  Refactored from PremiumPaywallView.swift to follow SOLID patterns
//  Contains view sections to keep main view under 300 lines
//

import SwiftUI

/// Helper class for managing premium paywall view sections
final class PremiumPaywallSections {
    private let subscriptionManager: SubscriptionManager

    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }

    // MARK: - Header Section

    func headerSection() -> some View {
        VStack(spacing: 20) {
            // Crown icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.3), radius: 10)
            }

            VStack(spacing: 12) {
                Text("PayslipMax Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Cloud backup for seamless device switching")
                    .font(.title3)
                    .foregroundColor(FintechColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Feature Carousel Section

    func featureCarouselSection(currentIndex: Binding<Int>) -> some View {
        VStack(spacing: 20) {
            Text("What You'll Get")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)

            TabView(selection: currentIndex) {
                ForEach(Array(FeatureHighlight.allFeatures.enumerated()), id: \.offset) { index, feature in
                    FeatureCard(feature: feature)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(height: 300)
            .animation(.easeInOut, value: currentIndex.wrappedValue)
        }
    }

    // MARK: - Pricing Section

    func pricingSection(
        selectedTier: SubscriptionTier?,
        onTierSelect: @escaping (SubscriptionTier) -> Void
    ) -> some View {
        VStack(spacing: 20) {
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)

            // Single Pro tier (full width)
            if let proTier = subscriptionManager.availableSubscriptions.first {
                PricingCard(
                    tier: proTier,
                    isSelected: selectedTier?.id == proTier.id,
                    subscriptionManager: subscriptionManager,
                    isFullWidth: true
                ) {
                    onTierSelect(proTier)
                }
            }
        }
    }

    // MARK: - Social Proof Section

    func socialProofSection() -> some View {
        VStack(spacing: 16) {
            Text("Trusted by \(PremiumPaywallHelper.socialProofStats.userCount) Users")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)

            HStack(spacing: 20) {
                // Rating
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.title3)
                        }
                    }

                    Text(PremiumPaywallHelper.socialProofStats.rating)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }

                Divider()
                    .frame(height: 40)

                // Stats
                VStack(spacing: 8) {
                    Text(PremiumPaywallHelper.socialProofStats.savings)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(FintechColors.primaryBlue)

                    Text("Total Savings")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }

                Divider()
                    .frame(height: 40)

                // Users
                VStack(spacing: 8) {
                    Text(PremiumPaywallHelper.socialProofStats.recommendation)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    Text("Recommend")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
        }
        .fintechCardStyle()
    }

    // MARK: - Benefits Section

    func benefitsSection() -> some View {
        VStack(spacing: 16) {
            Text("Why Pro Users Love PayslipMax")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)

            VStack(spacing: 12) {
                ForEach(PremiumPaywallHelper.benefits, id: \.title) { benefit in
                    BenefitRow(
                        icon: benefit.icon,
                        title: benefit.title,
                        description: benefit.description,
                        color: benefit.color
                    )
                }
            }
        }
        .fintechCardStyle()
    }

    // MARK: - CTA Section

    func ctaSection(
        selectedTier: SubscriptionTier?,
        showingLoading: Binding<Bool>,
        onPurchase: @escaping (SubscriptionTier) async -> Void,
        onRestore: @escaping () async -> Void
    ) -> some View {
        VStack(spacing: 20) {
            if let selectedTier = selectedTier {
                Button(action: {
                    Task {
                        await onPurchase(selectedTier)
                    }
                }) {
                    HStack {
                        if showingLoading.wrappedValue {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Start Premium - \(subscriptionManager.formattedPrice(for: selectedTier))")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [FintechColors.primaryBlue, FintechColors.primaryBlue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(showingLoading.wrappedValue)
            }

            Button("Restore Purchases") {
                Task {
                    await onRestore()
                }
            }
            .font(.subheadline)
            .foregroundColor(FintechColors.primaryBlue)

            legalSection()
        }
    }

    // MARK: - Legal Section

    private func legalSection() -> some View {
        VStack(spacing: 8) {
            Text("• Cancel anytime • No hidden fees • Secure payment")
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
                .multilineTextAlignment(.center)

            HStack {
                Button("Terms of Service") {
                    // Open terms
                }
                .font(.caption)
                .foregroundColor(FintechColors.primaryBlue)

                Text("•")
                    .foregroundColor(FintechColors.textSecondary)

                Button("Privacy Policy") {
                    // Open privacy
                }
                .font(.caption)
                .foregroundColor(FintechColors.primaryBlue)
            }
        }
    }
}
