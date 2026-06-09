import CoreGraphics
@testable import PayslipMax
import XCTest

/// **Local-only acceptance probe — the real-PDF "100% officers" check (plan Verification §2).**
///
/// Walks a year-wise folder of *real* officer PDFs and runs the exact production columnar
/// decision (`OfficerColumnarExtractor` → `OfficerColumnarReconciliationGate`) over each,
/// reporting per file whether the offline columnar path would accept it (parsed 100%
/// offline, no regex/LLM/network) or fall back, and — when it falls back — which stage
/// vetoed and by how much.
///
/// Real PDFs carry PII and are never committed; point the test at the local corpus via
/// `OFFICER_PDF_DIR` (recurses sub-folders), `OFFICER_PDF_PASSWORD` for the password. When
/// `OFFICER_PDF_DIR` is unset — as on CI — it `XCTSkip`s. Financial figures appear only in
/// local console output at runtime, never in committed source.
@MainActor
final class OfficerColumnarRealCorpusProbeTests: XCTestCase {
    private let extractor = OfficerColumnarExtractor()
    private let gate = OfficerColumnarReconciliationGate()

    func test_realOfficerCorpus_columnarAcceptanceRate() async throws {
        let config = try Self.corpusConfig()
        let urls = try Self.officerPDFURLs(under: config.dir)
        let password = config.password

        var accepted = 0
        var lines: [String] = []
        for url in urls {
            let outcome = await evaluate(url, password: password)
            if outcome.accepted { accepted += 1 }
            lines.append(outcome.line)
        }

        let total = urls.count
        let pct = total == 0 ? 0 : Int((Double(accepted) / Double(total) * 100).rounded())
        print("\n===== Officer columnar acceptance report (\(accepted)/\(total) = \(pct)%) =====")
        lines.forEach { print($0) }
        print("=====================================================================\n")

        XCTAssertGreaterThan(total, 0, "no PDFs discovered under OFFICER_PDF_DIR")
    }

    // MARK: - Per-PDF evaluation (mirrors the production .defense decision)

    private struct Outcome {
        let accepted: Bool
        let line: String
    }

    private func evaluate(_ url: URL, password: String?) async -> Outcome {
        let name = Self.shortName(url)
        guard let document = Self.openUnlocked(url, password: password) else {
            return Outcome(accepted: false, line: "❌ FALLBACK  \(name)  — could not open/unlock")
        }
        guard let result = await extractor.extract(from: document) else {
            return Outcome(accepted: false, line: "❌ FALLBACK  \(name)  — \(await Self.vetoStage(document))")
        }
        if gate.accept(result) {
            return Outcome(accepted: true, line: "✅ PARSED    \(name)  — \(Self.shape(result))")
        }
        return Outcome(accepted: false, line: "❌ FALLBACK  \(name)  — gate rejected: \(Self.deltas(result))")
    }

    // MARK: - Diagnostics

    /// Re-runs the early stages to name which one returned nil for a non-extracting slip.
    private static func vetoStage(_ document: CGPDFDocument) async -> String {
        let token = CGPDFTokenExtractor()
        guard let index = token.financialPageIndex(in: document),
              let page = document.page(at: index + 1) else {
            return "no financial page detected (earnings label + DSOP)"
        }
        let elements = token.elements(on: page, pageIndex: index)
        let rows = (try? await RowAssociator().associateElementsIntoRows(elements, tolerance: 15)) ?? []
        if ColumnarRows.totalsRow(rows) == nil {
            return "page \(index): no totals row (Gross/Total Credit + Total Deduction/Debit)"
        }
        return "page \(index): totals present but semantics unresolved (old-fold needs REMITTANCE)"
    }

    private static func shape(_ result: OfficerColumnarResult) -> String {
        "\(result.earnings.count) earn / \(result.deductions.count) ded, "
            + "\(result.template == .oldFolded ? "oldFolded" : "newDirect")"
    }

    private static func deltas(_ result: OfficerColumnarResult) -> String {
        let earn = result.earnings.values.reduce(0, +)
        let ded = result.deductions.values.reduce(0, +)
        let net = result.grossPay - result.totalDeductions
        return String(
            format: "Σearn %.0f vs gross %.0f (Δ%.0f) | Σded %.0f vs true %.0f (Δ%.0f) | net %.0f vs %.0f (Δ%.0f)",
            earn, result.grossPay, earn - result.grossPay,
            ded, result.totalDeductions, ded - result.totalDeductions,
            net, result.netRemittance, net - result.netRemittance
        )
    }

    // MARK: - Corpus discovery

    private static func openUnlocked(_ url: URL, password: String?) -> CGPDFDocument? {
        guard let provider = CGDataProvider(url: url as CFURL),
              let document = CGPDFDocument(provider) else {
            return nil
        }
        if document.isEncrypted, !document.isUnlocked, let password {
            _ = document.unlockWithPassword(password)
        }
        return document.isUnlocked ? document : nil
    }

    /// `2024/08 Aug 2024.pdf` → `2024/08 Aug 2024` (parent folder + file stem).
    private static func shortName(_ url: URL) -> String {
        let stem = url.deletingPathExtension().lastPathComponent
        let parent = url.deletingLastPathComponent().lastPathComponent
        return "\(parent)/\(stem)".padding(toLength: 26, withPad: " ", startingAt: 0)
    }

    /// Resolves the corpus dir + password from `OFFICER_PDF_DIR`/`OFFICER_PDF_PASSWORD`, or
    /// — since xcodebuild doesn't forward host env to the simulator — from a gitignored
    /// `.officer_corpus` file at the repo root (line 1 = absolute dir, line 2 = password).
    private static func corpusConfig(file: StaticString = #filePath) throws -> (dir: String, password: String?) {
        let env = ProcessInfo.processInfo.environment
        if let dir = env["OFFICER_PDF_DIR"]?.trimmingCharacters(in: .whitespaces), !dir.isEmpty {
            return (dir, env["OFFICER_PDF_PASSWORD"])
        }
        let configURL = repoRoot(from: file).appendingPathComponent(".officer_corpus")
        guard let raw = try? String(contentsOf: configURL, encoding: .utf8) else {
            throw XCTSkip("Set OFFICER_PDF_DIR or create <repo>/.officer_corpus (line1=dir, line2=password)")
        }
        let lines = raw.split(separator: "\n", omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        guard let dir = lines.first, !dir.isEmpty else {
            throw XCTSkip(".officer_corpus is empty")
        }
        let password = lines.count > 1 && !lines[1].isEmpty ? lines[1] : nil
        return (dir, password)
    }

    /// Walks up from the test source file (`…/PayslipMaxTests/Processing/<this>`) to the repo root.
    private static func repoRoot(from file: StaticString) -> URL {
        URL(fileURLWithPath: "\(file)")
            .deletingLastPathComponent()  // Processing
            .deletingLastPathComponent()  // PayslipMaxTests
            .deletingLastPathComponent()  // repo root
    }

    private static func officerPDFURLs(under dir: String) throws -> [URL] {
        let root = URL(fileURLWithPath: dir, isDirectory: true)
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        let all = (enumerator?.allObjects as? [URL]) ?? []
        let pdfs = all.filter { $0.pathExtension.lowercased() == "pdf" }
            .sorted { $0.path < $1.path }
        if pdfs.isEmpty {
            throw XCTSkip("corpus dir (\(dir)) contains no .pdf files")
        }
        return pdfs
    }
}
