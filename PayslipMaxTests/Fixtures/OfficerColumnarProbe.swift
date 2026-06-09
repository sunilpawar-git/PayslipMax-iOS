import CoreGraphics
import Foundation

/// **Plan Phase 0.5 — de-risk spike (test-only, no production wiring).**
///
/// Recovers per-token `(text, x, y)` from a PDF page's content stream via `CGPDFScanner`,
/// tracking the CTM + text matrix and recursing into Form XObjects. This is the approach
/// proven viable for the position-aware officer columnar extractor — PDFKit's
/// `characterBounds(at:)` mangles these bilingual PCDA(O) PDFs, but the content-stream
/// `Tm` translation per `Tj`/`TJ` gives clean, column-separated, same-row geometry that
/// matches the plan's coordinate table exactly.
///
/// Hindi (Devanagari) tokens use CID fonts that decode to garbage bytes; they are filtered
/// out and the extractor keys off ASCII amount tokens + column X, as planned.
enum OfficerColumnarProbe {
    /// A token recovered from the content stream, positioned in PDF page points
    /// (bottom-left origin, Y up) — the space `RowAssociator` already operates in.
    struct Token: Equatable {
        let text: String
        let x: CGFloat
        let y: CGFloat

        /// True for digit groups (with optional separators) — an amount.
        var isAmount: Bool {
            let stripped = text.filter { $0 != "," && $0 != "." }
            return !stripped.isEmpty && stripped.allSatisfy { $0.isNumber }
        }
    }

    /// All ASCII tokens on `page`, in document order.
    static func tokens(on page: CGPDFPage) -> [Token] {
        let scan = Scan(table: PDFTextOps.table())
        if let dict = page.dictionary {
            var resources: CGPDFDictionaryRef?
            if CGPDFDictionaryGetDictionary(dict, "Resources", &resources) {
                scan.fallbackResources = resources
            }
        }
        let stream = CGPDFContentStreamCreateWithPage(page)
        scan.streamStack.append(stream)
        let scanner = CGPDFScannerCreate(stream, scan.table, Unmanaged.passUnretained(scan).toOpaque())
        CGPDFScannerScan(scanner)
        CGPDFScannerRelease(scanner)
        CGPDFContentStreamRelease(stream)
        return scan.tokens
    }

    /// First 0-based page index whose tokens contain both an earnings label and `DSOP`
    /// (the financial page is not always page 0 on multi-page slips), or `nil`.
    static func financialPageIndex(in document: CGPDFDocument) -> Int? {
        for index in 1...max(1, document.numberOfPages) {
            guard let page = document.page(at: index) else { continue }
            let upper = tokens(on: page).map { $0.text.uppercased() }
            let hasCredit = upper.contains { $0.hasPrefix("BPAY") || $0.hasPrefix("BASIC") }
            let hasDebit = upper.contains { $0.hasPrefix("DSOP") }
            if hasCredit && hasDebit {
                return index - 1
            }
        }
        return nil
    }

    /// Mutable scan state threaded through the C callbacks via an opaque `info` pointer.
    final class Scan {
        var ctm = CGAffineTransform.identity
        var ctmStack: [CGAffineTransform] = []
        var textMatrix = CGAffineTransform.identity
        var lineMatrix = CGAffineTransform.identity
        var leading: CGFloat = 0
        var tokens: [Token] = []
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
            tokens.append(Token(text: clean, x: device.tx, y: device.ty))
        }
    }
}
