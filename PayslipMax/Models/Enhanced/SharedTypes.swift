import Foundation
import SwiftUI

// MARK: - Shared Types for PayslipMax
// This file consolidates all shared types to prevent ambiguous type lookup errors

// MARK: - Investment Tips Related Types

/// Reaction types for investment tips
enum TipReaction: String, CaseIterable, Codable, Hashable {
    case helpful = "helpful"
    case love = "love"
    case insightful = "insightful"
    case bookmark = "bookmark"
    case confusing = "confusing"
    
    var emoji: String {
        switch self {
        case .helpful: return "👍"
        case .love: return "❤️"
        case .insightful: return "💡"
        case .bookmark: return "🔖"
        case .confusing: return "🤔"
        }
    }
    
    var title: String {
        switch self {
        case .helpful: return "Helpful"
        case .love: return "Love it"
        case .insightful: return "Insightful"
        case .bookmark: return "Bookmark"
        case .confusing: return "Confusing"
        }
    }
    
    var color: Color {
        switch self {
        case .helpful: return .green
        case .love: return .red
        case .insightful: return .blue
        case .bookmark: return .orange
        case .confusing: return .orange
        }
    }
    
    var iconName: String {
        switch self {
        case .helpful: return "hand.thumbsup.fill"
        case .love: return "heart.fill"
        case .insightful: return "lightbulb.fill"
        case .bookmark: return "bookmark.fill"
        case .confusing: return "questionmark.circle.fill"
        }
    }
    
    var activeColor: Color {
        return color
    }
    
    var description: String {
        return title
    }
}

/// Categories for organizing investment tips
enum TipCategory: String, CaseIterable, Codable {
    case beginner = "Getting Started"
    case intermediate = "Building Wealth"
    case advanced = "Advanced Strategies"
    case taxOptimization = "Tax Smart"
    case emergencyFund = "Safety First"
    case retirement = "Future Planning"
    case marketPsychology = "Investor Mindset"
    case trending = "Market Insights"
    
    var icon: String {
        switch self {
        case .beginner: return "graduationcap.fill"
        case .intermediate: return "chart.line.uptrend.xyaxis"
        case .advanced: return "brain.head.profile"
        case .taxOptimization: return "percent"
        case .emergencyFund: return "shield.checkered"
        case .retirement: return "hourglass"
        case .marketPsychology: return "heart.fill"
        case .trending: return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .purple
        case .taxOptimization: return .orange
        case .emergencyFund: return .red
        case .retirement: return .indigo
        case .marketPsychology: return .pink
        case .trending: return .yellow
        }
    }
}

/// Difficulty levels for tips
enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    var sortOrder: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
}

/// Investment experience levels
enum InvestmentExperience: String, CaseIterable, Codable {
    case none = "none"
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
}

// MARK: - Achievement System Types

/// Achievement definition
struct Achievement: Identifiable, Codable {
    let id: UUID
    let type: AchievementType
    let title: String
    let description: String
    let icon: String
    let tier: AchievementTier
    let category: AchievementCategory
    let points: Int
    let requirements: AchievementRequirement
    let isUnlocked: Bool
    let unlockedDate: Date?
    let progress: Double
    
    init(
        id: UUID = UUID(),
        type: AchievementType,
        title: String,
        description: String,
        icon: String,
        tier: AchievementTier,
        category: AchievementCategory,
        points: Int,
        requirements: AchievementRequirement,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil,
        progress: Double = 0.0
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.icon = icon
        self.tier = tier
        self.category = category
        self.points = points
        self.requirements = requirements
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.progress = progress
    }
}

enum AchievementType: String, Codable, CaseIterable {
    case tipStreak = "tip_streak"
    case categoryExplorer = "category_explorer"
    case reactionMaster = "reaction_master"
    case knowledgeSeeker = "knowledge_seeker"
    case socialSharer = "social_sharer"
    case goalAchiever = "goal_achiever"
    case consistentLearner = "consistent_learner"
}

enum AchievementTier: Int, CaseIterable, Codable {
    case bronze = 1
    case silver = 2
    case gold = 3
    case platinum = 4
    
    var points: Int {
        switch self {
        case .bronze: return 100
        case .silver: return 250
        case .gold: return 500
        case .platinum: return 1000
        }
    }
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.7, green: 0.7, blue: 0.7)
        case .gold: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 1.0)
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case learning = "learning"
    case engagement = "engagement"
    case consistency = "consistency"
    case social = "social"
    case knowledge = "knowledge"
    case goals = "goals"
}

struct AchievementRequirement: Codable {
    let type: RequirementType
    let target: Int
    let timeframe: TimeFrame?
    
    enum RequirementType: String, Codable {
        case tipViews = "tip_views"
        case streakDays = "streak_days"
        case categoryExploration = "category_exploration"
        case reactionCount = "reaction_count"
        case shareCount = "share_count"
        case goalCompletion = "goal_completion"
    }
    
    enum TimeFrame: String, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case allTime = "all_time"
    }
}

// MARK: - Action Items

/// Generic action item for insights and tips
struct ActionItem: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let actionType: ActionItemType
    let category: ActionItemCategory
    let priority: ActionItemPriority
    let isCompleted: Bool
    let dueDate: Date?
    let estimatedDuration: TimeInterval?
    let externalURL: URL?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        actionType: ActionItemType,
        category: ActionItemCategory = .general,
        priority: ActionItemPriority = .medium,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        estimatedDuration: TimeInterval? = nil,
        externalURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.actionType = actionType
        self.category = category
        self.priority = priority
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.estimatedDuration = estimatedDuration
        self.externalURL = externalURL
    }
}

enum ActionItemType: String, Codable, CaseIterable {
    case calculate = "calculate"
    case remind = "remind"
    case bookmark = "bookmark"
    case share = "share"
    case learn = "learn"
    case track = "track"
    case review = "review"
    case optimize = "optimize"
    
    var icon: String {
        switch self {
        case .calculate: return "calculator"
        case .remind: return "bell"
        case .bookmark: return "bookmark"
        case .share: return "square.and.arrow.up"
        case .learn: return "book"
        case .track: return "chart.bar"
        case .review: return "magnifyingglass"
        case .optimize: return "slider.horizontal.3"
        }
    }
}

enum ActionItemCategory: String, Codable, CaseIterable {
    case general = "general"
    case investment = "investment"
    case savings = "savings"
    case tax = "tax"
    case insurance = "insurance"
    case debt = "debt"
    case goals = "goals"
}

enum ActionItemPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Financial Goals

/// Financial goal representation
struct FinancialGoal: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let targetAmount: Double
    let currentAmount: Double
    let targetDate: Date
    let category: GoalCategory
    let priority: GoalPriority
    let isActive: Bool
    let createdDate: Date
    let lastUpdated: Date
    
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        targetAmount: Double,
        currentAmount: Double = 0.0,
        targetDate: Date,
        category: GoalCategory,
        priority: GoalPriority = .medium,
        isActive: Bool = true,
        createdDate: Date = Date(),
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.category = category
        self.priority = priority
        self.isActive = isActive
        self.createdDate = createdDate
        self.lastUpdated = lastUpdated
    }
}

enum GoalCategory: String, Codable, CaseIterable {
    case emergencyFund = "emergency_fund"
    case retirement = "retirement"
    case house = "house"
    case education = "education"
    case vacation = "vacation"
    case car = "car"
    case investment = "investment"
    case debt = "debt"
    case other = "other"
    
    var icon: String {
        switch self {
        case .emergencyFund: return "shield.checkered"
        case .retirement: return "hourglass"
        case .house: return "house"
        case .education: return "graduationcap"
        case .vacation: return "airplane"
        case .car: return "car"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .debt: return "creditcard"
        case .other: return "target"
        }
    }
}

enum GoalPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Investment Tips Specific Types

/// Actionable items associated with investment tips (renamed to avoid conflicts)
struct InvestmentActionItem: Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let actionType: InvestmentActionType
    let externalURL: URL?
    let isCompleted: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        actionType: InvestmentActionType,
        externalURL: URL? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.actionType = actionType
        self.externalURL = externalURL
        self.isCompleted = isCompleted
    }
}

/// Types of actions users can take for investment tips
enum InvestmentActionType: String, Codable, CaseIterable {
    case calculate = "calculate"
    case remind = "remind"
    case bookmark = "bookmark"
    case share = "share"
    case learn = "learn"
    case track = "track"
    
    var icon: String {
        switch self {
        case .calculate: return "calculator"
        case .remind: return "bell"
        case .bookmark: return "bookmark"
        case .share: return "square.and.arrow.up"
        case .learn: return "book"
        case .track: return "chart.bar"
        }
    }
}

/// Calculator types for interactive features
enum CalculatorType: String, Codable, CaseIterable {
    case compoundInterest = "compound_interest"
    case emergencyFund = "emergency_fund"
    case retirementSavings = "retirement_savings"
    case loanPayoff = "loan_payoff"
    case investmentReturn = "investment_return"
    case taxOptimization = "tax_optimization"
    
    var title: String {
        switch self {
        case .compoundInterest: return "Compound Interest Calculator"
        case .emergencyFund: return "Emergency Fund Calculator"
        case .retirementSavings: return "Retirement Savings Calculator"
        case .loanPayoff: return "Loan Payoff Calculator"
        case .investmentReturn: return "Investment Return Calculator"
        case .taxOptimization: return "Tax Optimization Calculator"
        }
    }
}

/// References to visual assets
struct AssetReference: Codable, Hashable {
    let id: UUID
    let type: AssetType
    let filename: String
    let description: String
    
    init(
        id: UUID = UUID(),
        type: AssetType,
        filename: String,
        description: String
    ) {
        self.id = id
        self.type = type
        self.filename = filename
        self.description = description
    }
}

/// Types of visual assets
enum AssetType: String, Codable, CaseIterable {
    case icon = "icon"
    case chart = "chart"
    case infographic = "infographic"
    case video = "video"
    case animation = "animation"
}

// MARK: - Subscription Types (Minimal Implementation)

struct SubscriptionTier: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let price: Double
    let features: [PremiumInsightFeature]
    let analysisDepth: AnalysisDepth
    let updateFrequency: UpdateFrequency
    let supportLevel: SupportLevel
    
    enum AnalysisDepth: String, Codable {
        case basic, advanced, expert
    }
    
    enum UpdateFrequency: String, Codable {
        case monthly, weekly, daily
    }
    
    enum SupportLevel: String, Codable {
        case basic, premium, enterprise
    }
}

enum PremiumInsightFeature: String, CaseIterable, Codable {
    case basicAnalysis = "basic_analysis"
    case advancedCharts = "advanced_charts"
    case customReports = "custom_reports"
    case prioritySupport = "priority_support"
    
    enum FeatureCategory: String, Codable {
        case analytics, reporting, support
    }
    
    var category: FeatureCategory {
        switch self {
        case .basicAnalysis, .advancedCharts: return .analytics
        case .customReports: return .reporting  
        case .prioritySupport: return .support
        }
    }
}


// MARK: - Array Safe Subscript Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 