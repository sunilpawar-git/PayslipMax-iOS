import XCTest
@testable import PayslipMax

/// Comprehensive tests for QuizViewModel functionality
@MainActor
final class QuizViewModelTests: XCTestCase {

    // MARK: - Test Properties

    private var sut: QuizViewModel!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Create ViewModel with protocol-based mock through dependency injection
        // Since QuizGenerationService is final, we test through the public interface
        sut = createQuizViewModelForTesting()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_IsNotLoading() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_HasNoError() {
        XCTAssertNil(sut.error)
    }

    func test_initialState_HasNoActiveSession() {
        XCTAssertNil(sut.currentSession)
        XCTAssertFalse(sut.hasActiveSession)
    }

    func test_initialState_ShowResultsIsFalse() {
        XCTAssertFalse(sut.showResults)
    }

    func test_initialState_CurrentQuestionIsNil() {
        XCTAssertNil(sut.currentQuestion)
    }

    func test_initialState_QuizProgressIsZero() {
        XCTAssertEqual(sut.quizProgress, 0.0)
    }

    // MARK: - Sheet Control Tests

    func test_presentQuizSheet_SetsShowQuizSheetTrue() {
        // When
        sut.presentQuizSheet()

        // Then
        XCTAssertTrue(sut.showQuizSheet)
    }

    func test_dismissQuizSheet_SetsShowQuizSheetFalse() {
        // Given
        sut.presentQuizSheet()
        XCTAssertTrue(sut.showQuizSheet)

        // When
        sut.dismissQuizSheet()

        // Then
        XCTAssertFalse(sut.showQuizSheet)
    }

    // MARK: - Achievement Celebration Tests

    func test_dismissAchievementCelebration_HidesCelebration() {
        // Given
        sut.showAchievementCelebration = true

        // When
        sut.dismissAchievementCelebration()

        // Then
        XCTAssertFalse(sut.showAchievementCelebration)
    }

    // MARK: - Options Tests

    func test_availableDifficulties_ReturnsAllCases() {
        XCTAssertEqual(sut.availableDifficulties, QuizDifficulty.allCases)
    }

    func test_recommendedQuestionCounts_ReturnsExpectedValues() {
        XCTAssertEqual(sut.recommendedQuestionCounts, [3, 5, 10, 15])
    }

    // MARK: - Analytics Tests

    func test_getQuizAnalytics_WithNoResults_ReturnsNil() {
        XCTAssertNil(sut.getQuizAnalytics())
    }

    func test_getOverallStats_ReturnsUserProgress() {
        // When
        let stats = sut.getOverallStats()

        // Then
        XCTAssertNotNil(stats["total_questions_answered"])
        XCTAssertNotNil(stats["total_correct_answers"])
        XCTAssertNotNil(stats["overall_accuracy"])
        XCTAssertNotNil(stats["current_streak"])
    }

    // MARK: - User Progress Tests

    func test_userProgress_ReturnsProgress() {
        // When
        let progress = sut.userProgress

        // Then
        XCTAssertNotNil(progress)
    }

    func test_recentAchievements_ReturnsArray() {
        // When
        let achievements = sut.recentAchievements

        // Then
        XCTAssertNotNil(achievements)
    }

    // MARK: - End Quiz Tests

    func test_endQuiz_ClearsState() {
        // Given - Setup some state
        sut.showAchievementCelebration = true
        sut.presentQuizSheet()

        // When
        sut.endQuiz()

        // Then
        XCTAssertNil(sut.currentSession)
        XCTAssertFalse(sut.showResults)
        XCTAssertFalse(sut.showQuizSheet)
        XCTAssertFalse(sut.showAchievementCelebration)
        XCTAssertNil(sut.lastResults)
        XCTAssertNil(sut.error)
    }

    // MARK: - Submit Answer Without Session Tests

    func test_submitAnswer_WithNoSession_DoesNotCrash() {
        // Given - no session
        XCTAssertNil(sut.currentSession)

        // When/Then - should not crash
        sut.submitAnswer("A")
        XCTAssertNil(sut.currentSession)
    }

    // MARK: - Advance Question Without Session Tests

    func test_advanceToNextQuestion_WithNoSession_DoesNotCrash() {
        // Given - no session
        XCTAssertNil(sut.currentSession)

        // When/Then - should not crash
        sut.advanceToNextQuestion()
        XCTAssertNil(sut.currentSession)
    }

    // MARK: - Computed Properties Tests

    func test_totalQuestions_WithNoSession_ReturnsZero() {
        XCTAssertEqual(sut.totalQuestions, 0)
    }

    func test_currentQuestionNumber_WithNoSession_ReturnsZero() {
        XCTAssertEqual(sut.currentQuestionNumber, 0)
    }

    // MARK: - Helper Methods

    private func createQuizViewModelForTesting() -> QuizViewModel {
        // Create necessary ViewModels (lightweight, no side effects)
        let financialSummaryVM = FinancialSummaryViewModel()
        let trendAnalysisVM = TrendAnalysisViewModel()
        let chartDataVM = ChartDataViewModel()

        // Use shared mock repository
        let repository = MockPayslipRepository()

        // Create the quiz generation service with mocked repository
        let quizService = QuizGenerationService(
            financialSummaryViewModel: financialSummaryVM,
            trendAnalysisViewModel: trendAnalysisVM,
            chartDataViewModel: chartDataVM,
            repository: repository
        )

        // Create the achievement service
        let achievementService = AchievementService()

        return QuizViewModel(
            quizGenerationService: quizService,
            achievementService: achievementService
        )
    }
}

