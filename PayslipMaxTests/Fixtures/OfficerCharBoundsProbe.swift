import CoreGraphics
import Foundation
import PDFKit

/// **Plan Phase 0 — de-risk spike (test-only, no production wiring).**
///
/// Proves that PDFKit `PDFPage.characterBounds(at:)` yields sane, monotonic X-bounds
/// for the ASCII financial tokens (`BPAY`, `144700`, `DSOP`, …) on the real *bilingual*
/// PCDA(O) officer PDFs. If that holds, the position-aware columnar extractor planned
/// for Phase 1+ is viable; if it doesn't, the whole approach is reconsidered before any
/// production code is written.
///
/// This lives entirely in the test target — it is never wired into the parsing pipeline.
/// Hindi (Devanagari) glyphs may come back garbled or with composed-cluster index drift;
/// that is acceptable, because the extractor keys off ASCII amount tokens + column X, not
/// the localized label strings.
enum OfficerCharBoundsProbe {
    /// One whitespace-delimited word reconstructed from per-character bounds.
    /// Coordinates are raw PDF page points (bottom-left origin, Y up) — the same space
    /// `PositionalElement` / `RowAssociator` operate in, so no normalization is needed.
    struct ProbedWord: Equatable {
        /// The concatenated character text of the word.
        let text: String
        /// Left edge of the unioned word bounds (`bounds.minX`).
        let x: CGFloat
        /// Bottom edge of the unioned word bounds (`bounds.minY`).
        let y: CGFloat
        /// Width of the unioned word bounds.
        let width: CGFloat
        /// Per-character left edges, in document order — used to assert monotonic X growth.
        let charMinXs: [CGFloat]

        /// Right edge of the word (`x + width`).
        var maxX: CGFloat { x + width }

        /// True when the word is composed only of digits, commas and dots — an amount token.
        var isAmount: Bool {
            let stripped = text.filter { !($0 == "," || $0 == ".") }
            return !stripped.isEmpty && stripped.allSatisfy { $0.isNumber }
        }

        /// True when the per-character left edges are non-decreasing left-to-right
        /// (the core property that proves `characterBounds` is geometrically coherent).
        func hasMonotonicXBounds(epsilon: CGFloat = 0.5) -> Bool {
            zip(charMinXs, charMinXs.dropFirst()).allSatisfy { $0 <= $1 + epsilon }
        }
    }

    /// Groups every character on `page` into whitespace-delimited words, unioning each
    /// word's per-character `characterBounds` into a single bounding box.
    ///
    /// - Parameter page: the page to probe (Phase 0 always uses page 0).
    /// - Returns: words in document order; empty if the page has no extractable text.
    static func words(on page: PDFPage) -> [ProbedWord] {
        let count = page.numberOfCharacters
        guard count > 0, let pageText = page.string else {
            return []
        }

        // PDFKit's character count and the Swift `String` character count can drift on
        // composed Devanagari clusters; iterate the safe overlap so we never index out of
        // range. ASCII tokens (the only ones we assert on) stay aligned.
        let chars = Array(pageText)
        let upper = min(count, chars.count)

        var words: [ProbedWord] = []
        var pending: [Character] = []
        var pendingXs: [CGFloat] = []
        var unioned: CGRect?

        func flush() {
            if let word = Self.makeWord(pending, pendingXs, unioned) {
                words.append(word)
            }
            pending = []; pendingXs = []; unioned = nil
        }

        for index in 0..<upper {
            let character = chars[index]
            if character.isWhitespace || character.isNewline {
                flush()
                continue
            }
            let bounds = page.characterBounds(at: index)
            // Skip glyphs PDFKit cannot place (common for some bilingual ligatures)
            // without breaking the surrounding ASCII word.
            guard !bounds.isNull, bounds.width.isFinite, bounds.height.isFinite else {
                continue
            }
            pending.append(character)
            pendingXs.append(bounds.minX)
            unioned = unioned.map { $0.union(bounds) } ?? bounds
        }
        flush()
        return words
    }

    /// Builds a `ProbedWord` from an accumulated character run, or `nil` for an empty/null run.
    private static func makeWord(
        _ chars: [Character],
        _ xs: [CGFloat],
        _ rect: CGRect?
    ) -> ProbedWord? {
        guard !chars.isEmpty, let rect, !rect.isNull else {
            return nil
        }
        return ProbedWord(
            text: String(chars), x: rect.minX, y: rect.minY, width: rect.width, charMinXs: xs
        )
    }

    /// Words sharing `anchor`'s row (within `tolerance` points on Y), excluding the anchor.
    static func rowMates(
        of anchor: ProbedWord,
        in words: [ProbedWord],
        tolerance: CGFloat = 6
    ) -> [ProbedWord] {
        words.filter { $0 != anchor && abs($0.y - anchor.y) <= tolerance }
    }
}
