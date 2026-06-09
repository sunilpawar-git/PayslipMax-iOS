import CoreGraphics
@testable import PayslipMax
import XCTest

/// **Plan Phase 0.5 — BLOCKING de-risk spike (CGPDF approach).**
///
/// Drives `OfficerColumnarProbe` over the real bilingual PCDA(O) officer PDFs and proves
/// the content-stream `CGPDFScanner` path yields clean, column-separated, same-row
/// `label → amount` geometry — the property the position-aware columnar extractor needs,
/// which PDFKit's `characterBounds(at:)` failed to provide.
///
/// Real PDFs carry PII and are never committed. Point the test at a local folder via the
/// `OFFICER_PDF_DIR` environment variable (Edit Scheme → Test → Arguments → Environment
/// Variables); set `OFFICER_PDF_PASSWORD` if the slips are password-protected. When
/// `OFFICER_PDF_DIR` is unset — as on CI — the test `XCTSkip`s. No amount value is asserted
/// or logged, so no financial PII enters the committed assertions.
final class OfficerColumnarProbeTests: XCTestCase {
    private static let creditPrefixes = ["BPAY", "BASIC"]
    private static let debitPrefixes = ["DSOP"]
    private static let rowTolerance: CGFloat = 4

    func test_realOfficerPDFs_columnarGeometryIsClean() throws {
        let urls = try Self.localOfficerPDFURLs()
        let password = ProcessInfo.processInfo.environment["OFFICER_PDF_PASSWORD"]
        for url in urls {
            probe(url, password: password)
        }
    }

    // MARK: - Per-PDF probe

    private func probe(_ url: URL, password: String?) {
        let name = url.lastPathComponent
        guard let provider = CGDataProvider(url: url as CFURL) else {
            XCTFail("\(name): could not create data provider")
            return
        }
        guard let document = CGPDFDocument(provider) else {
            XCTFail("\(name): could not open as CGPDFDocument")
            return
        }
        if document.isEncrypted, !document.isUnlocked, let password {
            _ = document.unlockWithPassword(password)
        }
        guard let pageIndex = OfficerColumnarProbe.financialPageIndex(in: document) else {
            XCTFail("\(name): no financial page found (encrypted without OFFICER_PDF_PASSWORD?)")
            return
        }
        guard let page = document.page(at: pageIndex + 1) else {
            XCTFail("\(name): financial page \(pageIndex) missing")
            return
        }
        let tokens = OfficerColumnarProbe.tokens(on: page)
        XCTAssertFalse(tokens.isEmpty, "\(name): no tokens on financial page \(pageIndex)")
        Self.dump(tokens, page: pageIndex, name: name)

        assertPairing(Self.creditPrefixes, in: tokens, kind: "credit", name: name)
        assertPairing(Self.debitPrefixes, in: tokens, kind: "debit", name: name)
    }

    /// A known label is present and has an amount token to its right on the same row.
    private func assertPairing(
        _ prefixes: [String],
        in tokens: [OfficerColumnarProbe.Token],
        kind: String,
        name: String
    ) {
        guard let label = tokens.first(where: { token in
            let upper = token.text.uppercased()
            return prefixes.contains { upper.hasPrefix($0) }
        }) else {
            XCTFail("\(name): no \(kind) label \(prefixes) among tokens")
            return
        }
        let amount = tokens
            .filter { abs($0.y - label.y) <= Self.rowTolerance && $0.x > label.x && $0.isAmount }
            .min { $0.x < $1.x }
        XCTAssertNotNil(
            amount,
            "\(name): no amount to the right of \(kind) label '\(label.text)' on its row"
        )
    }

    // MARK: - Local fixture discovery

    private static func localOfficerPDFURLs() throws -> [URL] {
        let raw = ProcessInfo.processInfo.environment["OFFICER_PDF_DIR"] ?? ""
        let dir = raw.trimmingCharacters(in: .whitespaces)
        guard !dir.isEmpty else {
            throw XCTSkip(
                "Set OFFICER_PDF_DIR to a local folder of real officer PDFs to run the Phase 0.5 spike"
            )
        }
        let folder = URL(fileURLWithPath: dir, isDirectory: true)
        let contents = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        let pdfs = contents.filter { $0.pathExtension.lowercased() == "pdf" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        if pdfs.isEmpty {
            throw XCTSkip("OFFICER_PDF_DIR (\(dir)) contains no .pdf files")
        }
        return pdfs
    }

    /// Dumps per-token `(x, y, text)` so column X-bands can be eyeballed against the plan.
    private static func dump(_ tokens: [OfficerColumnarProbe.Token], page: Int, name: String) {
        print("=== OfficerColumnarProbe: \(name) page \(page) (\(tokens.count) tokens) ===")
        for token in tokens.sorted(by: { $0.y == $1.y ? $0.x < $1.x : $0.y > $1.y }) {
            let posX = String(format: "%.0f", token.x)
            let posY = String(format: "%.0f", token.y)
            print("  y=\(posY)\tx=\(posX)\t'\(token.text)'")
        }
    }
}
