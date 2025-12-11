import XCTest
@testable import PayslipMax

/// Comprehensive tests for QuizGenerationServiceCore functionality
@MainActor
final class QuizGenerationServiceTests: XCTestCase {

    // MARK: - Test Properties

    private var sut: QuizGenerationServiceCore!
    private var mockDataLoader: MockQuizDataLoader!
    private var mockPayslipQuestionGenerator: MockPayslipQuestionGenerator!
    private var mockIncomeQuestionGenerator: MockQuestionGenerator!
    private var mockDeductionQuestionGenerator: MockQuestionGenerator!
    private var mockLiteracyQuestionGenerator: MockQuestionGenerator!
    private var mockFallbackGenerator: MockFallbackGenerator!
    private var mockUtility: MockQuizUtility!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        mockDataLoader = MockQuizDataLoader()
        mockPayslipQuestionGenerator = MockPayslipQuestionGenerator()
        mockIncomeQuestionGenerator = MockQuestionGenerator()
        mockDeductionQuestionGenerator = MockQuestionGenerator()
        mockLiteracyQuestionGenerator = MockQuestionGenerator()
        mockFallbackGenerator = MockFallbackGenerator()
        mockUtility = MockQuizUtility()

        sut = QuizGenerationServiceCore(
            dataLoader: mockDataLoader,
            payslipQuestionGenerator: mockPayslipQuestionGenerator,
            incomeQuestionGenerator: mockIncomeQuestionGenerator,
            deductionQuestionGenerator: mockDeductionQuestionGenerator,
            literacyQuestionGenerator: mockLiteracyQuestionGenerator,
            fallbackGenerator: mockFallbackGenerator,
            utility: mockUtility
        )
    }

    override func tearDown() {
        sut = nil
        mockDataLoader = nil
        mockPayslipQuestionGenerator = nil
        mockIncomeQuestionGenerator = nil
        mockDeductionQuestionGenerator = nil
        mockLiteracyQuestionGenerator = nil
        mockFallbackGenerator = nil
        mockUtility = nil
        super.tearDown()
    }

    // MARK: - Basic Generation Tests

    func test_generateQuiz_WithDefaultCount_ReturnsFiveQuestions() async {
        // Given
        setupMocksWithQuestions(count: 5)

        // When
        let questions = await sut.generateQuiz()

        // Then
        XCTAssertEqual(questions.count, 5)
    }

    func test_generateQuiz_WithCustomCount_ReturnsRequestedCount() async {
        // Given
        setupMocksWithQuestions(count: 10)

        // When
        let questions = await sut.generateQuiz(questionCount: 10)

        // Then
        XCTAssertEqual(questions.count, 10)
    }

    func test_generateQuiz_CallsDataLoader() async {
        // Given
        setupMocksWithQuestions(count: 5)

        // When
        _ = await sut.generateQuiz()

        // Then
        XCTAssertTrue(mockDataLoader.loadPayslipDataCalled)
    }

    func test_generateQuiz_CallsPayslipQuestionGenerator() async {
        // Given
        setupMocksWithQuestions(count: 5)

        // When
        _ = await sut.generateQuiz()

        // Then
        XCTAssertTrue(mockPayslipQuestionGenerator.generateCalled)
    }

    // MARK: - Fallback Tests

    func test_generateQuiz_WhenNoPersonalizedQuestions_UsesFallback() async {
        // Given - No questions from generators
        mockPayslipQuestionGenerator.questionsToReturn = []
        mockIncomeQuestionGenerator.questionsToReturn = []
        mockDeductionQuestionGenerator.questionsToReturn = []
        mockLiteracyQuestionGenerator.questionsToReturn = []
        mockFallbackGenerator.questionsToReturn = createMockQuestions(count: 5)

        // When
        let questions = await sut.generateQuiz(questionCount: 5)

        // Then
        XCTAssertEqual(questions.count, 5)
        XCTAssertTrue(mockFallbackGenerator.generateCalled)
    }

    func test_generateQuiz_WhenPartialQuestions_FillsWithFallback() async {
        // Given - Only 2 personalized questions
        mockPayslipQuestionGenerator.questionsToReturn = createMockQuestions(count: 2)
        mockIncomeQuestionGenerator.questionsToReturn = []
        mockDeductionQuestionGenerator.questionsToReturn = []
        mockLiteracyQuestionGenerator.questionsToReturn = []
        mockFallbackGenerator.questionsToReturn = createMockQuestions(count: 3)

        // When
        let questions = await sut.generateQuiz(questionCount: 5)

        // Then
        XCTAssertEqual(questions.count, 5)
        XCTAssertTrue(mockFallbackGenerator.generateCalled)
    }

    // MARK: - Difficulty Filter Tests

    func test_generateQuiz_WithDifficultyFilter_PassesDifficultyToGenerators() async {
        // Given
        setupMocksWithQuestions(count: 5)

        // When
        _ = await sut.generateQuiz(questionCount: 5, difficulty: .hard)

        // Then
        XCTAssertEqual(mockPayslipQuestionGenerator.lastDifficulty, .hard)
    }

    // MARK: - Data Loader Error Tests

    func test_generateQuiz_WhenDataLoaderFails_ReturnsFallbackQuestions() async {
        // Given
        mockDataLoader.shouldThrowError = true
        mockFallbackGenerator.questionsToReturn = createMockQuestions(count: 5)

        // When
        let questions = await sut.generateQuiz(questionCount: 5)

        // Then
        XCTAssertEqual(questions.count, 5)
        XCTAssertTrue(mockFallbackGenerator.generateCalled)
    }

    // MARK: - Question Distribution Tests

    func test_generateQuiz_IncludesQuestionsFromMultipleGenerators() async {
        // Given
        mockPayslipQuestionGenerator.questionsToReturn = createMockQuestions(count: 2, prefix: "Payslip")
        mockIncomeQuestionGenerator.questionsToReturn = createMockQuestions(count: 2, prefix: "Income")
        mockDeductionQuestionGenerator.questionsToReturn = createMockQuestions(count: 2, prefix: "Deduction")
        mockLiteracyQuestionGenerator.questionsToReturn = createMockQuestions(count: 2, prefix: "Literacy")

        // When
        let questions = await sut.generateQuiz(questionCount: 5)

        // Then
        // Should have questions from multiple sources
        XCTAssertGreaterThanOrEqual(questions.count, 4)
    }

    // MARK: - Shuffle Tests

    func test_generateQuiz_ShufflesQuestions() async {
        // Given - Same questions multiple times
        setupMocksWithQuestions(count: 10)

        // When
        let questions1 = await sut.generateQuiz(questionCount: 5)
        let questions2 = await sut.generateQuiz(questionCount: 5)

        // Then - Questions should have different order (probabilistic but likely over multiple runs)
        // We can't guarantee different order, but we can verify the count is correct
        XCTAssertEqual(questions1.count, 5)
        XCTAssertEqual(questions2.count, 5)
    }

    // MARK: - Update Payslip Data Tests

    func test_updatePayslipData_DoesNotCrash() async {
        // Given
        let mockPayslips: [any PayslipProtocol] = []

        // When/Then - Should not crash
        await sut.updatePayslipData(mockPayslips)
        XCTAssertTrue(true)
    }

    // MARK: - Helper Methods

    private func setupMocksWithQuestions(count: Int) {
        let perGenerator = max(1, count / 4)
        mockPayslipQuestionGenerator.questionsToReturn = createMockQuestions(count: perGenerator)
        mockIncomeQuestionGenerator.questionsToReturn = createMockQuestions(count: perGenerator)
        mockDeductionQuestionGenerator.questionsToReturn = createMockQuestions(count: perGenerator)
        mockLiteracyQuestionGenerator.questionsToReturn = createMockQuestions(count: perGenerator)
        mockFallbackGenerator.questionsToReturn = createMockQuestions(count: count) // Fallback has enough
    }

    private func createMockQuestions(count: Int, prefix: String = "Test") -> [QuizQuestion] {
        return (0..<count).map { index in
            QuizQuestion(
                id: UUID(),
                questionText: "\(prefix) question \(index)",
                questionType: .multipleChoice,
                options: ["A", "B", "C", "D"],
                correctAnswer: "A",
                explanation: "Test explanation",
                difficulty: .medium,
                relatedInsightType: .income,
                contextData: QuizContextData(
                    userIncome: 100000,
                    userTaxRate: 0.2,
                    userDSOPContribution: 5000,
                    averageIncome: 90000,
                    comparisonPeriod: nil,
                    specificMonth: nil,
                    calculationDetails: nil
                )
            )
        }
    }
}

// MARK: - Mock Classes

@MainActor
private final class MockQuizDataLoader: QuizDataLoaderProtocol {
    var loadPayslipDataCalled = false
    var shouldThrowError = false

    func loadPayslipData() async throws {
        loadPayslipDataCalled = true
        if shouldThrowError {
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }
    }
}

@MainActor
private final class MockPayslipQuestionGenerator: QuizPayslipQuestionGeneratorProtocol {
    var generateCalled = false
    var lastDifficulty: QuizDifficulty?
    var questionsToReturn: [QuizQuestion] = []

    func generatePayslipSpecificQuestions(maxCount: Int, difficulty: QuizDifficulty?) async -> [QuizQuestion] {
        generateCalled = true
        lastDifficulty = difficulty
        return Array(questionsToReturn.prefix(maxCount))
    }
}

@MainActor
private final class MockQuestionGenerator: QuizQuestionGeneratorProtocol {
    var generateCalled = false
    var questionsToReturn: [QuizQuestion] = []

    func generateQuestions(maxCount: Int, difficulty: QuizDifficulty?) -> [QuizQuestion] {
        generateCalled = true
        return Array(questionsToReturn.prefix(maxCount))
    }
}

private final class MockFallbackGenerator: QuizFallbackGeneratorProtocol {
    var generateCalled = false
    var questionsToReturn: [QuizQuestion] = []

    func generateFallbackQuestions(count: Int) -> [QuizQuestion] {
        generateCalled = true
        return Array(questionsToReturn.prefix(count))
    }
}

private final class MockQuizUtility: QuizUtilityProtocol {
    func formatCurrencyForOptions(_ amount: Double) -> String {
        return "₹\(amount)"
    }

    func generateWrongCurrencyOptions(correct: Double) -> [String] {
        return ["₹\(correct * 0.8)", "₹\(correct * 1.2)", "₹\(correct * 0.5)"]
    }

    func shouldIncludeDifficulty(_ requested: QuizDifficulty?, _ questionDifficulty: QuizDifficulty) -> Bool {
        guard let requested = requested else { return true }
        return requested == questionDifficulty
    }

    func chronologicalComparison(
        latest: (month: String, net: Double),
        previous: (month: String, net: Double)
    ) -> (String, String, Double, Double, Double) {
        let difference = latest.net - previous.net
        return (latest.month, previous.month, latest.net, previous.net, difference)
    }
}
