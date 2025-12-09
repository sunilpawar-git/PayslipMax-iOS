import XCTest
@testable import PayslipMax

final class DITreeSmokeTests: XCTestCase {
    @MainActor
    func testPDFProcessingHandlerConstruction() {
        let handler = DIContainer.shared.makePDFProcessingHandler()
        XCTAssertNotNil(handler)
    }

    @MainActor
    func testPDFProcessingServiceConstruction() {
        let service = DIContainer.shared.makePDFProcessingService()
        XCTAssertNotNil(service)
    }
}

