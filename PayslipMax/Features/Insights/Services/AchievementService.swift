import Foundation
import SwiftUI

/// Service responsible for managing achievements, progress tracking, and badge unlocking
@MainActor
class AchievementService: ObservableObject {

    // MARK: - Dependencies

    private let definitionsService: AchievementDefinitionsServiceProtocol
    private let validationService: AchievementValidationServiceProtocol
    private let progressCalculator: AchievementProgressCalculatorProtocol
    private let persistenceService: AchievementPersistenceServiceProtocol

    // MARK: - Published Properties

    @Published var userProgress: UserGamificationProgress = UserGamificationProgress()
    @Published var availableAchievements: [Achievement] = []
    @Published var recentlyUnlockedAchievements: [Achievement] = []

    // MARK: - Initialization

    init(
        definitionsService: AchievementDefinitionsServiceProtocol = AchievementDefinitionsService(),
        validationService: AchievementValidationServiceProtocol = AchievementValidationService(),
        progressCalculator: AchievementProgressCalculatorProtocol = AchievementProgressCalculator(),
        persistenceService: AchievementPersistenceServiceProtocol = AchievementPersistenceService()
    ) {
        self.definitionsService = definitionsService
        self.validationService = validationService
        self.progressCalculator = progressCalculator
        self.persistenceService = persistenceService

        setupDefaultAchievements()
        loadUserProgress()
    }
    
    // MARK: - Achievement Management
    
    /// Records a quiz answer and updates progress
    func recordQuizAnswer(
        correct: Bool,
        points: Int,
        category: String,
        question: QuizQuestion
    ) {
        userProgress.recordAnswer(correct: correct, points: points, category: category)

        // Check for newly unlocked achievements
        let newlyUnlocked = validationService.checkForNewAchievements(
            availableAchievements: availableAchievements,
            userProgress: userProgress
        )

        if !newlyUnlocked.isEmpty {
            // Update user progress with unlocked achievements
            for achievement in newlyUnlocked {
                userProgress.unlockedAchievements.append(achievement.id)
                userProgress.totalPoints += achievement.pointsReward
            }

            recentlyUnlockedAchievements.append(contentsOf: newlyUnlocked)
            // Auto-clear after 5 seconds
            Task {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                recentlyUnlockedAchievements.removeAll { achievement in
                    newlyUnlocked.contains { $0.id == achievement.id }
                }
            }
        }

        persistenceService.saveUserProgress(userProgress)
    }
    
    
    /// Gets unlocked achievements
    func getUnlockedAchievements() -> [Achievement] {
        return availableAchievements.filter { achievement in
            userProgress.unlockedAchievements.contains(achievement.id)
                 }.map { achievement in
            Achievement(
                title: achievement.title,
                description: achievement.description,
                iconName: achievement.iconName,
                category: achievement.category,
                requirement: achievement.requirement,
                pointsReward: achievement.pointsReward,
                isUnlocked: true,
                unlockedDate: Date() // Would be actual unlock date in real implementation
            )
        }
    }
    
    /// Gets locked achievements with progress indicators
    func getLockedAchievements() -> [Achievement] {
        return availableAchievements.filter { achievement in
            !userProgress.unlockedAchievements.contains(achievement.id)
        }
    }
    
    /// Gets achievement progress percentage (0-100)
    func getAchievementProgress(_ achievement: Achievement) -> Double {
        return progressCalculator.calculateProgress(for: achievement, userProgress: userProgress)
    }
    
    // MARK: - Data Persistence

    /// Loads user progress from storage
    private func loadUserProgress() {
        if let progress = persistenceService.loadUserProgress() {
            userProgress = progress
        }
    }

    /// Resets all progress data (for development/testing)
    func resetProgress() {
        userProgress = UserGamificationProgress()
        recentlyUnlockedAchievements.removeAll()
        persistenceService.resetProgress()
    }
    
    // MARK: - Default Achievements Setup

    /// Sets up the default achievements available in the app
    private func setupDefaultAchievements() {
        availableAchievements = definitionsService.getDefaultAchievements()
    }
} 