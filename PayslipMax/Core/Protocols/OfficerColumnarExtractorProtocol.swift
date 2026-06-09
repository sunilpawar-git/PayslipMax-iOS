import CoreGraphics
import Foundation

/// Deterministic, offline, position-aware extractor for PCDA(O) officer payslips.
///
/// Operates on the geometry recovered by `CGPDFTokenExtractor`: it calibrates the
/// credit/debit amount columns from the totals row, pairs every line item with its
/// own-side label, and resolves the printed-totals template — all vocabulary-free.
/// Returns `nil` whenever calibration or totals reading fails, so the caller falls
/// back to the existing `HybridPayslipProcessor` cascade rather than shipping a guess.
///
/// `@MainActor` because the row clustering it composes (`RowAssociator`) is main-actor
/// isolated. The document overload assumes an **already-unlocked** `CGPDFDocument`.
@MainActor
protocol OfficerColumnarExtractorProtocol {
    /// Extracts from an already-unlocked document, detecting the financial page itself.
    func extract(from document: CGPDFDocument) async -> OfficerColumnarResult?

    /// Extracts from pre-extracted positional elements — the unit-testable core that
    /// needs no PDF (drives the CI synthetic-fixture path).
    func extract(from elements: [PositionalElement]) async -> OfficerColumnarResult?
}
