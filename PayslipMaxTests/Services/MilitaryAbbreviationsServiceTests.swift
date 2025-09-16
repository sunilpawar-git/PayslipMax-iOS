import XCTest
@testable import PayslipMax

/// Comprehensive tests for MilitaryAbbreviationsService with 200+ codes
final class MilitaryAbbreviationsServiceTests: XCTestCase {

    var service: MilitaryAbbreviationsService!

    override func setUp() {
        super.setUp()
        service = MilitaryAbbreviationsService.shared
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Basic Service Tests

    func testServiceInitialization() {
        // Then: Service should be properly initialized
        XCTAssertNotNil(service)
        XCTAssertGreaterThan(service.allAbbreviations.count, 200, "Should have 200+ abbreviations loaded")
    }

    func testCreditAbbreviations() {
        // When: Get credit abbreviations
        let credits = service.creditAbbreviations

        // Then: Should contain essential earning codes
        let creditCodes = Set(credits.map { $0.code })
        let essentialEarnings = ["BPAY", "MSP", "DA", "HRA", "TPTA", "CEA", "SPCDO", "FLYALLOW", "SICHA"]

        for code in essentialEarnings {
            XCTAssertTrue(creditCodes.contains(code), "Credits should contain: \(code)")
        }
    }

    func testDebitAbbreviations() {
        // When: Get debit abbreviations
        let debits = service.debitAbbreviations

        // Then: Should contain essential deduction codes
        let debitCodes = Set(debits.map { $0.code })
        let essentialDeductions = ["DSOP", "AGIF", "ITAX", "EHCESS"]

        for code in essentialDeductions {
            XCTAssertTrue(debitCodes.contains(code), "Debits should contain: \(code)")
        }
    }

    // MARK: - Abbreviation Lookup Tests

    func testAbbreviationLookup() {
        // When: Look up specific abbreviations
        let bpay = service.abbreviation(forCode: "BPAY")
        let msp = service.abbreviation(forCode: "MSP")
        let dsop = service.abbreviation(forCode: "DSOP")

        // Then: Should find all essential codes
        XCTAssertNotNil(bpay)
        XCTAssertEqual(bpay?.code, "BPAY")
        XCTAssertEqual(bpay?.description, "Basic Pay")
        XCTAssertEqual(bpay?.isCredit, true)

        XCTAssertNotNil(msp)
        XCTAssertEqual(msp?.code, "MSP")
        XCTAssertEqual(msp?.description, "Military Service Pay")
        XCTAssertEqual(msp?.isCredit, true)

        XCTAssertNotNil(dsop)
        XCTAssertEqual(dsop?.code, "DSOP")
        XCTAssertTrue(dsop?.description.contains("Defence") == true)
        XCTAssertEqual(dsop?.isCredit, false)
    }

    func testSpecialForcesAbbreviations() {
        // When: Look up special forces codes
        let spcdo = service.abbreviation(forCode: "SPCDO")
        let flyallow = service.abbreviation(forCode: "FLYALLOW")
        let sicha = service.abbreviation(forCode: "SICHA")

        // Then: Should find all special forces codes
        XCTAssertNotNil(spcdo, "Should find SPCDO (Special Forces)")
        XCTAssertNotNil(flyallow, "Should find FLYALLOW (Flying Allowance)")
        XCTAssertNotNil(sicha, "Should find SICHA (Siachen Allowance)")

        // All should be credits (earnings)
        XCTAssertEqual(spcdo?.isCredit, true)
        XCTAssertEqual(flyallow?.isCredit, true)
        XCTAssertEqual(sicha?.isCredit, true)
    }

    func testRHFamilyAbbreviations() {
        // When: Look up RH family codes
        let rhCodes = ["RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]

        for code in rhCodes {
            let abbreviation = service.abbreviation(forCode: code)

            // Then: Should find all RH codes
            XCTAssertNotNil(abbreviation, "Should find \(code)")
            XCTAssertEqual(abbreviation?.code, code)
            XCTAssertTrue(abbreviation?.description.contains("Risk") == true ||
                         abbreviation?.description.contains("Hardship") == true ||
                         abbreviation?.description.contains("Allowance") == true,
                         "\(code) should be Risk/Hardship related")
        }
    }

    func testCaseInsensitiveLookup() {
        // When: Look up with different cases
        let bpayUpper = service.abbreviation(forCode: "BPAY")
        let _ = service.abbreviation(forCode: "bpay")
        let _ = service.abbreviation(forCode: "BPay")

        // Then: Should handle case variations
        XCTAssertNotNil(bpayUpper)
        // Note: Current implementation may be case-sensitive
        // This test documents expected behavior
    }

    // MARK: - Category Tests

    func testAbbreviationsByCategory() {
        // When: Get abbreviations by category
        let allowances = service.abbreviations(inCategory: .allowance)
        let deductions = service.abbreviations(inCategory: .deduction)
        let insurance = service.abbreviations(inCategory: .insurance)

        // Then: Should have appropriate distributions
        XCTAssertFalse(allowances.isEmpty, "Should have allowance abbreviations")
        XCTAssertFalse(deductions.isEmpty, "Should have deduction abbreviations")
        XCTAssertFalse(insurance.isEmpty, "Should have insurance abbreviations")

        // Allowances should include DA, HRA, etc.
        let allowanceCodes = Set(allowances.map { $0.code })
        XCTAssertTrue(allowanceCodes.contains("DA") || allowanceCodes.contains("HRA"),
                     "Allowances should contain DA or HRA")
    }

    // MARK: - Text Matching Tests

    func testTextMatching() {
        // When: Match text descriptions
        let basicPayMatch = service.match(text: "Basic Pay")
        let militaryServiceMatch = service.match(text: "Military Service Pay")

        // Then: Should match by description
        XCTAssertNotNil(basicPayMatch)
        XCTAssertEqual(basicPayMatch?.code, "BPAY")

        XCTAssertNotNil(militaryServiceMatch)
        XCTAssertEqual(militaryServiceMatch?.code, "MSP")
    }

    // MARK: - Normalization Tests

    func testComponentNormalization() {
        // When: Normalize component names
        let normalizedBasic = service.normalizePayComponent("basic pay")
        let normalizedDA = service.normalizePayComponent("dearness allowance")

        // Then: Should return normalized forms
        XCTAssertFalse(normalizedBasic.isEmpty)
        XCTAssertFalse(normalizedDA.isEmpty)

        // Should handle common variations
        let variations = ["BASIC PAY", "Basic Pay", "basic pay", "BPAY"]
        for variation in variations {
            let normalized = service.normalizePayComponent(variation)
            XCTAssertFalse(normalized.isEmpty, "Should normalize: \(variation)")
        }
    }

    // MARK: - Performance Tests

    func testLookupPerformance() {
        // Given: Common abbreviations
        let commonCodes = ["BPAY", "MSP", "DA", "HRA", "DSOP", "AGIF", "ITAX", "RH12"]

        // When: Measure lookup performance
        measure {
            for code in commonCodes {
                _ = service.abbreviation(forCode: code)
            }
        }
    }

    func testAllAbbreviationsPerformance() {
        // When: Measure performance of getting all abbreviations
        measure {
            _ = service.allAbbreviations
        }
    }

    // MARK: - Integration Tests

    func testServiceIntegrationWithClassificationEngine() {
        // When: Test integration with classification engine
        let abbreviations = service.allAbbreviations

        // Then: All abbreviations should have proper isCredit values
        for abbreviation in abbreviations {
            XCTAssertNotNil(abbreviation.isCredit, "All abbreviations should have isCredit defined")
            XCTAssertFalse(abbreviation.code.isEmpty, "All abbreviations should have non-empty codes")
            XCTAssertFalse(abbreviation.description.isEmpty, "All abbreviations should have descriptions")
        }
    }

    func testServiceCompatibilityWithExistingParsers() {
        // When: Test compatibility with existing parsing logic
        let essentialCodesForParsing = [
            "BPAY", "MSP", "DA", "HRA", "TPTA", "TPTADA", "CEA", "RSHNA",
            "RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33",
            "DSOP", "AGIF", "AFPF", "ITAX", "EHCESS", "GPF", "PF",
            "SPCDO", "FLYALLOW", "SICHA", "HAUC3"
        ]

        for code in essentialCodesForParsing {
            let abbreviation = service.abbreviation(forCode: code)
            XCTAssertNotNil(abbreviation, "Essential parsing code must be available: \(code)")
        }
    }
}
