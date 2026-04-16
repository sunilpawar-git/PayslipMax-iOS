import XCTest
import PDFKit
@testable import PayslipMax

/// TDD tests for PDFParsingFeedbackViewModel.displayEarnings.
/// Verifies the ViewModel uses injected PayslipDisplayNameServiceProtocol
/// instead of accessing DIContainer directly from the View body.
@MainActor
final class PDFParsingFeedbackViewModelTests: XCTestCase {

    // MARK: - displayEarnings delegates to injected service

    func test_displayEarnings_usesInjectedDisplayNameService() {
        let mockService = MockPayslipDisplayNameService()
        mockService.stubbedDisplayEarnings = [
            (displayName: "Basic Pay", value: 50_000, originalKey: "BPAY"),
            (displayName: "DA", value: 10_000, originalKey: "DA")
        ]
        let sut = makeSUT(displayNameService: mockService)

        let result = sut.displayEarnings

        XCTAssertTrue(mockService.getDisplayEarningsCalled, "Should delegate to injected service")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.displayName, "Basic Pay")
    }

    func test_displayEarnings_emptyEarnings_returnsEmpty() {
        let mockService = MockPayslipDisplayNameService()
        mockService.stubbedDisplayEarnings = []
        let sut = makeSUT(displayNameService: mockService, earnings: [:])

        XCTAssertTrue(sut.displayEarnings.isEmpty)
    }

    // MARK: - displayDeductions delegates to injected service

    func test_displayDeductions_usesInjectedDisplayNameService() {
        let mockService = MockPayslipDisplayNameService()
        mockService.stubbedDisplayDeductions = [
            (displayName: "Income Tax", value: 8_000, originalKey: "ITAX")
        ]
        let sut = makeSUT(displayNameService: mockService)

        let result = sut.displayDeductions

        XCTAssertTrue(mockService.getDisplayDeductionsCalled)
        XCTAssertEqual(result.first?.displayName, "Income Tax")
    }

    // MARK: - Helpers

    private func makeSUT(
        displayNameService: PayslipDisplayNameServiceProtocol? = nil,
        earnings: [String: Double] = ["BPAY": 50_000],
        deductions: [String: Double] = ["ITAX": 8_000]
    ) -> PDFParsingFeedbackViewModel {
        let payslip = PayslipItem(
            month: "January", year: 2025,
            credits: 50_000, debits: 8_000,
            dsop: 0, tax: 8_000,
            earnings: earnings, deductions: deductions
        )
        return PDFParsingFeedbackViewModel(
            payslipItem: payslip,
            pdfDocument: PDFDocument(),
            parsingCoordinator: MockPDFParsingCoordinator(),
            abbreviationManager: AbbreviationManager(),
            dataService: MockDataService(),
            displayNameService: displayNameService
        )
    }
}

// MARK: - MockPayslipDisplayNameService

final class MockPayslipDisplayNameService: PayslipDisplayNameServiceProtocol {
    var getDisplayEarningsCalled = false
    var getDisplayDeductionsCalled = false
    var stubbedDisplayEarnings: [(displayName: String, value: Double, originalKey: String)] = []
    var stubbedDisplayDeductions: [(displayName: String, value: Double, originalKey: String)] = []

    func getDisplayName(for internalKey: String) -> String { internalKey }

    func getDisplayEarnings(from earnings: [String: Double]) -> [(displayName: String, value: Double, originalKey: String)] {
        getDisplayEarningsCalled = true
        return stubbedDisplayEarnings
    }

    func getDisplayDeductions(from deductions: [String: Double]) -> [(displayName: String, value: Double, originalKey: String)] {
        getDisplayDeductionsCalled = true
        return stubbedDisplayDeductions
    }
}

// MARK: - MockPDFParsingCoordinator

private final class MockPDFParsingCoordinator: PDFParsingCoordinatorProtocol {
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipDTO? { nil }
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) async throws -> PayslipDTO? { nil }
    func selectBestParser(for text: String) -> PayslipParser? { nil }
    func extractFullText(from document: PDFDocument) -> String? { nil }
    func getAvailableParsers() -> [PayslipParser] { [] }
}
