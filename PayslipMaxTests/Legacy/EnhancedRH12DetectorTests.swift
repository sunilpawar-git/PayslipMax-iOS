import XCTest
@testable import PayslipMax

/// Tests for EnhancedRH12Detector core functionality
@MainActor
final class EnhancedRH12DetectorTests: BaseTestCase {

    private var detector: EnhancedRH12Detector!

    override func setUp() {
        super.setUp()
        detector = EnhancedRH12Detector()
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    // MARK: - Single RH12 Detection Tests

    func testDetectAllRH12Instances_StandardPattern() {
        let payslipText = """
        STATEMENT OF ACCOUNT
        EARNINGS
        Basic Pay: ₹50,000
        RH12: ₹21,125
        TOTAL: ₹276,665
        """
        let instances = detector.detectAllRH12Instances(in: payslipText)
        XCTAssertEqual(instances.count, 1)
        XCTAssertEqual(instances.first?.value, 21125.0)
        XCTAssertTrue(instances.first?.context.contains("RH12") ?? false)
    }

    func testDetectAllRH12Instances_NoColonPattern() {
        let payslipText = """
        EARNINGS
        RH12 ₹15,000
        MSP: ₹10,000
        """
        let instances = detector.detectAllRH12Instances(in: payslipText)
        XCTAssertEqual(instances.count, 1)
        XCTAssertEqual(instances.first?.value, 15000.0)
    }

    func testDetectAllRH12Instances_SpacedPattern() {
        let payslipText = """
        ALLOWANCES
        R H 1 2    ₹8,500
        Other allowances
        """
        let instances = detector.detectAllRH12Instances(in: payslipText)
        XCTAssertEqual(instances.count, 1)
        XCTAssertEqual(instances.first?.value, 8500.0)
    }

    // MARK: - Dual RH12 Detection Tests

    func testDetectAllRH12Instances_DualSectionMay2025() {
        let may2025PayslipText = """
        STATEMENT OF ACCOUNT - MAY 2025

        EARNINGS                               AMOUNT
        Basic Pay                              50,000
        RH12                                   21,125
        TOTAL EARNINGS                        276,665

        DEDUCTIONS                             AMOUNT
        Income Tax                              8,000
        RH12                                    7,518
        TOTAL DEDUCTIONS                      108,525

        NET REMITTANCE                        168,140
        """
        let instances = detector.detectAllRH12Instances(in: may2025PayslipText)
        XCTAssertEqual(instances.count, 2)

        let values = instances.map { $0.value }.sorted()
        XCTAssertTrue(values.contains(7518.0))
        XCTAssertTrue(values.contains(21125.0))

        let contexts = instances.map { $0.context }
        XCTAssertTrue(contexts.contains { $0.uppercased().contains("EARNINGS") })
        XCTAssertTrue(contexts.contains { $0.uppercased().contains("DEDUCTIONS") })
    }

    func testDetectAllRH12Instances_MultiplePatternsInSamePayslip() {
        let mixedPatternText = """
        EARNINGS
        RH12: ₹21,125
        Basic Pay ₹50,000

        DEDUCTIONS
        Risk Hardship ₹7,518
        Income Tax ₹8,000

        ALLOWANCES
        R H 1 2 ₹3,500
        """
        let instances = detector.detectAllRH12Instances(in: mixedPatternText)
        XCTAssertEqual(instances.count, 3)
        let values = instances.map { $0.value }.sorted()
        XCTAssertEqual(values, [3500.0, 7518.0, 21125.0])
    }

    // MARK: - Pattern Variation Tests

    func testDetectAllRH12Instances_WithoutCurrencySymbol() {
        let payslipText = """
        EARNINGS
        RH12 21125
        Basic Pay 50000
        """
        let instances = detector.detectAllRH12Instances(in: payslipText)
        XCTAssertEqual(instances.count, 1)
        XCTAssertEqual(instances.first?.value, 21125.0)
    }

    func testDetectAllRH12Instances_WithCommasInValue() {
        let payslipText = """
        DEDUCTIONS
        RH12: ₹21,125
        Tax: ₹8,000
        """
        let instances = detector.detectAllRH12Instances(in: payslipText)
        XCTAssertEqual(instances.count, 1)
        XCTAssertEqual(instances.first?.value, 21125.0)
    }

    func testDetectAllRH12Instances_CaseInsensitive() {
        let payslipText = """
        EARNINGS
        rh12: ₹15,000
        Rh12 ₹10,000
        RH12: ₹5,000
        """
        let instances = detector.detectAllRH12Instances(in: payslipText)
        XCTAssertEqual(instances.count, 3)
        let values = instances.map { $0.value }.sorted()
        XCTAssertEqual(values, [5000.0, 10000.0, 15000.0])
    }

    // MARK: - Context Extraction Tests

    func testDetectAllRH12Instances_ContextWindow() {
        let longPayslipText = String(repeating: "A", count: 1000) +
                             " EARNINGS RH12: ₹21,125 MSP " +
                             String(repeating: "B", count: 1000)
        let instances = detector.detectAllRH12Instances(in: longPayslipText)
        XCTAssertEqual(instances.count, 1)

        let context = instances.first?.context ?? ""
        XCTAssertLessThanOrEqual(context.count, 800)
        XCTAssertTrue(context.contains("RH12"))
        XCTAssertTrue(context.contains("EARNINGS"))
    }

    // MARK: - Edge Cases

    func testDetectAllRH12Instances_EmptyText() {
        let instances = detector.detectAllRH12Instances(in: "")
        XCTAssertEqual(instances.count, 0)
    }

    func testDetectAllRH12Instances_NoRH12() {
        let payslipText = """
        EARNINGS
        Basic Pay: ₹50,000
        MSP: ₹10,000
        """
        let instances = detector.detectAllRH12Instances(in: payslipText)
        XCTAssertEqual(instances.count, 0)
    }

    func testDetectAllRH12Instances_InvalidAmounts() {
        let payslipText = """
        EARNINGS
        RH12: ₹abc
        RH12: ₹
        RH12:
        RH12: ₹-500
        """
        let instances = detector.detectAllRH12Instances(in: payslipText)
        XCTAssertEqual(instances.count, 0)
    }
}
