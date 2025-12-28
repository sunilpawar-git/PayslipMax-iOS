import XCTest
@testable import PayslipMax

/// Tests for VisionLLMOptimizationConfig
final class VisionLLMOptimizationConfigTests: XCTestCase {

    func testDefaultConfiguration() {
        // Given/When
        let config = VisionLLMOptimizationConfig.default

        // Then - Updated to match current production values
        // 0.75 quality for better table parsing accuracy
        // 8500 tokens to support complex JCO/OR payslips
        XCTAssertEqual(config.imageCompressionQuality, 0.75, accuracy: 0.01)
        XCTAssertEqual(config.maxOutputTokens, 8500)
        XCTAssertEqual(config.temperature, 0.0, accuracy: 0.01)
    }

    func testCustomConfiguration() {
        // Given/When
        let config = VisionLLMOptimizationConfig(
            imageCompressionQuality: 0.7,
            maxOutputTokens: 2000,
            temperature: 0.5
        )

        // Then
        XCTAssertEqual(config.imageCompressionQuality, 0.7, accuracy: 0.01)
        XCTAssertEqual(config.maxOutputTokens, 2000)
        XCTAssertEqual(config.temperature, 0.5, accuracy: 0.01)
    }

    func testMinimumCompression() {
        //Given/When
        let config = VisionLLMOptimizationConfig(
            imageCompressionQuality: 1.0,
            maxOutputTokens: 8000,
            temperature: 1.0
        )

        // Then
        XCTAssertEqual(config.imageCompressionQuality, 1.0, accuracy: 0.01)
    }

    func testMaximumCompression() {
        // Given/When
        let config = VisionLLMOptimizationConfig(
            imageCompressionQuality: 0.1,
            maxOutputTokens: 500,
            temperature: 0.0
        )

        // Then
        XCTAssertEqual(config.imageCompressionQuality, 0.1, accuracy: 0.01)
        XCTAssertEqual(config.maxOutputTokens, 500)
    }

    func testConfigIsSendable() {
        // Test that config can be used in async contexts
        Task {
            let config = VisionLLMOptimizationConfig.default
            XCTAssertNotNil(config)
        }
    }
}
