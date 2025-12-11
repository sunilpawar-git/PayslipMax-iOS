import XCTest
@testable import PayslipMax

/// Comprehensive tests for AchievementService functionality including progress tracking and badge unlocking
@MainActor
final class AchievementServiceTests: XCTestCase {

    // MARK: - Test Properties

    private var sut: AchievementService!
    private var mockDefinitionsService: MockAchievementDefinitionsService!
    private var mockValidationService: MockAchievementValidationService!
    private var mockProgressCalculator: MockAchievementProgressCalculator!
    private var mockPersistenceService: MockAchievementPersistenceService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        mockDefinitionsService = MockAchievementDefinitionsService()
        mockValidationService = MockAchievementValidationService()
        mockProgressCalculator = MockAchievementProgressCalculator()
        mockPersistenceService = MockAchievementPersistenceService()

        sut = AchievementService(
            definitionsService: mockDefinitionsService,
            validationService: mockValidationService,
            progressCalculator: mockProgressCalculator,
            persistenceService: mockPersistenceService
        )
    }

    override func tearDown() {
        sut = nil
        mockDefinitionsService = nil
        mockValidationService = nil
        mockProgressCalculator = nil
        mockPersistenceService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_LoadsDefaultAchievements() {
        // Then
        XCTAssertFalse(sut.availableAchievements.isEmpty)
        XCTAssertTrue(mockDefinitionsService.getDefaultAchievementsCalled)
    }

    func test_init_LoadsUserProgress() {
        // Given
        let savedProgress = UserGamificationProgress()
        mockPersistenceService.savedProgress = savedProgress

        // When - Create new instance with saved progress
        let newSut = AchievementService(
            definitionsService: mockDefinitionsService,
            validationService: mockValidationService,
            progressCalculator: mockProgressCalculator,
            persistenceService: mockPersistenceService
        )

        // Then
        XCTAssertTrue(mockPersistenceService.loadUserProgressCalled)
        XCTAssertNotNil(newSut.userProgress)
    }

    // MARK: - Record Quiz Answer Tests

    func test_recordQuizAnswer_UpdatesUserProgress() {
        // Given
        let question = createMockQuestion()
        let initialTotal = sut.userProgress.totalQuestionsAnswered

        // When
        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)

        // Then
        XCTAssertEqual(sut.userProgress.totalQuestionsAnswered, initialTotal + 1)
    }

    func test_recordQuizAnswer_CorrectAnswer_IncrementsCorrectCount() {
        // Given
        let question = createMockQuestion()
        let initialCorrect = sut.userProgress.totalCorrectAnswers

        // When
        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)

        // Then
        XCTAssertEqual(sut.userProgress.totalCorrectAnswers, initialCorrect + 1)
    }

    func test_recordQuizAnswer_IncorrectAnswer_DoesNotIncrementCorrectCount() {
        // Given
        let question = createMockQuestion()
        let initialCorrect = sut.userProgress.totalCorrectAnswers

        // When
        sut.recordQuizAnswer(correct: false, points: 0, category: "income", question: question)

        // Then
        XCTAssertEqual(sut.userProgress.totalCorrectAnswers, initialCorrect)
    }

    func test_recordQuizAnswer_SavesProgress() {
        // Given
        let question = createMockQuestion()

        // When
        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)

        // Then
        XCTAssertTrue(mockPersistenceService.saveUserProgressCalled)
    }

    func test_recordQuizAnswer_ChecksForNewAchievements() {
        // Given
        let question = createMockQuestion()

        // When
        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)

        // Then
        XCTAssertTrue(mockValidationService.checkForNewAchievementsCalled)
    }

    func test_recordQuizAnswer_WhenAchievementUnlocked_AddsToRecentlyUnlocked() {
        // Given
        let question = createMockQuestion()
        let newAchievement = createMockAchievement(title: "First Answer")
        mockValidationService.achievementsToReturn = [newAchievement]

        // When
        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)

        // Then
        XCTAssertFalse(sut.recentlyUnlockedAchievements.isEmpty)
        XCTAssertTrue(sut.recentlyUnlockedAchievements.contains { $0.title == "First Answer" })
    }

    func test_recordQuizAnswer_WhenAchievementUnlocked_AddsPointsToProgress() {
        // Given
        let question = createMockQuestion()
        let newAchievement = createMockAchievement(title: "Bonus", pointsReward: 50)
        mockValidationService.achievementsToReturn = [newAchievement]
        let initialPoints = sut.userProgress.totalPoints

        // When
        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)

        // Then - points include question points (10) + achievement bonus (50)
        XCTAssertEqual(sut.userProgress.totalPoints, initialPoints + 60)
    }


    // MARK: - Get Unlocked Achievements Tests

    func test_getUnlockedAchievements_ReturnsOnlyUnlocked() {
        // Given
        let achievement1 = createMockAchievement(title: "Achievement 1")
        let achievement2 = createMockAchievement(title: "Achievement 2")
        mockDefinitionsService.defaultAchievements = [achievement1, achievement2]

        // Reset sut with new definitions
        sut = AchievementService(
            definitionsService: mockDefinitionsService,
            validationService: mockValidationService,
            progressCalculator: mockProgressCalculator,
            persistenceService: mockPersistenceService
        )

        // Simulate unlocking achievement 1
        sut.userProgress.unlockedAchievements.append(achievement1.id)

        // When
        let unlocked = sut.getUnlockedAchievements()

        // Then
        XCTAssertEqual(unlocked.count, 1)
        XCTAssertTrue(unlocked.allSatisfy { $0.isUnlocked })
    }

    // MARK: - Get Locked Achievements Tests

    func test_getLockedAchievements_ReturnsOnlyLocked() {
        // Given
        let achievement1 = createMockAchievement(title: "Achievement 1")
        let achievement2 = createMockAchievement(title: "Achievement 2")
        mockDefinitionsService.defaultAchievements = [achievement1, achievement2]

        // Reset sut with new definitions
        sut = AchievementService(
            definitionsService: mockDefinitionsService,
            validationService: mockValidationService,
            progressCalculator: mockProgressCalculator,
            persistenceService: mockPersistenceService
        )

        // Simulate unlocking only achievement 1
        sut.userProgress.unlockedAchievements.append(achievement1.id)

        // When
        let locked = sut.getLockedAchievements()

        // Then
        XCTAssertEqual(locked.count, 1)
        XCTAssertTrue(locked.allSatisfy { $0.title == "Achievement 2" })
    }

    // MARK: - Get Achievement Progress Tests

    func test_getAchievementProgress_DelegatesToCalculator() {
        // Given
        let achievement = createMockAchievement()
        mockProgressCalculator.progressToReturn = 0.75

        // When
        let progress = sut.getAchievementProgress(achievement)

        // Then
        XCTAssertEqual(progress, 0.75, accuracy: 0.01)
        XCTAssertTrue(mockProgressCalculator.calculateProgressCalled)
    }

    // MARK: - Reset Progress Tests

    func test_resetProgress_ClearsUserProgress() {
        // Given
        sut.userProgress.totalQuestionsAnswered = 100
        sut.userProgress.totalCorrectAnswers = 90

        // When
        sut.resetProgress()

        // Then
        XCTAssertEqual(sut.userProgress.totalQuestionsAnswered, 0)
        XCTAssertEqual(sut.userProgress.totalCorrectAnswers, 0)
    }

    func test_resetProgress_ClearsRecentlyUnlocked() {
        // Given
        sut.recentlyUnlockedAchievements = [createMockAchievement()]

        // When
        sut.resetProgress()

        // Then
        XCTAssertTrue(sut.recentlyUnlockedAchievements.isEmpty)
    }

    func test_resetProgress_CallsPersistenceReset() {
        // When
        sut.resetProgress()

        // Then
        XCTAssertTrue(mockPersistenceService.resetProgressCalled)
    }

    // MARK: - Helper Methods

    private func createMockQuestion() -> QuizQuestion {
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

    private func createMockAchievement(
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

private final class MockAchievementDefinitionsService: AchievementDefinitionsServiceProtocol {
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
                    requirement: AchievementRequirement(type: .questionsAnswered, threshold: 1, category: nil),
                    pointsReward: 10
                )
            ]
        }
        return defaultAchievements
    }
}

private final class MockAchievementValidationService: AchievementValidationServiceProtocol {
    var checkForNewAchievementsCalled = false
    var achievementsToReturn: [Achievement] = []

    func checkForNewAchievements(
        availableAchievements: [Achievement],
        userProgress: UserGamificationProgress
    ) -> [Achievement] {
        checkForNewAchievementsCalled = true
        return achievementsToReturn
    }

    func isAchievementUnlocked(_ achievement: Achievement, userProgress: UserGamificationProgress) -> Bool {
        return userProgress.unlockedAchievements.contains(achievement.id)
    }
}


private final class MockAchievementProgressCalculator: AchievementProgressCalculatorProtocol {
    var calculateProgressCalled = false
    var progressToReturn: Double = 0.0

    func calculateProgress(for achievement: Achievement, userProgress: UserGamificationProgress) -> Double {
        calculateProgressCalled = true
        return progressToReturn
    }
}

private final class MockAchievementPersistenceService: AchievementPersistenceServiceProtocol {
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
