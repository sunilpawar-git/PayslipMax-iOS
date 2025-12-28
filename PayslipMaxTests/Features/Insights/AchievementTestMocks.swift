import Foundation
@testable import PayslipMax

/// Shared helpers for Achievement tests
enum AchievementTestHelpers {
    static func createMockQuestion() -> QuizQuestion {
        return QuizQuestion(
            id: UUID(),
            questionText: "Test question",
            questionType: .multipleChoice,
            options: ["A", "B", "C", "D"],
            correctAnswer: "A",
            explanation: "Test explanation",
            difficulty: .medium,
            relatedInsightType: .income,
            contextData: QuizContextData(
                userIncome: nil,
                userTaxRate: nil,
                userDSOPContribution: nil,
                averageIncome: nil,
                comparisonPeriod: nil,
                specificMonth: nil,
                calculationDetails: nil
            )
        )
    }

    static func createMockAchievement(
        title: String = "Test Achievement",
        pointsReward: Int = 10
    ) -> Achievement {
        return Achievement(
            id: UUID(),
            title: title,
            description: "Test description",
            iconName: "star.fill",
            category: .quiz,
            requirement: AchievementRequirement(
                type: .questionsAnswered,
                threshold: 1,
                category: nil
            ),
            pointsReward: pointsReward,
            isUnlocked: false,
            unlockedDate: nil
        )
    }
}

// MARK: - Mock Classes

final class MockAchievementDefinitionsService: AchievementDefinitionsServiceProtocol {
    var getDefaultAchievementsCalled = false
    var defaultAchievements: [Achievement] = []

    func getDefaultAchievements() -> [Achievement] {
        getDefaultAchievementsCalled = true
        if defaultAchievements.isEmpty {
            return [
                Achievement(
                    title: "First Steps",
                    description: "Answer your first question",
                    iconName: "star.fill",
                    category: .quiz,
                    requirement: AchievementRequirement(
                        type: .questionsAnswered,
                        threshold: 1,
                        category: nil
                    ),
                    pointsReward: 10
                )
            ]
        }
        return defaultAchievements
    }
}

final class MockAchievementValidationService: AchievementValidationServiceProtocol {
    var checkForNewAchievementsCalled = false
    var achievementsToReturn: [Achievement] = []

    func checkForNewAchievements(
        availableAchievements: [Achievement],
        userProgress: UserGamificationProgress
    ) -> [Achievement] {
        checkForNewAchievementsCalled = true
        return achievementsToReturn
    }

    func isAchievementUnlocked(
        _ achievement: Achievement,
        userProgress: UserGamificationProgress
    ) -> Bool {
        return userProgress.unlockedAchievements.contains(achievement.id)
    }
}

final class MockAchievementProgressCalculator: AchievementProgressCalculatorProtocol {
    var calculateProgressCalled = false
    var progressToReturn: Double = 0.0

    func calculateProgress(
        for achievement: Achievement,
        userProgress: UserGamificationProgress
    ) -> Double {
        calculateProgressCalled = true
        return progressToReturn
    }
}

final class MockAchievementPersistenceService: AchievementPersistenceServiceProtocol {
    var saveUserProgressCalled = false
    var loadUserProgressCalled = false
    var resetProgressCalled = false
    var savedProgress: UserGamificationProgress?

    func saveUserProgress(_ progress: UserGamificationProgress) {
        saveUserProgressCalled = true
        savedProgress = progress
    }

    func loadUserProgress() -> UserGamificationProgress? {
        loadUserProgressCalled = true
        return savedProgress
    }

    func resetProgress() {
        resetProgressCalled = true
        savedProgress = nil
    }
}

