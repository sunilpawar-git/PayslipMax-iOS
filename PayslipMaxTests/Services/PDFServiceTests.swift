import XCTest
@testable import PayslipMax

class TestPDFService: PDFService {
    // MARK: - Properties
    private var testData: [String: String]
    private var militaryStatus: Bool
    private var passwordProtected: Bool
    private var password: String?

    var fileType: PDFFileType {
        return militaryStatus ? .military : .standard
    }

    // MARK: - Initialization
    init(testData: [String: String] = [:],
         militaryStatus: Bool = false,
         passwordProtected: Bool = false,
         password: String? = nil) {
        self.testData = testData
        self.militaryStatus = militaryStatus
        self.passwordProtected = passwordProtected
        self.password = password
    }

    // MARK: - PDFService Protocol Methods
    func extract(_ pdfData: Data) -> [String: String] {
        guard let content = String(data: pdfData, encoding: .utf8) else {
            return [:]
        }

        if PDFTestHelpers.isMilitaryPDF(pdfData) {
            militaryStatus = true
            return PDFTestHelpers.extractTestData(content)
        }

        if PDFTestHelpers.isPasswordProtected(pdfData) {
            return [:]
        }

        return PDFTestHelpers.extractTestData(content)
    }

    func unlockPDF(data: Data, password: String) async throws -> Data {
        if militaryStatus {
            throw PDFServiceError.militaryPDFNotSupported
        }

        guard PDFTestHelpers.isPasswordProtected(data) else {
            throw PDFServiceError.unableToProcessPDF
        }

        guard let correctPassword = PDFTestHelpers.getPasswordFromProtectedPDF(data),
              password == correctPassword else {
            throw PDFServiceError.incorrectPassword
        }

        // Remove password protection and return the content
        let content = String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "\(PDFTestHelpers.passwordProtectedMarker)\nPassword: \(password)\n", with: "") ?? ""
        return content.data(using: .utf8) ?? Data()
    }

    func extractStructuredText(from pdfData: Data) async throws -> StructuredDocument {
        // Extract basic text data first
        let textData = extract(pdfData)

        // Create a simple structured page
        let structuredPage = StructuredPage(
            text: textData.values.joined(separator: " "),
            bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8),
            elements: [],
            pageIndex: 0,
            metadata: [:]
        )

        // Create structured document
        return StructuredDocument(
            pages: [structuredPage],
            metadata: textData,
            processingDuration: 0.1
        )
    }
}

class PDFServiceTests: XCTestCase {
    var sut: TestPDFService!

    override func setUp() {
        super.setUp()
        sut = TestPDFService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Test Cases

    func testExtractFromStandardPDF() {
        // Given
        let pdfData = PDFTestHelpers.createStandardPDF()

        // When
        let result = sut.extract(pdfData)

        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result["name"], "John Doe")
        XCTAssertEqual(result["month"], "April")
        XCTAssertEqual(result["year"], "2023")
        XCTAssertEqual(result["grossPay"], "5000.00")
    }

    func testExtractFromMilitaryPDF() {
        // Given
        let pdfData = PDFTestHelpers.createMilitaryPDF()

        // When
        let result = sut.extract(pdfData)

        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(sut.fileType, .military)
        XCTAssertEqual(result["name"], "John Doe")
        XCTAssertEqual(result["accountNumber"], "9876543210")
    }

    func testExtractFromPasswordProtectedPDF() {
        // Given
        let pdfData = PDFTestHelpers.createPasswordProtectedPDF()

        // When
        let result = sut.extract(pdfData)

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testUnlockPDFWithCorrectPassword() async throws {
        // Given
        let password = "test123"
        let pdfData = PDFTestHelpers.createPasswordProtectedPDF(password: password)

        // When
        let unlockedData = try await sut.unlockPDF(data: pdfData, password: password)
        let result = sut.extract(unlockedData)

        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result["name"], "John Doe")
        XCTAssertEqual(result["month"], "April")
    }

    func testUnlockPDFWithIncorrectPassword() async {
        // Given
        let pdfData = PDFTestHelpers.createPasswordProtectedPDF(password: "test123")

        // When/Then
        do {
            _ = try await sut.unlockPDF(data: pdfData, password: "wrongpass")
            XCTFail("Expected error to be thrown")
        } catch PDFServiceError.incorrectPassword {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnlockNonPasswordProtectedPDF() async {
        // Given
        let pdfData = PDFTestHelpers.createStandardPDF()

        // When/Then
        do {
            _ = try await sut.unlockPDF(data: pdfData, password: "test123")
            XCTFail("Expected error to be thrown")
        } catch PDFServiceError.unableToProcessPDF {
            // Success - standard PDFs are not password protected, so should fail with unableToProcessPDF
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnlockMilitaryPDF() async {
        // Given
        let pdfData = PDFTestHelpers.createMilitaryPDF()
        sut = TestPDFService(militaryStatus: true)

        // When/Then
        do {
            _ = try await sut.unlockPDF(data: pdfData, password: "test123")
            XCTFail("Expected error to be thrown")
        } catch PDFServiceError.militaryPDFNotSupported {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExtractFromMalformedPDF() {
        // Given
        let pdfData = PDFTestHelpers.createMalformedPDF()

        // When
        let result = sut.extract(pdfData)

        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result["name"], "Jane Smith")
    }
}
