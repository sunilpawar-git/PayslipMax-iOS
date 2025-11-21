//
//  PayslipProcessorFactoryTests.swift
//  PayslipMaxTests
//
//  Verifies that the factory correctly creates the HybridPayslipProcessor
//

import XCTest
@testable import PayslipMax

final class PayslipProcessorFactoryTests: XCTestCase {

    var mockSettings: MockLLMSettingsService!
    var mockFormatDetection: MockPayslipFormatDetectionService!
    var factory: PayslipProcessorFactory!

    override func setUp() {
        super.setUp()
        mockSettings = MockLLMSettingsService()
        mockFormatDetection = MockPayslipFormatDetectionService()

        factory = PayslipProcessorFactory(
            formatDetectionService: mockFormatDetection,
            settings: mockSettings
        )
    }

    override func tearDown() {
        mockSettings = nil
        mockFormatDetection = nil
        factory = nil
        super.tearDown()
    }

    func testFactoryReturnsHybridProcessor() {
        // Given
        let text = "Sample Payslip Text"

        // When
        let processor = factory.getProcessor(for: text)

        // Then
        // Verify it is a HybridPayslipProcessor
        XCTAssertTrue(processor is HybridPayslipProcessor, "Factory should return HybridPayslipProcessor")
    }
}
