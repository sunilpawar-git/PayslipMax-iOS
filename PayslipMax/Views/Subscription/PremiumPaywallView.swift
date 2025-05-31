import SwiftUI

struct PremiumPaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTier: SubscriptionTier?
    @State private var currentFeatureIndex = 0
    @State private var showingPurchaseLoading = false
    
    // Sample feature highlights
    private let featureHighlights = [
        FeatureHighlight(
            icon: "brain",
            title: "AI-Powered Health Score",
            description: "Get a comprehensive financial health assessment based on 5 key factors",
            benefit: "Know exactly where you stand financially",
            gradient: [Color.blue, Color.cyan]
        ),
        FeatureHighlight(
            icon: "crystal.ball",
            title: "Predictive Analytics",
            description: "See your future salary growth, tax projections, and retirement readiness",
            benefit: "Plan ahead with confidence",
            gradient: [Color.purple, Color.pink]
        ),
        FeatureHighlight(
            icon: "lightbulb",
            title: "Professional Recommendations",
            description: "Get expert advice on tax optimization, career growth, and investments",
            benefit: "Save thousands with actionable insights",
            gradient: [Color.orange, Color.yellow]
        ),
        FeatureHighlight(
            icon: "chart.bar.xaxis",
            title: "Industry Benchmarks",
            description: "Compare your salary and benefits with industry standards",
            benefit: "Know your market value",
            gradient: [Color.green, Color.mint]
        )
    ]
    
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
                        headerSection
                        
                        // Feature carousel
                        featureCarouselSection
                        
                        // Pricing cards
                        pricingSection
                        
                        // Benefits list
                        benefitsSection
                        
                        // Social proof
                        socialProofSection
                        
                        // CTA and legal
                        ctaSection
                        
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
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
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
                Text("Unlock Premium Insights")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Transform your payslips into powerful financial intelligence")
                    .font(.title3)
                    .foregroundColor(FintechColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Feature Carousel
    
    private var featureCarouselSection: some View {
        VStack(spacing: 20) {
            Text("What You'll Get")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            TabView(selection: $currentFeatureIndex) {
                ForEach(Array(featureHighlights.enumerated()), id: \.offset) { index, feature in
                    FeatureCard(feature: feature)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(height: 300)
            .animation(.easeInOut, value: currentFeatureIndex)
        }
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 20) {
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(subscriptionManager.availableSubscriptions.filter { !$0.id.contains("pro") }, id: \.id) { tier in
                    PricingCard(
                        tier: tier,
                        isSelected: selectedTier?.id == tier.id,
                        subscriptionManager: subscriptionManager
                    ) {
                        selectedTier = tier
                    }
                }
            }
            
            // Pro tier (full width)
            if let proTier = subscriptionManager.availableSubscriptions.first(where: { $0.id.contains("pro") }) {
                PricingCard(
                    tier: proTier,
                    isSelected: selectedTier?.id == proTier.id,
                    subscriptionManager: subscriptionManager,
                    isFullWidth: true
                ) {
                    selectedTier = proTier
                }
            }
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(spacing: 16) {
            Text("Why Premium Users Love PayslipMax")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            VStack(spacing: 12) {
                BenefitRow(
                    icon: "checkmark.circle.fill",
                    title: "Save Money",
                    description: "Average user saves ₹25,000 annually through tax optimization",
                    color: .green
                )
                
                BenefitRow(
                    icon: "arrow.up.right.circle.fill",
                    title: "Grow Income",
                    description: "Career recommendations help users increase salary by 15-20%",
                    color: FintechColors.primaryBlue
                )
                
                BenefitRow(
                    icon: "shield.checkered",
                    title: "Reduce Risk",
                    description: "Identify financial risks before they become problems",
                    color: .orange
                )
                
                BenefitRow(
                    icon: "clock.fill",
                    title: "Save Time",
                    description: "Automated analysis saves 10+ hours of manual calculation",
                    color: .purple
                )
            }
        }
        .fintechCardStyle()
    }
    
    // MARK: - Social Proof
    
    private var socialProofSection: some View {
        VStack(spacing: 16) {
            Text("Trusted by 10,000+ Users")
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
                    
                    Text("4.9/5 Rating")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                // Stats
                VStack(spacing: 8) {
                    Text("₹2.5Cr+")
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
                    Text("94%")
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
    
    // MARK: - CTA Section
    
    private var ctaSection: some View {
        VStack(spacing: 20) {
            if let selectedTier = selectedTier {
                Button(action: {
                    Task {
                        await purchaseSubscription(selectedTier)
                    }
                }) {
                    HStack {
                        if showingPurchaseLoading {
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
                .disabled(showingPurchaseLoading)
            }
            
            Button("Restore Purchases") {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            }
            .font(.subheadline)
            .foregroundColor(FintechColors.primaryBlue)
            
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
    
    // MARK: - Helper Methods
    
    private func startFeatureCarousel() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentFeatureIndex = (currentFeatureIndex + 1) % featureHighlights.count
            }
        }
    }
    
    private func purchaseSubscription(_ tier: SubscriptionTier) async {
        showingPurchaseLoading = true
        
        do {
            try await subscriptionManager.subscribeTo(tier)
            dismiss()
        } catch {
            // Handle error
            print("Purchase failed: \(error)")
        }
        
        showingPurchaseLoading = false
    }
}

// MARK: - Supporting Views

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
                // Header
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
                
                // Pricing
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
                
                // Features
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
}

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

// MARK: - Supporting Models

struct FeatureHighlight {
    let icon: String
    let title: String
    let description: String
    let benefit: String
    let gradient: [Color]
}

#Preview {
    PremiumPaywallView()
}