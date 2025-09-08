import Foundation
import SwiftUI

// MARK: - User Progress Tracking

/// Tracks user's gamification progress
struct UserGamificationProgress: Codable {
    var totalPoints: Int = 0
    var totalQuestionsAnswered: Int = 0
    var totalCorrectAnswers: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastQuizDate: Date?
    var unlockedAchievements: [UUID] = []
    var categoryStats: [String: CategoryStats] = [:]

    var level: Int {
        // Level calculation: every 100 points = 1 level
        return max(1, totalPoints / 100)
    }

    var accuracyPercentage: Double {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return (Double(totalCorrectAnswers) / Double(totalQuestionsAnswered)) * 100
    }

    mutating func recordAnswer(correct: Bool, points: Int, category: String) {
        totalQuestionsAnswered += 1
        lastQuizDate = Date()

        if correct {
            totalCorrectAnswers += 1
            totalPoints += points
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            // Apply penalty for wrong answer, but never go below 0 stars
            totalPoints = max(0, totalPoints - 1)
            currentStreak = 0
        }

        // Update category stats
        if categoryStats[category] == nil {
            categoryStats[category] = CategoryStats()
        }
        categoryStats[category]?.recordAnswer(correct: correct)
    }
}

/// Statistics for specific insight categories
struct CategoryStats: Codable {
    var questionsAnswered: Int = 0
    var correctAnswers: Int = 0
    var masteryLevel: MasteryLevel = .beginner

    var accuracyPercentage: Double {
        guard questionsAnswered > 0 else { return 0 }
        return (Double(correctAnswers) / Double(questionsAnswered)) * 100
    }

    mutating func recordAnswer(correct: Bool) {
        questionsAnswered += 1
        if correct {
            correctAnswers += 1
        }
        updateMasteryLevel()
    }

    private mutating func updateMasteryLevel() {
        if questionsAnswered >= 20 && accuracyPercentage >= 90 {
            masteryLevel = .expert
        } else if questionsAnswered >= 10 && accuracyPercentage >= 75 {
            masteryLevel = .intermediate
        } else if questionsAnswered >= 5 && accuracyPercentage >= 60 {
            masteryLevel = .novice
        }
    }
}

/// User's mastery level in different categories
enum MasteryLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case novice = "novice"
    case intermediate = "intermediate"
    case expert = "expert"

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .novice: return "Novice"
        case .intermediate: return "Intermediate"
        case .expert: return "Expert"
        }
    }

    var color: Color {
        switch self {
        case .beginner: return .gray
        case .novice: return .blue
        case .intermediate: return .orange
        case .expert: return .purple
        }
    }

    var iconName: String {
        switch self {
        case .beginner: return "person.fill"
        case .novice: return "person.badge.plus"
        case .intermediate: return "person.2.fill"
        case .expert: return "crown.fill"
        }
    }
}
