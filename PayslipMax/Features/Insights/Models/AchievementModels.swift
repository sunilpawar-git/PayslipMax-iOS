import Foundation
import SwiftUI

// MARK: - Achievement System

/// Represents an achievement the user can earn
struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let requirement: AchievementRequirement
    let pointsReward: Int
    let isUnlocked: Bool
    let unlockedDate: Date?

    // Custom initializer to handle UUID generation
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        iconName: String,
        category: AchievementCategory,
        requirement: AchievementRequirement,
        pointsReward: Int,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.pointsReward = pointsReward
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }

    var badgeColor: Color {
        switch category {
        case .quiz: return FintechColors.primaryBlue
        case .streak: return FintechColors.successGreen
        case .mastery: return FintechColors.premiumGold
        case .exploration: return FintechColors.secondaryBlue
        }
    }
}

/// Categories of achievements
enum AchievementCategory: String, Codable, CaseIterable {
    case quiz = "quiz"
    case streak = "streak"
    case mastery = "mastery"
    case exploration = "exploration"

    var displayName: String {
        switch self {
        case .quiz: return "Quiz Master"
        case .streak: return "Consistency"
        case .mastery: return "Subject Expert"
        case .exploration: return "Explorer"
        }
    }
}

/// Requirements for unlocking achievements
struct AchievementRequirement: Codable {
    let type: RequirementType
    let threshold: Int
    let category: String?

    enum RequirementType: String, Codable {
        case questionsAnswered = "questions_answered"
        case correctStreak = "correct_streak"
        case perfectQuiz = "perfect_quiz"
        case categoryMastery = "category_mastery"
        case totalPoints = "total_points"
    }
}
