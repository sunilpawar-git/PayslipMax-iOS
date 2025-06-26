import Foundation
import SwiftUI

/// Service responsible for managing achievements, progress tracking, and badge unlocking
@MainActor
class AchievementService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var userProgress: UserGamificationProgress = UserGamificationProgress()
    @Published var availableAchievements: [Achievement] = []
    @Published var recentlyUnlockedAchievements: [Achievement] = []
    
    // MARK: - Initialization
    
    init() {
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
        let newlyUnlocked = checkForNewAchievements()
        if !newlyUnlocked.isEmpty {
            recentlyUnlockedAchievements.append(contentsOf: newlyUnlocked)
            // Auto-clear after 5 seconds
            Task {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                recentlyUnlockedAchievements.removeAll { achievement in
                    newlyUnlocked.contains { $0.id == achievement.id }
                }
            }
        }
        
        saveUserProgress()
    }
    
    /// Checks for newly unlocked achievements
    private func checkForNewAchievements() -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        
        for achievement in availableAchievements {
            // Skip if already unlocked
            if userProgress.unlockedAchievements.contains(achievement.id) {
                continue
            }
            
            // Check if requirement is met
            if isAchievementUnlocked(achievement) {
                // Unlock the achievement
                userProgress.unlockedAchievements.append(achievement.id)
                userProgress.totalPoints += achievement.pointsReward
                
                // Create unlocked version
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
    
    /// Checks if an achievement requirement is met
    private func isAchievementUnlocked(_ achievement: Achievement) -> Bool {
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
        let requirement = achievement.requirement
        
        switch requirement.type {
        case .questionsAnswered:
            return min(100, (Double(userProgress.totalQuestionsAnswered) / Double(requirement.threshold)) * 100)
            
        case .correctStreak:
            return min(100, (Double(userProgress.currentStreak) / Double(requirement.threshold)) * 100)
            
        case .perfectQuiz:
            return 0 // Would be calculated based on perfect quiz count
            
        case .categoryMastery:
            guard let category = requirement.category,
                  let categoryStats = userProgress.categoryStats[category] else {
                return 0
            }
            let questionsProgress = (Double(categoryStats.questionsAnswered) / Double(requirement.threshold)) * 50
            let accuracyProgress = (categoryStats.accuracyPercentage / 80) * 50
            return min(100, questionsProgress + accuracyProgress)
            
        case .totalPoints:
            return min(100, (Double(userProgress.totalPoints) / Double(requirement.threshold)) * 100)
        }
    }
    
    // MARK: - Data Persistence
    
    /// Loads user progress from storage
    private func loadUserProgress() {
        // TODO: Load from SwiftData or UserDefaults
        // For now, using default progress
        if let data = UserDefaults.standard.data(forKey: "userGamificationProgress"),
           let progress = try? JSONDecoder().decode(UserGamificationProgress.self, from: data) {
            userProgress = progress
        }
    }
    
    /// Saves user progress to storage
    private func saveUserProgress() {
        // TODO: Save to SwiftData or UserDefaults
        if let data = try? JSONEncoder().encode(userProgress) {
            UserDefaults.standard.set(data, forKey: "userGamificationProgress")
        }
    }
    
    /// Resets all progress data (for development/testing)
    func resetProgress() {
        userProgress = UserGamificationProgress()
        recentlyUnlockedAchievements.removeAll()
        saveUserProgress()
    }
    
    // MARK: - Default Achievements Setup
    
    /// Sets up the default achievements available in the app
    private func setupDefaultAchievements() {
        availableAchievements = [
            // Quiz Achievements
            Achievement(
                title: "First Steps",
                description: "Answer your first quiz question",
                iconName: "star.fill",
                category: .quiz,
                requirement: AchievementRequirement(
                    type: .questionsAnswered,
                    threshold: 1,
                    category: nil
                ),
                pointsReward: 10,
                isUnlocked: false,
                unlockedDate: nil
            ),
            
            Achievement(
                title: "Quiz Enthusiast",
                description: "Answer 10 quiz questions",
                iconName: "star.circle.fill",
                category: .quiz,
                requirement: AchievementRequirement(
                    type: .questionsAnswered,
                    threshold: 10,
                    category: nil
                ),
                pointsReward: 50,
                isUnlocked: false,
                unlockedDate: nil
            ),
            
            Achievement(
                title: "Quiz Master",
                description: "Answer 50 quiz questions",
                iconName: "crown.fill",
                category: .quiz,
                requirement: AchievementRequirement(
                    type: .questionsAnswered,
                    threshold: 50,
                    category: nil
                ),
                pointsReward: 200,
                isUnlocked: false,
                unlockedDate: nil
            ),
            
            // Streak Achievements
            Achievement(
                title: "On a Roll",
                description: "Get 3 questions correct in a row",
                iconName: "flame.fill",
                category: .streak,
                requirement: AchievementRequirement(
                    type: .correctStreak,
                    threshold: 3,
                    category: nil
                ),
                pointsReward: 25,
                isUnlocked: false,
                unlockedDate: nil
            ),
            
            Achievement(
                title: "Unstoppable",
                description: "Get 10 questions correct in a row",
                iconName: "bolt.fill",
                category: .streak,
                requirement: AchievementRequirement(
                    type: .correctStreak,
                    threshold: 10,
                    category: nil
                ),
                pointsReward: 100,
                isUnlocked: false,
                unlockedDate: nil
            ),
            
            // Mastery Achievements
            Achievement(
                title: "Income Expert",
                description: "Master income-related questions",
                iconName: "dollarsign.circle.fill",
                category: .mastery,
                requirement: AchievementRequirement(
                    type: .categoryMastery,
                    threshold: 10,
                    category: "income"
                ),
                pointsReward: 75,
                isUnlocked: false,
                unlockedDate: nil
            ),
            
            Achievement(
                title: "Deduction Specialist",
                description: "Master deduction-related questions",
                iconName: "minus.circle.fill",
                category: .mastery,
                requirement: AchievementRequirement(
                    type: .categoryMastery,
                    threshold: 10,
                    category: "deductions"
                ),
                pointsReward: 75,
                isUnlocked: false,
                unlockedDate: nil
            ),
            
            // Point Achievements
            Achievement(
                title: "Point Collector",
                description: "Earn 100 total points",
                iconName: "gift.fill",
                category: .exploration,
                requirement: AchievementRequirement(
                    type: .totalPoints,
                    threshold: 100,
                    category: nil
                ),
                pointsReward: 50,
                isUnlocked: false,
                unlockedDate: nil
            ),
            
            Achievement(
                title: "Point Champion",
                description: "Earn 500 total points",
                iconName: "trophy.fill",
                category: .exploration,
                requirement: AchievementRequirement(
                    type: .totalPoints,
                    threshold: 500,
                    category: nil
                ),
                pointsReward: 150,
                isUnlocked: false,
                unlockedDate: nil
            )
        ]
    }
} 