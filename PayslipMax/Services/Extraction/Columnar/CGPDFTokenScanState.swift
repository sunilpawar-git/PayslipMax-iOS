import CoreGraphics
import Foundation

/// A text token recovered from a PDF content stream, positioned in PDF page points
/// (bottom-left origin, Y up). `scaleX`/`scaleY` capture the effective glyph scale
/// (device text-space) so the extractor can synthesize a `PositionalElement` bounds.
struct ColumnarRawToken: Equatable {
    let text: String
    let x: CGFloat
    let y: CGFloat
    let scaleX: CGFloat
    let scaleY: CGFloat
}

/// Mutable scan state threaded through the `CGPDFScanner` C callbacks via an opaque
/// `info` pointer. Mirrors the proven Phase 0.5 spike state (`OfficerColumnarProbe.Scan`),
/// tracking the graphics + text matrices and the Form-XObject recursion stack.
final class CGPDFTokenScanState {
    var ctm = CGAffineTransform.identity
    var ctmStack: [CGAffineTransform] = []
    var textMatrix = CGAffineTransform.identity
    var lineMatrix = CGAffineTransform.identity
    var leading: CGFloat = 0
    var tokens: [ColumnarRawToken] = []
    var streamStack: [CGPDFContentStreamRef] = []
    var fallbackResources: CGPDFDictionaryRef?
    var depth = 0
    let table: CGPDFOperatorTableRef

    init(table: CGPDFOperatorTableRef) {
        self.table = table
    }

    /// Records a shown string at the current text origin, keeping only ASCII glyphs.
    func show(_ raw: String) {
        let clean = raw
            .filter { $0.isASCII && ($0.isLetter || $0.isNumber || " ()/.,-+:".contains($0)) }
            .trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else {
            return
        }
        let device = textMatrix.concatenating(ctm)
        tokens.append(
            ColumnarRawToken(
                text: clean,
                x: device.tx,
                y: device.ty,
                scaleX: hypot(device.a, device.b),
                scaleY: hypot(device.c, device.d)
            )
        )
    }
}
