import XCTest
@testable import PayslipMax

/// Tests for expanded relaxed and cross-line pay code extraction,
/// covering JCO/OR-specific codes like TPAL, CL PAY, GSPAY, PLI, etc.
final class RelaxedPayCodeExpandedTests: XCTestCase {

    private var sut: UniversalPayCodeSearchEngine!

    override func setUp() {
        super.setUp()
        sut = UniversalPayCodeSearchEngine()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Relaxed Line-Based Extraction

    func test_relaxedLine_extractsTPAL() {
        let text = "TPAL\n4500"
        let results = sut.extractRelaxedLineMatches(from: text)
        XCTAssertNotNil(results["TPAL"], "Should extract TPAL via relaxed scan")
        XCTAssertEqual(results["TPAL"]?.value, 4500)
    }

    func test_relaxedLine_extractsCLPAY() {
        let text = "CL PAY\n15600"
        let results = sut.extractRelaxedLineMatches(from: text)
        XCTAssertNotNil(results["CLPAY"], "Should extract CL PAY via relaxed scan")
        XCTAssertEqual(results["CLPAY"]?.value, 15600)
    }

    func test_relaxedLine_extractsGSPAY() {
        let text = "GRADE PAY\n5400"
        let results = sut.extractRelaxedLineMatches(from: text)
        XCTAssertNotNil(results["GSPAY"], "Should extract GSPAY via relaxed scan")
        XCTAssertEqual(results["GSPAY"]?.value, 5400)
    }

    func test_relaxedLine_extractsPMHA() {
        let text = "PMHA\n900"
        let results = sut.extractRelaxedLineMatches(from: text)
        XCTAssertNotNil(results["PMHA"], "Should extract PMHA via relaxed scan")
        XCTAssertEqual(results["PMHA"]?.value, 900)
    }

    func test_relaxedLine_extractsLRA() {
        let text = "LRA\n2400"
        let results = sut.extractRelaxedLineMatches(from: text)
        XCTAssertNotNil(results["LRA"], "Should extract LRA via relaxed scan")
        XCTAssertEqual(results["LRA"]?.value, 2400)
    }

    func test_relaxedLine_extractsHRALF() {
        let text = "HRALF\n6750"
        let results = sut.extractRelaxedLineMatches(from: text)
        XCTAssertNotNil(results["HRALF"], "Should extract HRALF via relaxed scan")
        XCTAssertEqual(results["HRALF"]?.value, 6750)
    }

    func test_relaxedLine_extractsRISK() {
        let text = "RISK ALLOW\n6000"
        let results = sut.extractRelaxedLineMatches(from: text)
        XCTAssertNotNil(results["RISK"], "Should extract RISK via relaxed scan")
        XCTAssertEqual(results["RISK"]?.value, 6000)
    }

    func test_relaxedLine_extractsPLI() {
        let text = "PLI\n800"
        let results = sut.extractRelaxedLineMatches(from: text)
        XCTAssertNotNil(results["PLI"], "Should extract PLI via relaxed scan")
        XCTAssertEqual(results["PLI"]?.value, 800)
    }

    func test_relaxedLine_extractsRUMCIG() {
        let text = "RUM CIG\n250"
        let results = sut.extractRelaxedLineMatches(from: text)
        XCTAssertNotNil(results["RUMCIG"], "Should extract RUMCIG via relaxed scan")
        XCTAssertEqual(results["RUMCIG"]?.value, 250)
    }

    // MARK: - Cross-Line Extraction

    func test_crossLine_extractsTPAL() {
        let text = "TPAL 4500"
        let results = sut.extractCrossLineMatches(from: text)
        XCTAssertNotNil(results["TPAL"], "Should extract TPAL via cross-line")
        XCTAssertEqual(results["TPAL"]?.value, 4500)
    }

    func test_crossLine_extractsCLPAY() {
        let text = "CL PAY   15600"
        let results = sut.extractCrossLineMatches(from: text)
        XCTAssertNotNil(results["CLPAY"], "Should extract CL PAY via cross-line")
        XCTAssertEqual(results["CLPAY"]?.value, 15600)
    }

    func test_crossLine_extractsGSPAY() {
        let text = "GSPAY\n5400"
        let results = sut.extractCrossLineMatches(from: text)
        XCTAssertNotNil(results["GSPAY"], "Should extract GSPAY via cross-line")
        XCTAssertEqual(results["GSPAY"]?.value, 5400)
    }

    func test_crossLine_extractsPLI() {
        let text = "PLI  800"
        let results = sut.extractCrossLineMatches(from: text)
        XCTAssertNotNil(results["PLI"], "Should extract PLI via cross-line")
        XCTAssertEqual(results["PLI"]?.value, 800)
    }

    func test_crossLine_extractsRISK() {
        let text = "RISK ALLOWANCE 6000"
        let results = sut.extractCrossLineMatches(from: text)
        XCTAssertNotNil(results["RISK"], "Should extract RISK via cross-line")
        XCTAssertEqual(results["RISK"]?.value, 6000)
    }

    // MARK: - Existing Codes Still Work

    func test_relaxedLine_existingBPAY_stillWorks() {
        let text = "BAND PAY\n56900"
        let results = sut.extractRelaxedLineMatches(from: text)
        XCTAssertNotNil(results["BPAY"])
        XCTAssertEqual(results["BPAY"]?.value, 56900)
    }

    func test_crossLine_existingDA_stillWorks() {
        let text = "DEARNESS ALLOWANCE 34000"
        let results = sut.extractCrossLineMatches(from: text)
        XCTAssertNotNil(results["DA"])
        XCTAssertEqual(results["DA"]?.value, 34000)
    }
}
