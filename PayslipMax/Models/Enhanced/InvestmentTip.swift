import Foundation
import SwiftUI

// MARK: - Investment Tip Model

/// The world's best investment tip model with advanced personalization, gamification, and user engagement
struct InvestmentTip: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let shortDescription: String
    let fullContent: String
    let category: TipCategory
    let difficultyLevel: DifficultyLevel
    let estimatedReadTime: TimeInterval
    let actionItems: [InvestmentActionItem]
    let relatedCalculators: [CalculatorType]
    let tags: [String]
    let visualAssets: [AssetReference]
    let createdDate: Date
    let lastUpdated: Date
    let viewCount: Int
    let rating: Double
    let personalizedScore: Double?
    let isBookmarked: Bool
    let userReaction: TipReaction?
    
    init(
        id: UUID = UUID(),
        title: String,
        shortDescription: String,
        fullContent: String,
        category: TipCategory,
        difficultyLevel: DifficultyLevel,
        estimatedReadTime: TimeInterval,
        actionItems: [InvestmentActionItem] = [],
        relatedCalculators: [CalculatorType] = [],
        tags: [String] = [],
        visualAssets: [AssetReference] = [],
        createdDate: Date = Date(),
        lastUpdated: Date = Date(),
        viewCount: Int = 0,
        rating: Double = 0.0,
        personalizedScore: Double? = nil,
        isBookmarked: Bool = false,
        userReaction: TipReaction? = nil
    ) {
        self.id = id
        self.title = title
        self.shortDescription = shortDescription
        self.fullContent = fullContent
        self.category = category
        self.difficultyLevel = difficultyLevel
        self.estimatedReadTime = estimatedReadTime
        self.actionItems = actionItems
        self.relatedCalculators = relatedCalculators
        self.tags = tags
        self.visualAssets = visualAssets
        self.createdDate = createdDate
        self.lastUpdated = lastUpdated
        self.viewCount = viewCount
        self.rating = rating
        self.personalizedScore = personalizedScore
        self.isBookmarked = isBookmarked
        self.userReaction = userReaction
    }
}

// MARK: - Extensions for World-Class Features

extension InvestmentTip {
    /// Beautiful formatted read time display
    var formattedReadTime: String {
        let minutes = Int(estimatedReadTime / 60)
        return minutes <= 1 ? "1 min read" : "\(minutes) min read"
    }
    
    /// Smart difficulty assessment
    func isSuitableFor(difficultyPreference: DifficultyLevel) -> Bool {
        difficultyLevel.sortOrder <= difficultyPreference.sortOrder
    }
    
    /// Advanced AI-powered relevance scoring
    func calculateRelevanceScore(for profile: UserProfile) -> Double {
        var score = 0.0
        
        // Category preference matching (40% weight)
        if profile.preferredCategories.contains(category) {
            score += 0.4
        }
        
        // Difficulty level matching (30% weight)
        if isSuitableFor(difficultyPreference: profile.preferredDifficulty) {
            score += 0.3
        }
        
        // Tag matching (10% weight per matching tag, max 20%)
        let matchingTags = Set(tags).intersection(Set(profile.interests))
        score += min(Double(matchingTags.count) * 0.1, 0.2)
        
        // Recency bonus (10% weight)
        let daysSinceCreated = Calendar.current.dateComponents([.day], from: createdDate, to: Date()).day ?? 0
        if daysSinceCreated <= 7 {
            score += 0.1
        } else if daysSinceCreated <= 30 {
            score += 0.05
        }
        
        // Quality score based on rating (10% weight)
        score += (rating / 5.0) * 0.1
        
        // Engagement bonus (5% weight)
        if viewCount > 100 {
            score += 0.05
        }
        
        return min(score, 1.0)
    }
    
    /// Trending status based on recent engagement
    var isTrending: Bool {
        let daysSinceCreated = Calendar.current.dateComponents([.day], from: createdDate, to: Date()).day ?? 0
        return daysSinceCreated <= 7 && viewCount > 50 && rating > 4.0
    }
    
    /// Premium content indicator
    var isPremium: Bool {
        difficultyLevel == .expert || category == .advanced || tags.contains("premium")
    }
    
    /// Estimated impact on user's financial knowledge
    var knowledgeImpact: KnowledgeImpact {
        switch (difficultyLevel, rating) {
        case (.expert, 4.5...5.0): return .transformative
        case (.advanced, 4.0...5.0): return .significant
        case (.intermediate, 3.5...5.0): return .moderate
        default: return .basic
        }
    }
}

// MARK: - Sample Data for World-Class Experience

extension InvestmentTip {
    /// Premium quality sample tips for demonstration
    static let worldClassSampleTips: [InvestmentTip] = [
        InvestmentTip(
            title: "🚀 Master the Power of Compound Interest",
            shortDescription: "Unlock exponential wealth growth with time's most powerful force",
            fullContent: """
            Compound interest is the eighth wonder of the world. Those who understand it earn it, those who don't pay it.
            
            Here's why starting early is your secret weapon:
            • ₹10,000 invested at age 25 becomes ₹3.2 lakhs by age 60
            • The same amount at age 35 becomes only ₹1.3 lakhs
            • Every 10 years you delay costs you 60% of potential wealth
            
            🎯 Action Steps:
            1. Start with just ₹1,000 per month
            2. Choose low-cost index funds (expense ratio < 0.5%)
            3. Automate your investments through SIP
            4. Never touch your investments for 25+ years
            
            💡 Pro Tip: Increase your investment by 10% every year to beat inflation and lifestyle inflation.
            """,
            category: .beginner,
            difficultyLevel: .beginner,
            estimatedReadTime: 240,
            actionItems: [
                InvestmentActionItem(
                    title: "Calculate Your Compound Interest Potential",
                    description: "See how much you could earn over 25 years",
                    actionType: .calculate
                ),
                InvestmentActionItem(
                    title: "Set Up Your First SIP",
                    description: "Start with ₹1,000/month in an index fund",
                    actionType: .track
                )
            ],
            relatedCalculators: [.compoundInterest, .retirementSavings],
            tags: ["compound interest", "wealth building", "SIP", "index funds", "long-term"],
            viewCount: 1247,
            rating: 4.9
        ),
        
        InvestmentTip(
            title: "🛡️ Build Your Financial Fortress: Emergency Fund Strategy",
            shortDescription: "Create an unshakeable foundation for your financial future",
            fullContent: """
            Your emergency fund isn't just savings—it's your financial freedom and peace of mind.
            
            🎯 The 3-6-12 Rule:
            • 3 months: Minimum for stable jobs
            • 6 months: Standard for most people
            • 12 months: For entrepreneurs & freelancers
            
            💰 Smart Emergency Fund Strategy:
            1. Keep 1 month in savings account (immediate access)
            2. Keep 2-3 months in liquid funds (1-day withdrawal)
            3. Keep remaining in short-term debt funds (2-3 day access)
            
            🚨 Emergency Fund Mistakes to Avoid:
            ❌ Investing it in stocks or equity funds
            ❌ Using it for planned expenses (vacation, shopping)
            ❌ Not separating it from your regular savings
            ❌ Keeping everything in zero-interest accounts
            
            ✅ Pro Strategy: Use the 'bucket approach' to maximize returns while maintaining liquidity.
            """,
            category: .emergencyFund,
            difficultyLevel: .beginner,
            estimatedReadTime: 300,
            actionItems: [
                InvestmentActionItem(
                    title: "Calculate Your Emergency Fund Target",
                    description: "Based on your monthly expenses",
                    actionType: .calculate
                ),
                InvestmentActionItem(
                    title: "Open a Separate Emergency Account",
                    description: "Keep it separate from regular savings",
                    actionType: .track
                ),
                InvestmentActionItem(
                    title: "Set Up Auto-Debit for Emergency Fund",
                    description: "Automate 20% of savings towards emergency fund",
                    actionType: .remind
                )
            ],
            relatedCalculators: [.emergencyFund],
            tags: ["emergency fund", "financial security", "liquidity", "risk management"],
            viewCount: 987,
            rating: 4.8
        ),
        
        InvestmentTip(
            title: "📊 Advanced Portfolio Diversification: Beyond Basic Asset Allocation",
            shortDescription: "Master sophisticated diversification strategies for optimal risk-adjusted returns",
            fullContent: """
            True diversification goes beyond the simple 60-40 equity-debt split. Here's how the pros do it:
            
            🎯 Smart Diversification Framework:
            
            **By Asset Class (Geographic):**
            • 40% Indian Equity (Large, Mid, Small cap)
            • 20% International Equity (US, Developed, Emerging)
            • 25% Fixed Income (Govt bonds, Corporate bonds, FDs)
            • 10% Alternative Assets (REITs, Gold, Commodities)
            • 5% Cash & Liquid funds
            
            **By Market Cap (Indian Equity):**
            • 60% Large Cap (stability)
            • 25% Mid Cap (growth)
            • 15% Small Cap (high growth potential)
            
            **By Sector Diversification:**
            Never put more than 20% in any single sector, even IT.
            
            🔄 Rebalancing Strategy:
            • Review quarterly, rebalance if deviation > 5%
            • Use new investments to rebalance
            • Consider tax implications before selling
            
            💡 Advanced Tip: Use correlation analysis to ensure your investments don't move together during market stress.
            """,
            category: .advanced,
            difficultyLevel: .advanced,
            estimatedReadTime: 420,
            actionItems: [
                InvestmentActionItem(
                    title: "Analyze Your Current Portfolio",
                    description: "Check asset allocation and correlation",
                    actionType: .calculate
                ),
                InvestmentActionItem(
                    title: "Create Rebalancing Schedule",
                    description: "Set quarterly review reminders",
                    actionType: .remind
                )
            ],
            relatedCalculators: [.investmentReturn],
            tags: ["diversification", "portfolio", "asset allocation", "rebalancing", "advanced", "premium"],
            viewCount: 543,
            rating: 4.7
        )
    ]
}

/// Knowledge impact levels for tips
enum KnowledgeImpact: String, CaseIterable {
    case basic = "Basic"
    case moderate = "Moderate"
    case significant = "Significant"
    case transformative = "Transformative"
    
    var color: Color {
        switch self {
        case .basic: return .blue
        case .moderate: return .green
        case .significant: return .orange
        case .transformative: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .basic: return "lightbulb"
        case .moderate: return "brain"
        case .significant: return "star.fill"
        case .transformative: return "crown.fill"
        }
    }
}

/// User profile for advanced personalization
struct UserProfile: Codable {
    let id: UUID
    let preferredCategories: [TipCategory]
    let preferredDifficulty: DifficultyLevel
    let interests: [String]
    let monthlyIncome: Double?
    let age: Int?
    let investmentExperience: InvestmentExperience
    let riskTolerance: RiskTolerance
    let financialGoals: [String]
    let readingHistory: [UUID] // Tip IDs
    
    init(
        id: UUID = UUID(),
        preferredCategories: [TipCategory] = [.beginner],
        preferredDifficulty: DifficultyLevel = .beginner,
        interests: [String] = [],
        monthlyIncome: Double? = nil,
        age: Int? = nil,
        investmentExperience: InvestmentExperience = .none,
        riskTolerance: RiskTolerance = .moderate,
        financialGoals: [String] = [],
        readingHistory: [UUID] = []
    ) {
        self.id = id
        self.preferredCategories = preferredCategories
        self.preferredDifficulty = preferredDifficulty
        self.interests = interests
        self.monthlyIncome = monthlyIncome
        self.age = age
        self.investmentExperience = investmentExperience
        self.riskTolerance = riskTolerance
        self.financialGoals = financialGoals
        self.readingHistory = readingHistory
    }
}

/// Risk tolerance levels
enum RiskTolerance: String, CaseIterable, Codable {
    case conservative = "Conservative"
    case moderate = "Moderate" 
    case aggressive = "Aggressive"
    
    var description: String {
        switch self {
        case .conservative: return "Prefer stability over high returns"
        case .moderate: return "Balanced approach to risk and returns"
        case .aggressive: return "Willing to take high risks for high returns"
        }
    }
} 