import XCTest
@testable import PayslipMax

/// Integration and performance tests for EnhancedRH12Detector
@MainActor
final class EnhancedRH12DetectorIntegrationTests: BaseTestCase {

    private var detector: EnhancedRH12Detector!

    override func setUp() {
        super.setUp()
        detector = EnhancedRH12Detector()
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    // MARK: - Deduplication Tests

    func testDetectAllRH12Instances_DuplicateValues() {
        let payslipText = """
        EARNINGS
        RH12: ₹15,000
        Risk Hardship: ₹15,000
        RH12 ₹15,000
        """
        let instances = detector.detectAllRH12Instances(in: payslipText)
        XCTAssertEqual(instances.count, 1)
        XCTAssertEqual(instances.first?.value, 15000.0)
    }

    func testDetectAllRH12Instances_NearDuplicateValues() {
        let payslipText = """
        EARNINGS
        RH12: ₹15,000.50
        RH12 ₹15,000.49
        """
        let instances = detector.detectAllRH12Instances(in: payslipText)
        XCTAssertEqual(instances.count, 2)
    }

    // MARK: - Performance Tests

    func testDetectAllRH12Instances_LargeText() {
        let baseText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 1000)
        let payslipText = baseText + " RH12: ₹21,125 " + baseText + " RH12 ₹7,518 " + baseText

        let startTime = CFAbsoluteTimeGetCurrent()
        let instances = detector.detectAllRH12Instances(in: payslipText)
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertEqual(instances.count, 2)
        XCTAssertLessThan(executionTime, 1.0)
    }

    // MARK: - Integration Test with Real-World Data

    func testDetectAllRH12Instances_RealWorldMay2025Scenario() {
        let realWorldText = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        STATEMENT OF ACCOUNT FOR THE MONTH OF MAY 2025

        NAME: MAJOR RAJESH KUMAR
        SERVICE NO: IC-56789
        UNIT: 15 RAJPUT REGIMENT

        EARNINGS                                          AMOUNT (₹)
        001  Basic Pay                                     65,000
        002  Dearness Allowance @ 42%                      27,300
        003  Military Service Pay                          15,500
        004  High Altitude Allowance                        8,200
        005  Technical Allowance                            5,800
        006  RH12                                          21,125
        007  Field Area Allowance                           4,500
        008  Transport Allowance                            3,240
                                            TOTAL EARNINGS  276,665

        DEDUCTIONS                                        AMOUNT (₹)
        101  Income Tax u/s 192                            45,280
        102  AGIF                                           6,500
        103  DSOP                                          32,500
        104  Group Insurance                                1,850
        105  RH12                                           7,518
        106  Welfare Fund                                   2,000
        107  Mess Charges                                   8,877
        108  Other Deductions                               4,000
                                         TOTAL DEDUCTIONS  108,525

        NET REMITTANCE                                    168,140
        """

        let instances = detector.detectAllRH12Instances(in: realWorldText)

        XCTAssertEqual(instances.count, 2)

        let sortedValues = instances.map { $0.value }.sorted()
        XCTAssertEqual(sortedValues[0], 7518.0)
        XCTAssertEqual(sortedValues[1], 21125.0)

        let totalRH12 = instances.map { $0.value }.reduce(0, +)
        XCTAssertEqual(totalRH12, 28643.0)

        let contexts = instances.map { $0.context.uppercased() }
        XCTAssertTrue(contexts.contains { $0.contains("EARNINGS") })
        XCTAssertTrue(contexts.contains { $0.contains("DEDUCTIONS") })
    }
}

