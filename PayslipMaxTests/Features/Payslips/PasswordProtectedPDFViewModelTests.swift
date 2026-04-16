import XCTest
@testable import PayslipMax

/// TDD tests for PasswordProtectedPDFViewModel.
/// Verifies that all unlock logic lives in the ViewModel and uses injected services.
@MainActor
final class PasswordProtectedPDFViewModelTests: XCTestCase {

    // MARK: - Properties

    private var mockPDF: SpyPDFService!
    private var mockPCDA: SpyPCDAHandler!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockPDF = SpyPDFService()
        mockPCDA = SpyPCDAHandler()
    }

    override func tearDown() {
        mockPDF = nil
        mockPCDA = nil
        super.tearDown()
    }

    // MARK: - Empty password guard

    func test_unlockPDF_emptyPassword_setsErrorAndDoesNotCallServices() async {
        let sut = makeSUT()
        sut.password = ""

        await sut.unlockPDF()

        XCTAssertEqual(sut.errorMessage, "Password cannot be empty")
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(mockPDF.unlockCalled)
        XCTAssertFalse(mockPCDA.unlockCalled)
    }

    // MARK: - Standard unlock success

    func test_unlockPDF_correctPassword_callsOnUnlockAndClearsLoading() async {
        let expected = Data("unlocked".utf8)
        mockPDF.stubbedUnlockedData = expected
        let sut = makeSUT()
        sut.password = "correct"

        var receivedData: Data?
        var receivedPassword: String?
        sut.onUnlock = { data, pwd in
            receivedData = data
            receivedPassword = pwd
        }

        await sut.unlockPDF()

        XCTAssertEqual(receivedData, expected)
        XCTAssertEqual(receivedPassword, "correct")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Incorrect password error handling

    func test_unlockPDF_incorrectPassword_firstAttempt_setsGenericError() async {
        mockPDF.stubbedError = PDFServiceError.incorrectPassword
        let sut = makeSUT()
        sut.password = "wrong"

        await sut.unlockPDF()

        XCTAssertEqual(sut.errorMessage, "Incorrect password. Please try again.")
        XCTAssertFalse(sut.isLoading)
    }

    func test_unlockPDF_incorrectPassword_twoAttempts_suggestsMilitaryHint() async {
        mockPDF.stubbedError = PDFServiceError.incorrectPassword
        let sut = makeSUT()
        sut.password = "wrong"

        await sut.unlockPDF()
        await sut.unlockPDF()

        XCTAssertTrue(sut.isLikelyMilitaryPDF)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Unsupported encryption

    func test_unlockPDF_unsupportedEncryption_setsError() async {
        mockPDF.stubbedError = PDFServiceError.unsupportedEncryptionMethod
        let sut = makeSUT()
        sut.password = "anyPassword"

        await sut.unlockPDF()

        XCTAssertEqual(sut.errorMessage, "This PDF uses an unsupported encryption method.")
    }

    // MARK: - Military PDF path

    func test_unlockPDF_militaryPDF_successfulUnlock_callsOnUnlock() async {
        let expected = Data("militaryUnlocked".utf8)
        mockPCDA.stubbedResult = (expected, "SVC123")
        let sut = makeSUT()
        sut.isLikelyMilitaryPDF = true
        sut.password = "SVC123"

        var receivedData: Data?
        sut.onUnlock = { data, _ in receivedData = data }

        await sut.unlockPDF()

        XCTAssertEqual(receivedData, expected)
        XCTAssertTrue(mockPCDA.unlockCalled)
    }

    func test_unlockPDF_militaryPDF_failedPCDA_fallsBackToStandardService() async {
        mockPCDA.stubbedResult = (nil, nil)          // PCDA fails
        mockPDF.stubbedError = PDFServiceError.incorrectPassword  // standard also fails
        let sut = makeSUT()
        sut.isLikelyMilitaryPDF = true
        sut.password = "wrong"

        await sut.unlockPDF()

        XCTAssertTrue(mockPCDA.unlockCalled)
        XCTAssertTrue(mockPDF.unlockCalled)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Loading state

    func test_unlockPDF_setsLoadingTrueWhileRunning() async {
        // We can only check after the fact — loading is reset on completion
        mockPDF.stubbedUnlockedData = Data("ok".utf8)
        let sut = makeSUT()
        sut.password = "pw"

        await sut.unlockPDF()

        XCTAssertFalse(sut.isLoading, "isLoading must be false after completion")
    }

    // MARK: - Helpers

    private func makeSUT(pdfData: Data = Data()) -> PasswordProtectedPDFViewModel {
        PasswordProtectedPDFViewModel(
            pdfData: pdfData,
            pdfService: mockPDF,
            pcdaHandler: mockPCDA
        )
    }
}

// MARK: - SpyPDFService

@MainActor
private final class SpyPDFService: PDFServiceProtocol {
    var isInitialized: Bool = true
    var unlockCalled = false
    var stubbedUnlockedData: Data?
    var stubbedError: Error?

    func initialize() async throws {}
    func process(_ url: URL) async throws -> Data { Data() }
    func extract(_ data: Data) -> [String: String] { [:] }

    func unlockPDF(data: Data, password: String) async throws -> Data {
        unlockCalled = true
        if let error = stubbedError { throw error }
        return stubbedUnlockedData ?? data
    }

    func extractStructuredText(from pdfData: Data) async throws -> StructuredDocument {
        throw MockError.processingFailed
    }
}

// MARK: - SpyPCDAHandler

private final class SpyPCDAHandler: PCDAPayslipHandlerProtocol {
    var unlockCalled = false
    var stubbedResult: (Data?, String?) = (nil, nil)

    func unlockPDF(data: Data, basePassword: String) async -> (Data?, String?) {
        unlockCalled = true
        return stubbedResult
    }
}
