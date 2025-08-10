import XCTest
@testable import PayslipMax

final class PCDATotalsMismatchClassificationTests: XCTestCase {
    private var validator: PCDAFinancialValidator!

    override func setUp() {
        super.setUp()
        validator = PCDAFinancialValidator()
    }

    override func tearDown() {
        validator = nil
        super.tearDown()
    }

    // MARK: - Totals mismatch should fail with actionable message
    func testTotalsMismatch_FailsWithActionableExplanation() {
        // Credits and debits differ by more than tolerance (1.0)
        let credits: [String: Double] = [
            "BPAY": 50_000,
            "DA": 20_000,
            "MSP": 10_000
        ] // Total = 80_000

        let debits: [String: Double] = [
            "DSOP": 5_000,
            "AGIF": 2_000,
            "ITAX": 30_000
        ] // Total = 37_000

        let result = validator.validatePCDAExtraction(
            credits: credits,
            debits: debits,
            remittance: nil
        )

        switch result {
        case .failed(let message):
            // Message should guide reconciliation clearly
            XCTAssertTrue(message.contains("PCDA format violation"))
            XCTAssertTrue(message.contains("Total Credits"))
            XCTAssertTrue(message.contains("Total Debits"))
            XCTAssertTrue(message.contains("Difference"))
        default:
            XCTFail("Expected failure with actionable explanation, got: \(String(describing: result.message))")
        }
    }

    // MARK: - Near-match within tolerance should be valid (no hard failure)
    func testTotalsWithinTolerance_IsValid() {
        // Difference is 0.5, inside tolerance (1.0)
        let credits: [String: Double] = ["BPAY": 10_000]
        let debits: [String: Double] = ["DSOP": 9_999.5]

        let result = validator.validatePCDAExtraction(
            credits: credits,
            debits: debits,
            remittance: nil
        )

        XCTAssertTrue(result.isValid, result.message ?? "Unexpected invalid result for near-match totals")
    }
}


