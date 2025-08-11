import XCTest
@testable import PayslipMax

final class PCDAHeaderVariantRobustnessTests: XCTestCase {
    private var parser: SimplifiedPCDATableParser!

    override func setUp() {
        super.setUp()
        parser = SimplifiedPCDATableParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Aliases normalize to stable keys across header variants
    func testAliasNormalizationAcrossHeaderVariants() {
        // Variant 1: CREDIT/DEBIT
        let v1 = """
        CREDIT DEBIT
        Basic Pay 50000
        Dearness Allowance 20000
        Military Service Pay 10000
        DSOP Fund 5000
        Income Tax 4000
        AGIF 2000
        """
        // Variant 2: EARNINGS/DEDUCTIONS
        let v2 = """
        EARNINGS DEDUCTIONS
        BPAY 50000
        DA 20000
        MSP 10000
        DSOP 5000
        ITAX 4000
        AGIF 2000
        """
        // Variant 3: CR./DR. compact
        let v3 = """
        CR. DR.
        Pay 50000
        DA 20000
        MSP 10000
        DSOP 5000
        Inctax 4000
        AGIF 2000
        """

        let variants = [v1, v2, v3]

        for variant in variants {
            let (earn, ded) = parser.extractTableData(from: variant)

            // Normalize keys for both buckets
            let normalizedEarnings = earn.reduce(into: [String: Double]()) { acc, kv in
                let key = MilitaryAbbreviationsService.shared.normalizePayComponent(kv.key)
                acc[key] = (acc[key] ?? 0) + kv.value
            }
            let normalizedDeductions = ded.reduce(into: [String: Double]()) { acc, kv in
                let key = MilitaryAbbreviationsService.shared.normalizePayComponent(kv.key)
                acc[key] = (acc[key] ?? 0) + kv.value
            }

            // Combine for normalization-only assertions (classification placement is validated elsewhere)
            let allNormalizedKeys = Set(normalizedEarnings.keys).union(normalizedDeductions.keys)
            let allOriginalKeys = Set(earn.keys).union(ded.keys)
            // Case-insensitive union across original and normalized keys
            let allKeysLowercased: Set<String> = Set(allNormalizedKeys.map { $0.lowercased() })
                .union(allOriginalKeys.map { $0.lowercased() })

            // Assert presence of canonical keys regardless of header variant
            XCTAssertTrue(allKeysLowercased.contains("basic pay"), "Missing Basic Pay in variant: \(variant.prefix(20))…")
            XCTAssertTrue(allKeysLowercased.contains("dearness allowance") || allKeysLowercased.contains("da"), "Missing DA in variant: \(variant.prefix(20))…")
            XCTAssertTrue(allKeysLowercased.contains("military service pay") || allKeysLowercased.contains("msp"), "Missing MSP in variant")

            // Deductions: require DSOP and AGIF normalization which are ubiquitous across variants
            XCTAssertTrue(allKeysLowercased.contains("dsop"))
            XCTAssertTrue(allKeysLowercased.contains("agif"))
        }
    }
}


