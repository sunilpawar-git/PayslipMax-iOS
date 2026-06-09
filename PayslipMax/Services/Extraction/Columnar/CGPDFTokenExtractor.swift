import CoreGraphics
import Foundation

// swiftlint:disable no_hardcoded_strings
// The only string literals here are PDF resource keys / financial-page anchor prefixes
// (BPAY/BASIC/DSOP), which are content markers, not user-facing copy.

/// Production port of the Phase 0.5 `CGPDFScanner` spike. Reads a PDF page's content
/// stream — tracking the CTM + text matrix and recursing into Form XObjects — and emits
/// `PositionalElement`s in raw PDF page points for the position-aware columnar pipeline.
///
/// See `CGPDFTokenExtractorProtocol` for the rationale (PDFKit `characterBounds` mangles
/// these bilingual PCDA(O) PDFs; the content-stream `Tm` per token does not).
final class CGPDFTokenExtractor: CGPDFTokenExtractorProtocol {
    /// Earnings-label prefixes used to recognize the financial page.
    private static let creditPrefixes = ["BPAY", "BASIC"]
    /// Deduction-label prefix used to recognize the financial page.
    private static let debitPrefix = "DSOP"

    init() {}

    // MARK: - CGPDFTokenExtractorProtocol

    func elements(on page: CGPDFPage, pageIndex: Int) -> [PositionalElement] {
        rawTokens(on: page).map { token in element(from: token, pageIndex: pageIndex) }
    }

    func financialPageIndex(in document: CGPDFDocument) -> Int? {
        for index in 1...max(1, document.numberOfPages) {
            guard let page = document.page(at: index) else { continue }
            let upper = rawTokens(on: page).map { $0.text.uppercased() }
            let hasCredit = upper.contains { text in
                Self.creditPrefixes.contains { text.hasPrefix($0) }
            }
            let hasDebit = upper.contains { $0.hasPrefix(Self.debitPrefix) }
            if hasCredit && hasDebit {
                return index - 1
            }
        }
        return nil
    }

    // MARK: - Scanning

    /// Scans `page`'s content stream and returns every ASCII token in document order.
    private func rawTokens(on page: CGPDFPage) -> [ColumnarRawToken] {
        let scan = CGPDFTokenScanState(table: CGPDFTextOperators.table())
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

    // MARK: - Conversion

    /// Builds a `PositionalElement` from a raw token. The scanner reports the text origin
    /// (baseline-left); a nominal bounds is synthesized from the device text scale so that
    /// `RowAssociator` (which clusters on `bounds.midY`) groups same-baseline tokens and so
    /// later pairing can compare left-X. Width uses an average half-em advance per glyph.
    private func element(from token: ColumnarRawToken, pageIndex: Int) -> PositionalElement {
        let height = max(token.scaleY, 1)
        let width = max(CGFloat(token.text.count) * token.scaleX * 0.5, 1)
        let bounds = CGRect(x: token.x, y: token.y, width: width, height: height)
        let isAmount = Self.isAmount(token.text)
        return PositionalElement(
            text: token.text,
            bounds: bounds,
            type: isAmount ? .value : .label,
            confidence: 1.0,
            fontSize: Double(token.scaleY),
            pageIndex: pageIndex
        )
    }

    /// True for digit groups (with optional thousands/decimal separators) — an amount.
    /// Rejects mixed tokens like `(12A)` so the suffix-grabbing bug cannot recur.
    static func isAmount(_ text: String) -> Bool {
        let stripped = text.filter { $0 != "," && $0 != "." }
        return !stripped.isEmpty && stripped.allSatisfy { $0.isNumber }
    }
}

// swiftlint:enable no_hardcoded_strings
