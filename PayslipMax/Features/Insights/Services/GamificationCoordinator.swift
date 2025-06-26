import Foundation
import SwiftUI
import Combine

/// Coordinator that manages gamification state consistency across the entire app
/// Ensures star counts and quiz progress are synchronized between all views
@MainActor
class GamificationCoordinator: ObservableObject {
    
    // MARK: - Singleton Instance
    
    static let shared = GamificationCoordinator()
    
    // MARK: - Published Properties
    
    /// Current star count - published for real-time updates across all views
    @Published var currentStarCount: Int = 0
    
    /// Current user level
    @Published var currentLevel: Int = 1
    
    /// Current accuracy percentage
    @Published var currentAccuracy: Double = 0.0
    
    /// Current streak
    @Published var currentStreak: Int = 0
    
    /// Total questions answered
    @Published var totalQuestionsAnswered: Int = 0
    
    /// Recently unlocked achievements
    @Published var recentAchievements: [Achievement] = []
    
    // MARK: - Private Properties
    
    private let achievementService: AchievementService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // Use the shared achievement service from DIContainer
        self.achievementService = DIContainer.shared.makeAchievementService()
        
        // Set up bindings to achievement service
        setupBindings()
        
        // Load initial data
        refreshData()
    }
    
    // MARK: - Public Methods
    
    /// Gets the current user progress
    var userProgress: UserGamificationProgress {
        return achievementService.userProgress
    }
    
    /// Records a quiz answer and updates all published properties
    func recordQuizAnswer(correct: Bool, points: Int, category: String, question: QuizQuestion) {
        achievementService.recordQuizAnswer(
            correct: correct,
            points: points,
            category: category,
            question: question
        )
        
        // Refresh all published properties
        refreshData()
        
        // Trigger achievements check
        checkForNewAchievements()
    }
    
    /// Refreshes all data from the achievement service
    func refreshData() {
        let progress = achievementService.userProgress
        
        currentStarCount = progress.totalPoints
        currentLevel = progress.level
        currentAccuracy = progress.accuracyPercentage
        currentStreak = progress.currentStreak
        totalQuestionsAnswered = progress.totalQuestionsAnswered
    }
    
    /// Gets unlocked achievements
    func getUnlockedAchievements() -> [Achievement] {
        return achievementService.getUnlockedAchievements()
    }
    
    /// Gets locked achievements
    func getLockedAchievements() -> [Achievement] {
        return achievementService.getLockedAchievements()
    }
    
    /// Gets progress for a specific achievement
    func getAchievementProgress(_ achievement: Achievement) -> Double {
        return achievementService.getAchievementProgress(achievement)
    }
    
    /// Clears recent achievements (after they've been shown)
    func clearRecentAchievements() {
        recentAchievements.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Monitor changes to the achievement service's user progress
        achievementService.$userProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.currentStarCount = progress.totalPoints
                self?.currentLevel = progress.level
                self?.currentAccuracy = progress.accuracyPercentage
                self?.currentStreak = progress.currentStreak
                self?.totalQuestionsAnswered = progress.totalQuestionsAnswered
            }
            .store(in: &cancellables)
        
        // Monitor for new achievements
        achievementService.$recentlyUnlockedAchievements
            .receive(on: DispatchQueue.main)
            .sink { [weak self] achievements in
                if !achievements.isEmpty {
                    self?.recentAchievements = achievements
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkForNewAchievements() {
        // This will be called by the achievement service automatically
        // We just need to refresh our local state
        recentAchievements = achievementService.recentlyUnlockedAchievements
    }
    
    // MARK: - Analytics and Metrics
    
    /// Gets comprehensive user stats for analytics
    func getUserStats() -> [String: Any] {
        let progress = userProgress
        
        return [
            "total_stars": progress.totalPoints,
            "current_level": progress.level,
            "accuracy_percentage": progress.accuracyPercentage,
            "current_streak": progress.currentStreak,
            "longest_streak": progress.longestStreak,
            "total_questions_answered": progress.totalQuestionsAnswered,
            "total_correct_answers": progress.totalCorrectAnswers,
            "achievements_unlocked": progress.unlockedAchievements.count,
            "last_quiz_date": progress.lastQuizDate?.timeIntervalSince1970 ?? 0
        ]
    }
} 