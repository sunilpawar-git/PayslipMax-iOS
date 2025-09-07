//
//  PremiumPaywallView.swift
//  PayslipMax
//
//  Created by Sunil Garg on 2024
//  Refactored to follow MVVM/SOLID patterns - Core view focused on layout and navigation
//  Components extracted to separate files for maintainability
//

import SwiftUI

@MainActor
struct PremiumPaywallView: View {
    // MARK: - Dependencies (DI compliant)
    private let subscriptionManager: SubscriptionManager
    private let helper: PremiumPaywallHelper
    private let sections: PremiumPaywallSections

    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var selectedTier: SubscriptionTier?
    @State private var currentFeatureIndex = 0
    @State private var showingPurchaseLoading = false
    @State private var carouselTimer: Timer?

    // MARK: - Initialization (DI constructor)
    init(subscriptionManager: SubscriptionManager? = nil) {
        // Use provided manager or default to shared instance (accessing within MainActor context)
        let manager = subscriptionManager ?? SubscriptionManager.shared
        self.subscriptionManager = manager
        self.helper = PremiumPaywallHelper(subscriptionManager: manager)
        self.sections = PremiumPaywallSections(subscriptionManager: manager)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        FintechColors.accentBackground.opacity(0.3),
                        FintechColors.primaryBlue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        sections.headerSection()

                        // Feature carousel
                        sections.featureCarouselSection(currentIndex: $currentFeatureIndex)

                        // Pricing cards
                        sections.pricingSection(
                            selectedTier: selectedTier,
                            onTierSelect: { selectedTier = $0 }
                        )

                        // Benefits list
                        sections.benefitsSection()

                        // Social proof
                        sections.socialProofSection()

                        // CTA and legal
                        sections.ctaSection(
                            selectedTier: selectedTier,
                            showingLoading: $showingPurchaseLoading,
                            onPurchase: { tier in
                                await helper.purchaseSubscription(
                                    tier,
                                    showingLoading: $showingPurchaseLoading,
                                    dismissAction: { dismiss() }
                                )
                            },
                            onRestore: {
                                await helper.restorePurchases()
                            }
                        )

                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(FintechColors.textPrimary)
                }
            }
        }
        .onAppear {
            selectedTier = subscriptionManager.availableSubscriptions.first
            startFeatureCarousel()
        }
        .onDisappear {
            carouselTimer?.invalidate()
            carouselTimer = nil
        }
    }
    
    
    // MARK: - Helper Methods

    private func startFeatureCarousel() {
        carouselTimer = helper.startFeatureCarousel(
            featureCount: FeatureHighlight.allFeatures.count,
            currentIndex: $currentFeatureIndex
        )
    }
}

#Preview {
    PremiumPaywallView()
}