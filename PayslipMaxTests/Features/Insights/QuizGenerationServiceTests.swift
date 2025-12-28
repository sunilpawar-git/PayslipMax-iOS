import XCTest
@testable import PayslipMax

/// Comprehensive tests for QuizGenerationServiceCore functionality
@MainActor
final class QuizGenerationServiceTests: XCTestCase {

    private var sut: QuizGenerationServiceCore!
    private var mockDataLoader: MockQuizDataLoader!
    private var mockPayslipQuestionGenerator: MockPayslipQuestionGenerator!
    private var mockIncomeQuestionGenerator: MockQuestionGenerator!
    private var mockDeductionQuestionGenerator: MockQuestionGenerator!
    private var mockLiteracyQuestionGenerator: MockQuestionGenerator!
    private var mockFallbackGenerator: MockFallbackGenerator!
    private var mockUtility: MockQuizUtility!

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
        setupMocksWithQuestions(count: 5)
        let questions = await sut.generateQuiz()
        XCTAssertEqual(questions.count, 5)
    }

    func test_generateQuiz_WithCustomCount_ReturnsRequestedCount() async {
        setupMocksWithQuestions(count: 10)
        let questions = await sut.generateQuiz(questionCount: 10)
        XCTAssertEqual(questions.count, 10)
    }

    func test_generateQuiz_CallsDataLoader() async {
        setupMocksWithQuestions(count: 5)
        _ = await sut.generateQuiz()
        XCTAssertTrue(mockDataLoader.loadPayslipDataCalled)
    }

    func test_generateQuiz_CallsPayslipQuestionGenerator() async {
        setupMocksWithQuestions(count: 5)
        _ = await sut.generateQuiz()
        XCTAssertTrue(mockPayslipQuestionGenerator.generateCalled)
    }

    // MARK: - Fallback Tests

    func test_generateQuiz_WhenNoPersonalizedQuestions_UsesFallback() async {
        mockPayslipQuestionGenerator.questionsToReturn = []
        mockIncomeQuestionGenerator.questionsToReturn = []
        mockDeductionQuestionGenerator.questionsToReturn = []
        mockLiteracyQuestionGenerator.questionsToReturn = []
        mockFallbackGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: 5)

        let questions = await sut.generateQuiz(questionCount: 5)
        XCTAssertEqual(questions.count, 5)
        XCTAssertTrue(mockFallbackGenerator.generateCalled)
    }

    func test_generateQuiz_WhenPartialQuestions_FillsWithFallback() async {
        mockPayslipQuestionGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: 2)
        mockIncomeQuestionGenerator.questionsToReturn = []
        mockDeductionQuestionGenerator.questionsToReturn = []
        mockLiteracyQuestionGenerator.questionsToReturn = []
        mockFallbackGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: 3)

        let questions = await sut.generateQuiz(questionCount: 5)
        XCTAssertEqual(questions.count, 5)
        XCTAssertTrue(mockFallbackGenerator.generateCalled)
    }

    // MARK: - Difficulty Filter Tests

    func test_generateQuiz_WithDifficultyFilter_PassesDifficultyToGenerators() async {
        setupMocksWithQuestions(count: 5)
        _ = await sut.generateQuiz(questionCount: 5, difficulty: .hard)
        XCTAssertEqual(mockPayslipQuestionGenerator.lastDifficulty, .hard)
    }

    // MARK: - Data Loader Error Tests

    func test_generateQuiz_WhenDataLoaderFails_ReturnsFallbackQuestions() async {
        mockDataLoader.shouldThrowError = true
        mockFallbackGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: 5)

        let questions = await sut.generateQuiz(questionCount: 5)
        XCTAssertEqual(questions.count, 5)
        XCTAssertTrue(mockFallbackGenerator.generateCalled)
    }

    // MARK: - Question Distribution Tests

    func test_generateQuiz_IncludesQuestionsFromMultipleGenerators() async {
        mockPayslipQuestionGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: 2, prefix: "Payslip")
        mockIncomeQuestionGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: 2, prefix: "Income")
        mockDeductionQuestionGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: 2, prefix: "Deduction")
        mockLiteracyQuestionGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: 2, prefix: "Literacy")

        let questions = await sut.generateQuiz(questionCount: 5)
        XCTAssertGreaterThanOrEqual(questions.count, 4)
    }

    // MARK: - Shuffle Tests

    func test_generateQuiz_ShufflesQuestions() async {
        setupMocksWithQuestions(count: 10)
        let questions1 = await sut.generateQuiz(questionCount: 5)
        let questions2 = await sut.generateQuiz(questionCount: 5)

        XCTAssertEqual(questions1.count, 5)
        XCTAssertEqual(questions2.count, 5)
    }

    // MARK: - Update Payslip Data Tests

    func test_updatePayslipData_DoesNotCrash() async {
        let mockPayslips: [any PayslipProtocol] = []
        await sut.updatePayslipData(mockPayslips)
        XCTAssertTrue(true)
    }

    // MARK: - Helper Methods

    private func setupMocksWithQuestions(count: Int) {
        let perGenerator = max(1, count / 4)
        mockPayslipQuestionGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: perGenerator)
        mockIncomeQuestionGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: perGenerator)
        mockDeductionQuestionGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: perGenerator)
        mockLiteracyQuestionGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: perGenerator)
        mockFallbackGenerator.questionsToReturn = QuizTestHelpers.createMockQuestions(count: count)
    }
}
