import CoreGraphics
import Foundation

/// Orchestrates the position-aware columnar parse: financial page → tokens → rows →
/// calibrate → pair → totals semantics → `OfficerColumnarResult`.
///
/// Each stage can veto the parse (returning `nil`), which the pipeline treats as a
/// signal to fall back to the existing cascade. No regex over reading-order text, no
/// LLM, no network — fully offline.
@MainActor
final class OfficerColumnarExtractor: OfficerColumnarExtractorProtocol {
    private let tokenExtractor: CGPDFTokenExtractorProtocol
    private let calibrator = ColumnBandCalibrator()
    private let pairer = ColumnarLineItemPairer()
    private let semantics = OfficerTotalsSemantics()

    init(tokenExtractor: CGPDFTokenExtractorProtocol = CGPDFTokenExtractor()) {
        self.tokenExtractor = tokenExtractor
    }

    // MARK: - OfficerColumnarExtractorProtocol

    /// Max pages to span when gathering the financial section (line items + totals).
    private static let maxFinancialPages = 4
    /// Per-page vertical offset so gathered pages stack without baseline collisions.
    private static let pageStackHeight: CGFloat = 1000

    func extract(from document: CGPDFDocument) async -> OfficerColumnarResult? {
        guard let index = tokenExtractor.financialPageIndex(in: document) else {
            return nil
        }
        return await extract(from: gatherFinancialElements(from: document, startIndex: index))
    }

    /// Collects tokens from the financial page; when its totals row is on a later page (the
    /// multi-page arrears layout puts line items and totals on separate pages), appends the
    /// following pages — each shifted down by `pageStackHeight` so their rows never collide —
    /// until the totals labels appear or the page budget is spent.
    private func gatherFinancialElements(from document: CGPDFDocument, startIndex: Int) -> [PositionalElement] {
        var gathered: [PositionalElement] = []
        for offset in 0..<Self.maxFinancialPages {
            let pageNumber = startIndex + offset
            guard pageNumber < document.numberOfPages, let page = document.page(at: pageNumber + 1) else {
                break
            }
            let shift = -CGFloat(offset) * Self.pageStackHeight
            gathered += tokenExtractor.elements(on: page, pageIndex: startIndex).map { shifted($0, by: shift) }
            if hasTotalsLabels(gathered) {
                break
            }
        }
        return gathered
    }

    private func hasTotalsLabels(_ elements: [PositionalElement]) -> Bool {
        elements.contains { OfficerColumnarLabels.isCreditTotal($0.text) }
            && elements.contains { OfficerColumnarLabels.isDebitTotal($0.text) }
    }

    private func shifted(_ element: PositionalElement, by dy: CGFloat) -> PositionalElement {
        guard dy != 0 else {
            return element
        }
        var bounds = element.bounds
        bounds.origin.y += dy
        return PositionalElement(
            text: element.text, bounds: bounds, type: element.type,
            confidence: element.confidence, fontSize: element.fontSize, pageIndex: element.pageIndex
        )
    }

    func extract(from elements: [PositionalElement]) async -> OfficerColumnarResult? {
        let rows = ColumnarRowGrouper.group(elements)
        guard let bands = calibrator.calibrate(rows: rows, elements: elements),
              let totals = semantics.read(rows: rows),
              let resolved = semantics.resolve(totals) else {
            return nil
        }
        let items = pairer.pair(rows: rows, bands: bands)
        return OfficerColumnarResult(
            earnings: items.earnings,
            deductions: items.deductions,
            grossPay: totals.gross,
            totalDeductions: resolved.trueDeductions,
            netRemittance: resolved.net,
            template: resolved.template
        )
    }
}
