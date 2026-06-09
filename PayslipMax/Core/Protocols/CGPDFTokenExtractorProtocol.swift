import CoreGraphics
import Foundation

/// Extracts per-token `(text, position)` geometry from a PDF page's **content stream**
/// via `CGPDFScanner`, tracking the CTM + text matrix and recursing into Form XObjects.
///
/// This is the production port of the Phase 0.5 de-risk spike (`OfficerColumnarProbe`):
/// PDFKit's `characterBounds(at:)` mangles bilingual PCDA(O) officer PDFs (scrambled char
/// order, inflated word boxes, collapsed rows), but the content-stream `Tm` translation per
/// `Tj`/`TJ` token yields clean, column-separated, same-row geometry. Emitted elements live
/// in raw PDF page points (bottom-left origin, Y up) — the space `RowAssociator` operates in.
///
/// Hindi (Devanagari) tokens use CID fonts that decode to garbage bytes; they are filtered
/// out so the extractor keys off ASCII labels + amounts. The document is assumed already
/// unlocked (the pipeline unlocks password-protected slips before extraction).
protocol CGPDFTokenExtractorProtocol {
    /// All ASCII positional elements on `page`, in content-stream (document) order.
    /// - Parameters:
    ///   - page: A `CGPDFPage` from an already-unlocked document.
    ///   - pageIndex: The 0-based index recorded on each emitted `PositionalElement`.
    /// - Returns: One `PositionalElement` per shown ASCII text token.
    func elements(on page: CGPDFPage, pageIndex: Int) -> [PositionalElement]

    /// First 0-based page index whose tokens contain both an earnings label and `DSOP`.
    ///
    /// The financial page is not always page 0: multi-page slips carry a cover page and put
    /// line items on a later page. Returns `nil` when no page qualifies (e.g. the document is
    /// still encrypted).
    func financialPageIndex(in document: CGPDFDocument) -> Int?
}
