import Foundation

/// Service responsible for calculating achievement progress percentages
protocol AchievementProgressCalculatorProtocol {
    func calculateProgress(for achievement: Achievement, userProgress: UserGamificationProgress) -> Double
}

/// Service responsible for calculating achievement progress percentages
class AchievementProgressCalculator: AchievementProgressCalculatorProtocol {

    /// Calculates the progress percentage (0-100) for a given achievement
    func calculateProgress(for achievement: Achievement, userProgress: UserGamificationProgress) -> Double {
        let requirement = achievement.requirement

        switch requirement.type {
        case .questionsAnswered:
            return calculateQuestionsAnsweredProgress(userProgress: userProgress, threshold: requirement.threshold)

        case .correctStreak:
            return calculateCorrectStreakProgress(userProgress: userProgress, threshold: requirement.threshold)

        case .perfectQuiz:
            return calculatePerfectQuizProgress(userProgress: userProgress)

        case .categoryMastery:
            return calculateCategoryMasteryProgress(userProgress: userProgress, requirement: requirement)

        case .totalPoints:
            return calculateTotalPointsProgress(userProgress: userProgress, threshold: requirement.threshold)
        }
    }

    // MARK: - Private Calculation Methods

    private func calculateQuestionsAnsweredProgress(userProgress: UserGamificationProgress, threshold: Int) -> Double {
        return min(100, (Double(userProgress.totalQuestionsAnswered) / Double(threshold)) * 100)
    }

    private func calculateCorrectStreakProgress(userProgress: UserGamificationProgress, threshold: Int) -> Double {
        return min(100, (Double(userProgress.currentStreak) / Double(threshold)) * 100)
    }

    private func calculatePerfectQuizProgress(userProgress: UserGamificationProgress) -> Double {
        // Would be calculated based on perfect quiz count in real implementation
        return 0
    }

    private func calculateCategoryMasteryProgress(userProgress: UserGamificationProgress, requirement: AchievementRequirement) -> Double {
        guard let category = requirement.category,
              let categoryStats = userProgress.categoryStats[category] else {
            return 0
        }

        // 50% weight for questions answered, 50% for accuracy
        let questionsProgress = (Double(categoryStats.questionsAnswered) / Double(requirement.threshold)) * 50
        let accuracyProgress = (categoryStats.accuracyPercentage / 80) * 50

        return min(100, questionsProgress + accuracyProgress)
    }

    private func calculateTotalPointsProgress(userProgress: UserGamificationProgress, threshold: Int) -> Double {
        return min(100, (Double(userProgress.totalPoints) / Double(threshold)) * 100)
    }
}
