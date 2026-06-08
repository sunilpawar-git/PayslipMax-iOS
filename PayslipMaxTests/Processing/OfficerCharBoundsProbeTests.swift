@testable import PayslipMax
import PDFKit
import XCTest

/// **Plan Phase 0 — BLOCKING de-risk spike.**
///
/// Drives `OfficerCharBoundsProbe` over the *real* bilingual PCDA(O) officer PDFs to
/// prove PDFKit's `characterBounds(at:)` is geometrically coherent (monotonic X within a
/// word; label-left / amount-right on a shared row). Only when this passes do we build the
/// position-aware columnar extractor.
///
/// The real PDFs carry PII, so they are **never committed**. Point the test at a local
/// folder of officer slips via the `OFFICER_PDF_DIR` environment variable (Edit Scheme →
/// Test → Arguments → Environment Variables). When the variable is unset — as on CI — every
/// case `XCTSkip`s, keeping the pipeline green. Nothing here asserts an amount *value*, so
/// no financial PII ever enters the committed assertions or logs.
final class OfficerCharBoundsProbeTests: XCTestCase {
    /// Known credit labels present on every officer slip across both layouts.
    private static let creditLabelPrefixes = ["BPAY", "BASIC"]
    /// Known debit label present on every officer slip across both layouts.
    private static let debitLabelPrefixes = ["DSOP"]

    func test_realOfficerPDFs_characterBoundsAreSane() throws {
        let urls = try Self.localOfficerPDFURLs()
        for url in urls {
            try probe(url)
        }
    }

    // MARK: - Per-PDF probe

    private func probe(_ url: URL) throws {
        guard let document = PDFDocument(url: url) else {
            XCTFail("Could not open PDF at \(url.lastPathComponent)")
            return
        }
        let page = try XCTUnwrap(document.page(at: 0), "\(url.lastPathComponent): no page 0")
        let words = OfficerCharBoundsProbe.words(on: page)

        XCTAssertFalse(words.isEmpty, "\(url.lastPathComponent): no words extracted from page 0")
        Self.dump(words, for: url)

        assertMonotonicXBounds(words, file: url)
        let creditLabel = try assertLabelPresent(Self.creditLabelPrefixes, in: words, file: url)
        _ = try assertLabelPresent(Self.debitLabelPrefixes, in: words, file: url)
        assertAmountRightOfLabel(creditLabel, in: words, file: url)
    }

    // MARK: - Assertions

    /// Every reconstructed word must have left-to-right increasing per-character X bounds —
    /// the property the columnar pairer relies on to split numeric vs label tokens.
    private func assertMonotonicXBounds(
        _ words: [OfficerCharBoundsProbe.ProbedWord],
        file url: URL
    ) {
        for word in words where word.charMinXs.count > 1 {
            XCTAssertTrue(
                word.hasMonotonicXBounds(),
                "\(url.lastPathComponent): non-monotonic X bounds for '\(word.text)' — \(word.charMinXs)"
            )
        }
    }

    /// A known label (matched case-insensitively by prefix) is present with sane geometry.
    @discardableResult
    private func assertLabelPresent(
        _ prefixes: [String],
        in words: [OfficerCharBoundsProbe.ProbedWord],
        file url: URL
    ) throws -> OfficerCharBoundsProbe.ProbedWord {
        let match = words.first { word in
            let upper = word.text.uppercased()
            return prefixes.contains { upper.hasPrefix($0) }
        }
        let label = try XCTUnwrap(
            match,
            "\(url.lastPathComponent): none of \(prefixes) found among extracted words"
        )
        XCTAssertGreaterThan(label.width, 0, "\(url.lastPathComponent): label '\(label.text)' has zero width")
        return label
    }

    /// On the credit label's row there is an amount token positioned to its right — proving
    /// label/amount column separation survives `characterBounds` (the Phase-1+ premise).
    private func assertAmountRightOfLabel(
        _ label: OfficerCharBoundsProbe.ProbedWord,
        in words: [OfficerCharBoundsProbe.ProbedWord],
        file url: URL
    ) {
        let amountOnRow = OfficerCharBoundsProbe
            .rowMates(of: label, in: words)
            .first { $0.isAmount && $0.x > label.maxX }
        XCTAssertNotNil(
            amountOnRow,
            "\(url.lastPathComponent): no amount token to the right of '\(label.text)' on its row"
        )
    }

    // MARK: - Local fixture discovery

    /// Resolves the local-only officer PDFs, or skips when `OFFICER_PDF_DIR` is unset/empty.
    private static func localOfficerPDFURLs() throws -> [URL] {
        let rawDir = ProcessInfo.processInfo.environment["OFFICER_PDF_DIR"] ?? ""
        let dir = rawDir.trimmingCharacters(in: .whitespaces)
        guard !dir.isEmpty else {
            throw XCTSkip(
                "Set OFFICER_PDF_DIR to a local folder of real officer PDFs to run the Phase 0 spike"
            )
        }
        let folder = URL(fileURLWithPath: dir, isDirectory: true)
        let contents = try FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil
        )
        let pdfs = contents.filter { $0.pathExtension.lowercased() == "pdf" }.sorted {
            $0.lastPathComponent < $1.lastPathComponent
        }
        if pdfs.isEmpty {
            throw XCTSkip("OFFICER_PDF_DIR (\(dir)) contains no .pdf files")
        }
        return pdfs
    }

    /// Dumps per-word `(text, x, y, w)` so the column X-bands can be eyeballed against the
    /// plan's layout table. Filenames only — never amount values — appear in the log.
    private static func dump(_ words: [OfficerCharBoundsProbe.ProbedWord], for url: URL) {
        print("=== OfficerCharBoundsProbe: \(url.lastPathComponent) (\(words.count) words) ===")
        for word in words {
            let minX = String(format: "%.1f", word.x)
            let minY = String(format: "%.1f", word.y)
            let width = String(format: "%.1f", word.width)
            print("  x=\(minX)\ty=\(minY)\tw=\(width)\t'\(word.text)'")
        }
    }
}
