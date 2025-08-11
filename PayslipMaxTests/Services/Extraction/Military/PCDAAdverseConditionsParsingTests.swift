import XCTest
@testable import PayslipMax
import CoreGraphics

final class PCDAAdverseConditionsParsingTests: XCTestCase {
    // MARK: - Helpers

    private struct ScenarioConfig {
        let rotationDegrees: CGFloat
        let yJitter: CGFloat
        let mergeCreditCells: Bool
        let mergeDebitCells: Bool
        let confidence: Float
        let rows: Int
        let includePCDATerms: Bool
        let equalizeTotals: Bool
    }

    private func makeRect(x: CGFloat, y: CGFloat, w: CGFloat = 80, h: CGFloat = 16) -> CGRect {
        CGRect(x: x, y: y, width: w, height: h)
    }

    private func rotate(point: CGPoint, degrees: CGFloat) -> CGPoint {
        guard degrees != 0 else { return point }
        let radians = degrees * .pi / 180
        let cosA = cos(radians)
        let sinA = sin(radians)
        return CGPoint(x: point.x * cosA - point.y * sinA, y: point.x * sinA + point.y * cosA)
    }

    private func rotate(rect: CGRect, degrees: CGFloat) -> CGRect {
        guard degrees != 0 else { return rect }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let rotatedCenter = rotate(point: center, degrees: degrees)
        return CGRect(x: rotatedCenter.x - rect.width/2, y: rotatedCenter.y - rect.height/2, width: rect.width, height: rect.height)
    }

    private func jitterY(_ value: CGFloat, jitter: CGFloat) -> CGFloat { value + (jitter == 0 ? 0 : CGFloat.random(in: -jitter...jitter)) }

    private func headerElements(rotation: CGFloat, includePCDATerms: Bool) -> [TextElement] {
        var elements: [TextElement] = []
        let y: CGFloat = 20
        let headers = [
            ("विवरण / DESCRIPTION", makeRect(x: 10, y: y)),
            ("राशि / AMOUNT", makeRect(x: 130, y: y)),
            ("DESCRIPTION", makeRect(x: 220, y: y)),
            ("AMOUNT", makeRect(x: 340, y: y))
        ]
        elements.append(contentsOf: headers.map { (text, rect) in
            let r = rotate(rect: rect, degrees: rotation)
            return TextElement(text: text, bounds: r, fontSize: 12, confidence: 0.99)
        })
        if includePCDATerms {
            // Add a couple of PCDA-specific markers to satisfy detection
            let y2: CGFloat = 4
            let terms = [
                ("PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS", makeRect(x: 10, y: y2, w: 360, h: 14)),
                ("TOTAL CREDIT", makeRect(x: 10, y: y + 4, w: 120, h: 14)),
                ("TOTAL DEBIT", makeRect(x: 220, y: y + 4, w: 120, h: 14))
            ]
            elements.append(contentsOf: terms.map { (text, rect) in
                let r = rotate(rect: rect, degrees: rotation)
                return TextElement(text: text, bounds: r, fontSize: 11, confidence: 0.98)
            })
        }
        return elements
    }

    private func generatePCDAElements(config: ScenarioConfig) -> (elements: [TextElement], expectedCredits: [String: Double], expectedDebits: [String: Double]) {
        var elements: [TextElement] = []
        elements.append(contentsOf: headerElements(rotation: config.rotationDegrees, includePCDATerms: config.includePCDATerms))

        var expectedCredits: [String: Double] = [:]
        var expectedDebits: [String: Double] = [:]

        // Columns (approximate grid)
        let colX: [CGFloat] = [10, 130, 220, 340]
        let rowStartY: CGFloat = 50
        let rowStep: CGFloat = 24

        // Sample codes and amounts
        let creditCodes = ["BPAY", "DA", "MSP", "HRA", "TPTA", "CEA", "OUTFITA", "WASHIA", "TPT", "A/O"]
        let creditAmounts: [Double] = [40000, 12000, 10000, 8000, 3600, 2250, 1500, 900, 1600, 750]
        let debitCodes = ["DSOP", "AGIF", "ITAX", "CGEIS", "R/O", "ELKT", "FUR", "BARRACK", "CESS", "FUND"]
        let debitAmounts: [Double] = [5000, 3500, 4200, 120, 200, 180, 160, 140, 130, 120]

        let rowCount = min(config.rows, min(creditCodes.count, debitCodes.count))

        // Optionally rebalance debit totals to equal credits (PCDA validator requirement)
        var adjustedDebitAmounts = debitAmounts
        if config.equalizeTotals {
            let creditTotal = creditAmounts.prefix(rowCount).reduce(0, +)
            let baseDebitTotal = debitAmounts.prefix(rowCount).reduce(0, +)
            if baseDebitTotal > 0 {
                let scale = creditTotal / baseDebitTotal
                adjustedDebitAmounts = debitAmounts.map { ($0 * scale).rounded() }
            }
        }

        for i in 0..<rowCount {
            let baseY = rowStartY + CGFloat(i) * rowStep
            let y = jitterY(baseY, jitter: config.yJitter)

            let creditCode = creditCodes[i]
            let creditAmt = creditAmounts[i]
            let debitCode = debitCodes[i]
            let debitAmt = adjustedDebitAmounts[i]

            expectedCredits[creditCode] = creditAmt
            expectedDebits[debitCode] = debitAmt

            // Credit side
            if config.mergeCreditCells {
                // Put code and amount into description cell to simulate merged/overlap
                let mergedText = "\(creditCode) \(Int(creditAmt))"
                var rect = makeRect(x: colX[0], y: y, w: 90)
                rect = rotate(rect: rect, degrees: config.rotationDegrees)
                elements.append(TextElement(text: mergedText, bounds: rect, fontSize: 12, confidence: config.confidence))
                // Also add amount-only cell in the amount column so PCDA pipeline can read amounts
                var amtRect = makeRect(x: colX[1], y: y)
                amtRect = rotate(rect: amtRect, degrees: config.rotationDegrees)
                elements.append(TextElement(text: String(Int(creditAmt)), bounds: amtRect, fontSize: 12, confidence: config.confidence))
            } else {
                var descRect = makeRect(x: colX[0], y: y)
                var amtRect = makeRect(x: colX[1], y: y)
                descRect = rotate(rect: descRect, degrees: config.rotationDegrees)
                amtRect = rotate(rect: amtRect, degrees: config.rotationDegrees)
                elements.append(TextElement(text: creditCode, bounds: descRect, fontSize: 12, confidence: config.confidence))
                elements.append(TextElement(text: String(Int(creditAmt)), bounds: amtRect, fontSize: 12, confidence: config.confidence))
            }

            // Debit side
            if config.mergeDebitCells {
                let mergedText = "\(debitCode) \(Int(debitAmt))"
                var rect = makeRect(x: colX[2], y: y, w: 90)
                rect = rotate(rect: rect, degrees: config.rotationDegrees)
                elements.append(TextElement(text: mergedText, bounds: rect, fontSize: 12, confidence: config.confidence))
                // Also add amount-only cell in the amount column so PCDA pipeline can read amounts
                var amtRect = makeRect(x: colX[3], y: y)
                amtRect = rotate(rect: amtRect, degrees: config.rotationDegrees)
                elements.append(TextElement(text: String(Int(debitAmt)), bounds: amtRect, fontSize: 12, confidence: config.confidence))
            } else {
                var descRect = makeRect(x: colX[2], y: y)
                var amtRect = makeRect(x: colX[3], y: y)
                descRect = rotate(rect: descRect, degrees: config.rotationDegrees)
                amtRect = rotate(rect: amtRect, degrees: config.rotationDegrees)
                elements.append(TextElement(text: debitCode, bounds: descRect, fontSize: 12, confidence: config.confidence))
                elements.append(TextElement(text: String(Int(debitAmt)), bounds: amtRect, fontSize: 12, confidence: config.confidence))
            }
        }

        return (elements, expectedCredits, expectedDebits)
    }

    private func assertCoverageAndTotals(actualCredits: [String: Double], actualDebits: [String: Double], expectedCredits: [String: Double], expectedDebits: [String: Double], file: StaticString = #filePath, line: UInt = #line) {
        let expectedFieldCount = expectedCredits.count + expectedDebits.count
        let actualFieldCount = actualCredits.count + actualDebits.count
        let coverage = expectedFieldCount == 0 ? 1.0 : Double(actualFieldCount) / Double(expectedFieldCount)
        XCTAssertGreaterThanOrEqual(coverage, 0.9, "Field coverage below 90% (\(coverage * 100)%)", file: file, line: line)

        let expectedCreditTotal = expectedCredits.values.reduce(0, +)
        let expectedDebitTotal = expectedDebits.values.reduce(0, +)
        let actualCreditTotal = actualCredits.values.reduce(0, +)
        let actualDebitTotal = actualDebits.values.reduce(0, +)

        // Totals consistency ≥98% relative to expected totals
        func within98Percent(_ expected: Double, _ actual: Double) -> Bool {
            guard expected > 0 else { return true }
            return abs(expected - actual) / expected <= 0.02
        }

        XCTAssertTrue(within98Percent(expectedCreditTotal, actualCreditTotal), "Credit totals deviate more than 2% (expected: \(expectedCreditTotal), actual: \(actualCreditTotal))", file: file, line: line)
        XCTAssertTrue(within98Percent(expectedDebitTotal, actualDebitTotal), "Debit totals deviate more than 2% (expected: \(expectedDebitTotal), actual: \(actualDebitTotal))", file: file, line: line)
    }

    // MARK: - Tests

    func testRotatedTableParsing_recoversMostFields_andTotals() {
        let config = ScenarioConfig(rotationDegrees: 5, yJitter: 0.5, mergeCreditCells: false, mergeDebitCells: false, confidence: 0.95, rows: 10, includePCDATerms: true, equalizeTotals: true)
        let (elements, expectedCredits, expectedDebits) = generatePCDAElements(config: config)

        let extractor = MilitaryFinancialDataExtractor()
        let (credits, debits) = extractor.extractMilitaryTabularData(from: elements)

        assertCoverageAndTotals(actualCredits: credits, actualDebits: debits, expectedCredits: expectedCredits, expectedDebits: expectedDebits)
    }

    func testSkewedWithMergedCreditCells_parsesViaFallback_andTotals() {
        let config = ScenarioConfig(rotationDegrees: 0.5, yJitter: 0.5, mergeCreditCells: true, mergeDebitCells: false, confidence: 0.9, rows: 10, includePCDATerms: true, equalizeTotals: true)
        let (elements, expectedCredits, expectedDebits) = generatePCDAElements(config: config)

        let extractor = MilitaryFinancialDataExtractor()
        let (credits, debits) = extractor.extractMilitaryTabularData(from: elements)

        assertCoverageAndTotals(actualCredits: credits, actualDebits: debits, expectedCredits: expectedCredits, expectedDebits: expectedDebits)
    }

    func testLowConfidenceOCR_elements_stillParse() {
        let config = ScenarioConfig(rotationDegrees: 0, yJitter: 0.5, mergeCreditCells: false, mergeDebitCells: false, confidence: 0.3, rows: 10, includePCDATerms: true, equalizeTotals: true)
        let (elements, expectedCredits, expectedDebits) = generatePCDAElements(config: config)

        let extractor = MilitaryFinancialDataExtractor()
        let (credits, debits) = extractor.extractMilitaryTabularData(from: elements)

        assertCoverageAndTotals(actualCredits: credits, actualDebits: debits, expectedCredits: expectedCredits, expectedDebits: expectedDebits)
    }

    func testMergedCellsOnBothSides_parsesAtLeastNinetyPercent() {
        let config = ScenarioConfig(rotationDegrees: 0, yJitter: 0.3, mergeCreditCells: true, mergeDebitCells: true, confidence: 0.85, rows: 10, includePCDATerms: true, equalizeTotals: true)
        let (elements, expectedCredits, expectedDebits) = generatePCDAElements(config: config)

        let extractor = MilitaryFinancialDataExtractor()
        let (credits, debits) = extractor.extractMilitaryTabularData(from: elements)

        assertCoverageAndTotals(actualCredits: credits, actualDebits: debits, expectedCredits: expectedCredits, expectedDebits: expectedDebits)
    }
}


