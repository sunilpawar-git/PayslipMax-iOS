import XCTest
import CoreGraphics
@testable import PayslipMax

final class Phase5PCDATableParsingTests: XCTestCase {
    // MARK: - Subjects Under Test
    private var parser: SimplifiedPCDATableParser! // text/spatial PCDA parser
    private var extractor: MilitaryFinancialDataExtractor! // end-to-end extractor
    private var validator: PCDAFinancialValidator! // totals/consistency validator

    override func setUp() {
        super.setUp()
        parser = SimplifiedPCDATableParser()
        extractor = MilitaryFinancialDataExtractor()
        validator = PCDAFinancialValidator()
    }

    override func tearDown() {
        parser = nil
        extractor = nil
        validator = nil
        super.tearDown()
    }

    // MARK: - Golden dataset regression
    func testGoldenDataset_ArmyNavyAF_CleanPDFs_ShouldExtractCoreFields() {
        // Army-like
        let army = """
        CREDIT DEBIT
        BPAY 50000 DA 20000 MSP 10000
        DSOP 5000 AGIF 2000 ITAX 4000
        Total Credit 80000
        Total Debit 16000
        """

        // Navy-like
        let navy = """
        EARNINGS DEDUCTIONS
        HRA 15000 TA 5000 BPAY 60000
        ITAX 7000 AGIF 2500 DSOP 5500
        Total Credit 80000
        Total Debit 15000
        """

        // Air Force-like
        let airForce = """
        Credits and Debits
        MSP 12000 DA 24000 BPAY 48000
        DSOP 6000 ITAX 8000
        Total Credit 84000
        Total Debit 14000
        """

        // Use the text-based parser for golden dataset coverage
        let (aEarn, aDed) = parser.extractTableData(from: army)
        let (nEarn, nDed) = parser.extractTableData(from: navy)
        let (fEarn, fDed) = parser.extractTableData(from: airForce)

        // Core schema codes should be present
        XCTAssertGreaterThan(aEarn["BPAY"] ?? 0, 0)
        XCTAssertGreaterThan(aEarn["DA"] ?? 0, 0)
        XCTAssertGreaterThan(aEarn["MSP"] ?? 0, 0)
        XCTAssertGreaterThan(aDed["DSOP"] ?? 0, 0)
        XCTAssertGreaterThan(aDed["AGIF"] ?? 0, 0)
        XCTAssertTrue(aDed.keys.contains { $0 == "IT" || $0 == "ITAX" })

        XCTAssertGreaterThan(nEarn["BPAY"] ?? 0, 0)
        XCTAssertGreaterThan(nEarn["HRA"] ?? 0, 0)
        XCTAssertGreaterThan(nEarn["TA"] ?? 0, 0)
        XCTAssertGreaterThan(nDed["DSOP"] ?? 0, 0)
        XCTAssertGreaterThan(nDed["AGIF"] ?? 0, 0)

        XCTAssertGreaterThan(fEarn["BPAY"] ?? 0, 0)
        XCTAssertGreaterThan(fEarn["DA"] ?? 0, 0)
        XCTAssertGreaterThan(fEarn["MSP"] ?? 0, 0)
        XCTAssertGreaterThan(fDed["DSOP"] ?? 0, 0)
        XCTAssertTrue(fDed.keys.contains { $0 == "IT" || $0 == "ITAX" })
    }

    // MARK: - Totals reconciliation and validation
    func testTotalsReconciliation_PCDAValidator_PassesOrWarns_NotFails() {
        // Include PCDA marker so extractor takes the PCDA path and build balanced totals
        let text = """
        Principal Controller of Defence Accounts
        CREDIT DEBIT
        BPAY 50000 DA 20000 MSP 10000
        DSOP 5000 AGIF 2000 ITAX 73000
        """

        let (earn, ded) = extractor.extractMilitaryTabularData(from: text)

        // Expect non-empty extraction and balanced totals to validate
        XCTAssertFalse(earn.isEmpty && ded.isEmpty, "Expected extracted earnings/deductions")

        let result = validator.validatePCDAExtraction(
            credits: earn,
            debits: ded,
            remittance: nil
        )
        XCTAssertTrue(result.isValid, result.message ?? "Unexpected failure")
    }

    // MARK: - Spatial 4-column structure (Description|Amount|Description|Amount)
    func testSpatialExtraction_PCDAFourColumnStructure_ExtractsPairs() {
        // Build a simple 4-column, 2-row table
        let rows = [
            TableStructure.TableRow(index: 0, yPosition: 0, height: 20, bounds: CGRect(x: 0, y: 0, width: 400, height: 20)),
            TableStructure.TableRow(index: 1, yPosition: 25, height: 20, bounds: CGRect(x: 0, y: 25, width: 400, height: 20))
        ]
        let columns = [
            TableStructure.TableColumn(index: 0, xPosition: 0, width: 100, bounds: CGRect(x: 0, y: 0, width: 100, height: 45)),
            TableStructure.TableColumn(index: 1, xPosition: 105, width: 90, bounds: CGRect(x: 105, y: 0, width: 90, height: 45)),
            TableStructure.TableColumn(index: 2, xPosition: 200, width: 100, bounds: CGRect(x: 200, y: 0, width: 100, height: 45)),
            TableStructure.TableColumn(index: 3, xPosition: 305, width: 95, bounds: CGRect(x: 305, y: 0, width: 95, height: 45))
        ]

        // Create cells for header + 1 data row
        let headerCells: [TableCell?] = [
            TableCell(row: 0, column: 0, bounds: .init(x: 0, y: 0, width: 100, height: 20), textElements: [TextElement(text: "Description", bounds: .init(x: 10, y: 5, width: 80, height: 10), fontSize: 12, confidence: 0.9)]),
            TableCell(row: 0, column: 1, bounds: .init(x: 105, y: 0, width: 90, height: 20), textElements: [TextElement(text: "Credit", bounds: .init(x: 110, y: 5, width: 40, height: 10), fontSize: 12, confidence: 0.9)]),
            TableCell(row: 0, column: 2, bounds: .init(x: 200, y: 0, width: 100, height: 20), textElements: [TextElement(text: "Description", bounds: .init(x: 210, y: 5, width: 80, height: 10), fontSize: 12, confidence: 0.9)]),
            TableCell(row: 0, column: 3, bounds: .init(x: 305, y: 0, width: 95, height: 20), textElements: [TextElement(text: "Debit", bounds: .init(x: 310, y: 5, width: 30, height: 10), fontSize: 12, confidence: 0.9)])
        ]
        let dataCells: [TableCell?] = [
            TableCell(row: 1, column: 0, bounds: .init(x: 0, y: 25, width: 100, height: 20), textElements: [TextElement(text: "BPAY", bounds: .init(x: 10, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9)]),
            TableCell(row: 1, column: 1, bounds: .init(x: 105, y: 25, width: 90, height: 20), textElements: [TextElement(text: "50000", bounds: .init(x: 110, y: 30, width: 40, height: 10), fontSize: 12, confidence: 0.9)]),
            TableCell(row: 1, column: 2, bounds: .init(x: 200, y: 25, width: 100, height: 20), textElements: [TextElement(text: "DSOP", bounds: .init(x: 210, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9)]),
            TableCell(row: 1, column: 3, bounds: .init(x: 305, y: 25, width: 95, height: 20), textElements: [TextElement(text: "5000", bounds: .init(x: 310, y: 30, width: 30, height: 10), fontSize: 12, confidence: 0.9)])
        ]

        let spatial = SpatialTableStructure(
            cells: [headerCells, dataCells],
            rows: rows,
            columns: columns,
            bounds: .init(x: 0, y: 0, width: 400, height: 45),
            headers: ["Description", "Credit", "Description", "Debit"]
        )

        // Build PCDA-specific structures to hand to the high-level parser
        let tableStructure = TableStructure(rows: rows, columns: columns, bounds: .init(x: 0, y: 0, width: 400, height: 45))
        let pcdaStructure = PCDATableStructure(
            baseStructure: tableStructure,
            headerRow: rows.first,
            dataRows: [rows[1]],
            creditColumns: (description: 0, amount: 1),
            debitColumns: (description: 2, amount: 3),
            isPCDAFormat: true
        )

        // Build a PCDA row and assert pair extraction from the 4-column structure
        let pcdaRow = PCDATableRow(
            rowIndex: 1,
            creditDescription: spatial.cell(at: 1, column: 0),
            creditAmount: spatial.cell(at: 1, column: 1),
            debitDescription: spatial.cell(at: 1, column: 2),
            debitAmount: spatial.cell(at: 1, column: 3)
        )

        XCTAssertTrue(pcdaRow.isValid)
        if let credit = pcdaRow.getCreditData() {
            XCTAssertEqual(credit.description, "BPAY")
            XCTAssertEqual(credit.amount, 50000)
        } else {
            XCTFail("Missing credit data")
        }
        if let debit = pcdaRow.getDebitData() {
            XCTAssertEqual(debit.description, "DSOP")
            XCTAssertEqual(debit.amount, 5000)
        } else {
            XCTFail("Missing debit data")
        }
    }

    // MARK: - Property-based style fuzzing (lightweight)
    func testFuzzing_MinorNoiseAndOrderChanges_DoNotBreakExtraction() {
        let baseLines = [
            "BPAY 50000",
            "DA 20000",
            "MSP 10000",
            "DSOP 5000",
            "AGIF 2000",
            "ITAX 4000"
        ]

        for seed in 1...25 { // lightweight fuzzing
            var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
            var lines = baseLines.shuffled(using: &rng)
            // Inject minor noise
            if seed % 3 == 0 { lines.insert("Notes: confidential", at: 0) }
            if seed % 5 == 0 { lines.append("Footer 12345") }

            let text = (["CREDIT DEBIT"] + lines).joined(separator: "\n")
            let (earn, ded) = parser.extractTableData(from: text)

            // We should still reliably pick up at least BPAY and DSOP
            XCTAssertGreaterThan(earn["BPAY"] ?? 0, 0, "Seed \(seed) failed to extract BPAY")
            XCTAssertGreaterThan(ded["DSOP"] ?? 0, 0, "Seed \(seed) failed to extract DSOP")
        }
    }
}

// MARK: - Helpers
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xDEADBEEF : seed }
    mutating func next() -> UInt64 {
        // XorShift64*
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2685821657736338717
    }
}


