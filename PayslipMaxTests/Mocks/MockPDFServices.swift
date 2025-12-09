import Foundation
import PDFKit
@testable import PayslipMax

/// Mock PDF service for testing
/// Implements PDFServiceProtocol with configurable failure modes
/// Follows SOLID principles with single responsibility for PDF service mocking
public class MockPDFService: PDFServiceProtocol {
    public var isInitialized: Bool = true
    public var shouldFailProcessing = false

    public func initialize() async throws {
        if shouldFailProcessing { throw MockError.initializationFailed }
        isInitialized = true
    }

    public func process(_ url: URL) async throws -> Data {
        if shouldFailProcessing { throw MockError.processingFailed }
        return Data("Mock processed data".utf8)
    }

    public func extract(_ data: Data) -> [String: String] {
        if shouldFailProcessing { return [:] }
        return ["credits": "5000", "debits": "1000", "name": "Mock Employee"]
    }

    public func unlockPDF(data: Data, password: String) async throws -> Data {
        if shouldFailProcessing { throw MockError.processingFailed }
        return data // Return unlocked data
    }
}

/// Mock PDF extractor for testing
/// Implements PDFExtractorProtocol with configurable failure modes
/// Follows SOLID principles with single responsibility for PDF extraction mocking
public class MockPDFExtractor: PDFExtractorProtocol {
    public var shouldFailExtraction = false

    public func extractPayslipData(from pdfDocument: PDFDocument) async throws -> PayslipItem? {
        if shouldFailExtraction { throw MockError.extractionFailed }
        return createMockPayslip()
    }

    public func extractPayslipData(from text: String) async throws -> PayslipItem? {
        if shouldFailExtraction { throw MockError.extractionFailed }
        return createMockPayslip()
    }

    public func extractText(from pdfDocument: PDFDocument) async -> String {
        shouldFailExtraction ? "" : "Mock extracted text"
    }

    public func getAvailableParsers() -> [String] { ["MockParser"] }

    private func createMockPayslip() -> PayslipItem {
        PayslipItem(
            month: "January",
            year: 2024,
            credits: 50000,
            debits: 10000,
            dsop: 0,
            tax: 5000,
            name: "Mock Employee",
            accountNumber: "MOCK123456",
            panNumber: "MOCKPAN123"
        )
    }
}

/// Mock payslip format detection service for testing
/// Implements PayslipFormatDetectionServiceProtocol
/// Follows SOLID principles with single responsibility for format detection mocking
public class MockPayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {
    public func detectFormat(_ data: Data) async -> PayslipFormat { .defense }
    public func detectFormat(fromText text: String) -> PayslipFormat { .defense }
    public func getSupportedFormats() -> [PayslipFormat] { [.defense, .unknown] }
    public func updateUserHint(_ hint: PayslipUserHint) { }
}
