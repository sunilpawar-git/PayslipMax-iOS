import Foundation

/// Service responsible for defining and providing default achievements
protocol AchievementDefinitionsServiceProtocol {
    func getDefaultAchievements() -> [Achievement]
}

/// Service responsible for defining and providing default achievements
class AchievementDefinitionsService: AchievementDefinitionsServiceProtocol {

    /// Gets the complete set of default achievements available in the app
    func getDefaultAchievements() -> [Achievement] {
        return [
            // Quiz Achievements
            createQuizAchievement(
                title: "First Steps",
                description: "Answer your first quiz question",
                iconName: "star.fill",
                threshold: 1,
                pointsReward: 10
            ),

            createQuizAchievement(
                title: "Quiz Enthusiast",
                description: "Answer 10 quiz questions",
                iconName: "star.circle.fill",
                threshold: 10,
                pointsReward: 50
            ),

            createQuizAchievement(
                title: "Quiz Master",
                description: "Answer 50 quiz questions",
                iconName: "crown.fill",
                threshold: 50,
                pointsReward: 200
            ),

            // Streak Achievements
            createStreakAchievement(
                title: "On a Roll",
                description: "Get 3 questions correct in a row",
                iconName: "flame.fill",
                threshold: 3,
                pointsReward: 25
            ),

            createStreakAchievement(
                title: "Unstoppable",
                description: "Get 10 questions correct in a row",
                iconName: "bolt.fill",
                threshold: 10,
                pointsReward: 100
            ),

            // Mastery Achievements
            createMasteryAchievement(
                title: "Income Expert",
                description: "Master income-related questions",
                iconName: "dollarsign.circle.fill",
                threshold: 10,
                category: "income",
                pointsReward: 75
            ),

            createMasteryAchievement(
                title: "Deduction Specialist",
                description: "Master deduction-related questions",
                iconName: "minus.circle.fill",
                threshold: 10,
                category: "deductions",
                pointsReward: 75
            ),

            // Point Achievements
            createPointAchievement(
                title: "Point Collector",
                description: "Earn 100 total points",
                iconName: "gift.fill",
                threshold: 100,
                pointsReward: 50
            ),

            createPointAchievement(
                title: "Point Champion",
                description: "Earn 500 total points",
                iconName: "trophy.fill",
                threshold: 500,
                pointsReward: 150
            )
        ]
    }

    // MARK: - Private Helper Methods

    private func createQuizAchievement(
        title: String,
        description: String,
        iconName: String,
        threshold: Int,
        pointsReward: Int
    ) -> Achievement {
        Achievement(
            title: title,
            description: description,
            iconName: iconName,
            category: .quiz,
            requirement: AchievementRequirement(
                type: .questionsAnswered,
                threshold: threshold,
                category: nil
            ),
            pointsReward: pointsReward,
            isUnlocked: false,
            unlockedDate: nil
        )
    }

    private func createStreakAchievement(
        title: String,
        description: String,
        iconName: String,
        threshold: Int,
        pointsReward: Int
    ) -> Achievement {
        Achievement(
            title: title,
            description: description,
            iconName: iconName,
            category: .streak,
            requirement: AchievementRequirement(
                type: .correctStreak,
                threshold: threshold,
                category: nil
            ),
            pointsReward: pointsReward,
            isUnlocked: false,
            unlockedDate: nil
        )
    }

    private func createMasteryAchievement(
        title: String,
        description: String,
        iconName: String,
        threshold: Int,
        category: String,
        pointsReward: Int
    ) -> Achievement {
        Achievement(
            title: title,
            description: description,
            iconName: iconName,
            category: .mastery,
            requirement: AchievementRequirement(
                type: .categoryMastery,
                threshold: threshold,
                category: category
            ),
            pointsReward: pointsReward,
            isUnlocked: false,
            unlockedDate: nil
        )
    }

    private func createPointAchievement(
        title: String,
        description: String,
        iconName: String,
        threshold: Int,
        pointsReward: Int
    ) -> Achievement {
        Achievement(
            title: title,
            description: description,
            iconName: iconName,
            category: .exploration,
            requirement: AchievementRequirement(
                type: .totalPoints,
                threshold: threshold,
                category: nil
            ),
            pointsReward: pointsReward,
            isUnlocked: false,
            unlockedDate: nil
        )
    }
}
