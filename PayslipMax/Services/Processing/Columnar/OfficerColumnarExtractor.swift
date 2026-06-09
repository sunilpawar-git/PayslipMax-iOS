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
    /// Y-band tolerance for row clustering (matches the proven Phase 0.5 geometry).
    private let rowTolerance: CGFloat = 15

    init(tokenExtractor: CGPDFTokenExtractorProtocol = CGPDFTokenExtractor()) {
        self.tokenExtractor = tokenExtractor
    }

    // MARK: - OfficerColumnarExtractorProtocol

    func extract(from document: CGPDFDocument) async -> OfficerColumnarResult? {
        guard let index = tokenExtractor.financialPageIndex(in: document),
              let page = document.page(at: index + 1) else {
            return nil
        }
        return await extract(from: tokenExtractor.elements(on: page, pageIndex: index))
    }

    func extract(from elements: [PositionalElement]) async -> OfficerColumnarResult? {
        guard let rows = try? await RowAssociator().associateElementsIntoRows(elements, tolerance: rowTolerance),
              let bands = calibrator.calibrate(rows: rows, elements: elements),
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
