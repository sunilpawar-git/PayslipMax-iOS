import XCTest
@testable import PayslipMax

/// Tests for AchievementService core functionality
@MainActor
final class AchievementServiceTests: XCTestCase {

    private var sut: AchievementService!
    private var mockDefinitionsService: MockAchievementDefinitionsService!
    private var mockValidationService: MockAchievementValidationService!
    private var mockProgressCalculator: MockAchievementProgressCalculator!
    private var mockPersistenceService: MockAchievementPersistenceService!

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
        XCTAssertFalse(sut.availableAchievements.isEmpty)
        XCTAssertTrue(mockDefinitionsService.getDefaultAchievementsCalled)
    }

    func test_init_LoadsUserProgress() {
        let savedProgress = UserGamificationProgress()
        mockPersistenceService.savedProgress = savedProgress

        let newSut = AchievementService(
            definitionsService: mockDefinitionsService,
            validationService: mockValidationService,
            progressCalculator: mockProgressCalculator,
            persistenceService: mockPersistenceService
        )

        XCTAssertTrue(mockPersistenceService.loadUserProgressCalled)
        XCTAssertNotNil(newSut.userProgress)
    }

    // MARK: - Record Quiz Answer Tests

    func test_recordQuizAnswer_UpdatesUserProgress() {
        let question = AchievementTestHelpers.createMockQuestion()
        let initialTotal = sut.userProgress.totalQuestionsAnswered

        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)

        XCTAssertEqual(sut.userProgress.totalQuestionsAnswered, initialTotal + 1)
    }

    func test_recordQuizAnswer_CorrectAnswer_IncrementsCorrectCount() {
        let question = AchievementTestHelpers.createMockQuestion()
        let initialCorrect = sut.userProgress.totalCorrectAnswers

        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)

        XCTAssertEqual(sut.userProgress.totalCorrectAnswers, initialCorrect + 1)
    }

    func test_recordQuizAnswer_IncorrectAnswer_DoesNotIncrementCorrectCount() {
        let question = AchievementTestHelpers.createMockQuestion()
        let initialCorrect = sut.userProgress.totalCorrectAnswers

        sut.recordQuizAnswer(correct: false, points: 0, category: "income", question: question)

        XCTAssertEqual(sut.userProgress.totalCorrectAnswers, initialCorrect)
    }

    func test_recordQuizAnswer_SavesProgress() {
        let question = AchievementTestHelpers.createMockQuestion()
        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)
        XCTAssertTrue(mockPersistenceService.saveUserProgressCalled)
    }

    func test_recordQuizAnswer_ChecksForNewAchievements() {
        let question = AchievementTestHelpers.createMockQuestion()
        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)
        XCTAssertTrue(mockValidationService.checkForNewAchievementsCalled)
    }

    func test_recordQuizAnswer_WhenAchievementUnlocked_AddsToRecentlyUnlocked() {
        let question = AchievementTestHelpers.createMockQuestion()
        let newAchievement = AchievementTestHelpers.createMockAchievement(title: "First Answer")
        mockValidationService.achievementsToReturn = [newAchievement]

        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)

        XCTAssertFalse(sut.recentlyUnlockedAchievements.isEmpty)
        XCTAssertTrue(sut.recentlyUnlockedAchievements.contains { $0.title == "First Answer" })
    }

    func test_recordQuizAnswer_WhenAchievementUnlocked_AddsPointsToProgress() {
        let question = AchievementTestHelpers.createMockQuestion()
        let newAchievement = AchievementTestHelpers.createMockAchievement(title: "Bonus", pointsReward: 50)
        mockValidationService.achievementsToReturn = [newAchievement]
        let initialPoints = sut.userProgress.totalPoints

        sut.recordQuizAnswer(correct: true, points: 10, category: "income", question: question)

        XCTAssertEqual(sut.userProgress.totalPoints, initialPoints + 60)
    }

    // MARK: - Get Achievements Tests

    func test_getUnlockedAchievements_ReturnsOnlyUnlocked() {
        let achievement1 = AchievementTestHelpers.createMockAchievement(title: "Achievement 1")
        let achievement2 = AchievementTestHelpers.createMockAchievement(title: "Achievement 2")
        mockDefinitionsService.defaultAchievements = [achievement1, achievement2]

        sut = AchievementService(
            definitionsService: mockDefinitionsService,
            validationService: mockValidationService,
            progressCalculator: mockProgressCalculator,
            persistenceService: mockPersistenceService
        )
        sut.userProgress.unlockedAchievements.append(achievement1.id)

        let unlocked = sut.getUnlockedAchievements()
        XCTAssertEqual(unlocked.count, 1)
        XCTAssertTrue(unlocked.allSatisfy { $0.isUnlocked })
    }

    func test_getLockedAchievements_ReturnsOnlyLocked() {
        let achievement1 = AchievementTestHelpers.createMockAchievement(title: "Achievement 1")
        let achievement2 = AchievementTestHelpers.createMockAchievement(title: "Achievement 2")
        mockDefinitionsService.defaultAchievements = [achievement1, achievement2]

        sut = AchievementService(
            definitionsService: mockDefinitionsService,
            validationService: mockValidationService,
            progressCalculator: mockProgressCalculator,
            persistenceService: mockPersistenceService
        )
        sut.userProgress.unlockedAchievements.append(achievement1.id)

        let locked = sut.getLockedAchievements()
        XCTAssertEqual(locked.count, 1)
        XCTAssertTrue(locked.allSatisfy { $0.title == "Achievement 2" })
    }

    func test_getAchievementProgress_DelegatesToCalculator() {
        let achievement = AchievementTestHelpers.createMockAchievement()
        mockProgressCalculator.progressToReturn = 0.75

        let progress = sut.getAchievementProgress(achievement)
        XCTAssertEqual(progress, 0.75, accuracy: 0.01)
        XCTAssertTrue(mockProgressCalculator.calculateProgressCalled)
    }

    // MARK: - Reset Progress Tests

    func test_resetProgress_ClearsUserProgress() {
        sut.userProgress.totalQuestionsAnswered = 100
        sut.userProgress.totalCorrectAnswers = 90

        sut.resetProgress()

        XCTAssertEqual(sut.userProgress.totalQuestionsAnswered, 0)
        XCTAssertEqual(sut.userProgress.totalCorrectAnswers, 0)
    }

    func test_resetProgress_ClearsRecentlyUnlocked() {
        sut.recentlyUnlockedAchievements = [AchievementTestHelpers.createMockAchievement()]
        sut.resetProgress()
        XCTAssertTrue(sut.recentlyUnlockedAchievements.isEmpty)
    }

    func test_resetProgress_CallsPersistenceReset() {
        sut.resetProgress()
        XCTAssertTrue(mockPersistenceService.resetProgressCalled)
    }
}
