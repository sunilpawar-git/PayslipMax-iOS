import Foundation

/// Service responsible for validating achievement unlock conditions
protocol AchievementValidationServiceProtocol {
    func checkForNewAchievements(availableAchievements: [Achievement], userProgress: UserGamificationProgress) -> [Achievement]
    func isAchievementUnlocked(_ achievement: Achievement, userProgress: UserGamificationProgress) -> Bool
}

/// Service responsible for validating achievement unlock conditions
class AchievementValidationService: AchievementValidationServiceProtocol {

    /// Checks for newly unlocked achievements based on user progress
    func checkForNewAchievements(availableAchievements: [Achievement], userProgress: UserGamificationProgress) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        for achievement in availableAchievements {
            // Skip if already unlocked
            if userProgress.unlockedAchievements.contains(achievement.id) {
                continue
            }

            // Check if requirement is met
            if isAchievementUnlocked(achievement, userProgress: userProgress) {
                // Unlock the achievement
                let unlockedAchievement = Achievement(
                    title: achievement.title,
                    description: achievement.description,
                    iconName: achievement.iconName,
                    category: achievement.category,
                    requirement: achievement.requirement,
                    pointsReward: achievement.pointsReward,
                    isUnlocked: true,
                    unlockedDate: Date()
                )

                newlyUnlocked.append(unlockedAchievement)
            }
        }

        return newlyUnlocked
    }

    /// Checks if a specific achievement requirement is met
    func isAchievementUnlocked(_ achievement: Achievement, userProgress: UserGamificationProgress) -> Bool {
        let requirement = achievement.requirement

        switch requirement.type {
        case .questionsAnswered:
            return userProgress.totalQuestionsAnswered >= requirement.threshold

        case .correctStreak:
            return userProgress.currentStreak >= requirement.threshold

        case .perfectQuiz:
            // This would be handled differently, based on quiz session results
            return false

        case .categoryMastery:
            guard let category = requirement.category,
                  let categoryStats = userProgress.categoryStats[category] else {
                return false
            }
            return categoryStats.questionsAnswered >= requirement.threshold &&
                   categoryStats.accuracyPercentage >= 80

        case .totalPoints:
            return userProgress.totalPoints >= requirement.threshold
        }
    }
}
