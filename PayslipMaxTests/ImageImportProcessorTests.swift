import XCTest
@testable import PayslipMax
import UIKit

final class ImageImportProcessorTests: XCTestCase {

    @MainActor
    func testProcessImageSuccessSavesPayslip() async {
        let handler = StubPDFProcessingHandler(result: .success(TestDataGenerator.samplePayslipItem()))
        let dataService = MockDataService()
        let processor = ImageImportProcessor(pdfHandler: handler, dataService: dataService)
        let image = UIImage(systemName: "doc") ?? UIImage()

        let result = await processor.process(image: image)

        if case .failure(let message) = result {
            XCTFail("Expected success, got failure: \(message)")
        }
        XCTAssertEqual(dataService.initializeCallCount, 1)
        XCTAssertEqual(dataService.saveCallCount, 1)
    }

    @MainActor
    func testProcessImageFailurePropagatesMessage() async {
        let handler = StubPDFProcessingHandler(result: .failure(PDFProcessingError.notAPayslip))
        let dataService = MockDataService()
        let processor = ImageImportProcessor(pdfHandler: handler, dataService: dataService)
        let image = UIImage(systemName: "doc") ?? UIImage()

        let result = await processor.process(image: image)

        if case .failure(let error) = result {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        } else {
            XCTFail("Expected failure result")
        }
    }
}

// MARK: - Test Doubles
@MainActor
private final class StubPDFProcessingService: PDFProcessingServiceProtocol {
    var isInitialized: Bool = true
    func initialize() async throws {}

    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> { .failure(.invalidPDFData) }
    func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> { .failure(.invalidPDFData) }
    func isPasswordProtected(_ data: Data) -> Bool { false }
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError> { .failure(.incorrectPassword) }
    func processScannedImage(_ image: UIImage) async -> Result<PayslipItem, PDFProcessingError> { .failure(.notAPayslip) }
    func processScannedImageLLMOnly(_ image: UIImage, hint: PayslipUserHint) async -> Result<PayslipItem, PDFProcessingError> { .failure(.notAPayslip) }
    func updateUserHint(_ hint: PayslipUserHint) { }
    func detectPayslipFormat(_ data: Data) -> PayslipFormat { .unknown }
    func validatePayslipContent(_ data: Data) -> PayslipContentValidationResult {
        PayslipContentValidationResult(isValid: false, confidence: 0, detectedFields: [], missingRequiredFields: [])
    }
}

@MainActor
private final class StubPDFProcessingHandler: PDFProcessingHandler {
    private let stubResult: Result<PayslipItem, Error>

    init(result: Result<PayslipItem, Error>) {
        self.stubResult = result
        super.init(pdfProcessingService: StubPDFProcessingService())
    }

    override func processScannedImage(_ image: UIImage, hint: PayslipUserHint = .auto) async -> Result<PayslipItem, Error> {
        stubResult
    }
}


