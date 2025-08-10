import XCTest
import PDFKit
import UIKit
@testable import PayslipMax

final class SmokePerformanceTests: XCTestCase {
    private func generateMultiPagePDF(pageCount: Int, linesPerPage: Int) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("perf_smoke_\(UUID().uuidString).pdf")

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            for page in 1...pageCount {
                context.beginPage()
                let title = "Performance Smoke Test - Page \(page)"
                title.draw(at: CGPoint(x: 40, y: 40), withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 18)
                ])
                for line in 0..<linesPerPage {
                    let y = 80 + line * 18
                    let text = "Line \(line + 1): Sample content for performance testing, page=\(page)"
                    text.draw(at: CGPoint(x: 40, y: CGFloat(y)), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 12)
                    ])
                }
            }
        }

        do {
            try data.write(to: fileURL)
        } catch {
            XCTFail("Failed to write generated PDF: \(error)")
        }
        return fileURL
    }

    func testPerformanceSmoke_MultiPageGeneratedPDFs() async throws {
        // Generate 5 multi-page PDFs (12 pages each)
        let pdfURLs: [URL] = (0..<5).map { _ in generateMultiPagePDF(pageCount: 12, linesPerPage: 50) }

        let service = EnhancedTextExtractionService()
        var durations: [TimeInterval] = []

        for url in pdfURLs {
            guard let document = PDFDocument(url: url) else {
                XCTFail("Failed to load generated PDF at \(url)")
                continue
            }

            let start = Date()
            _ = await service.extractTextEnhanced(from: document)
            let duration = Date().timeIntervalSince(start)
            durations.append(duration)

            // Assert under 10 seconds per acceptance criteria
            XCTAssertLessThan(duration, 10.0, "Performance smoke failed for \(url.lastPathComponent): \(duration)s")

            // Log for reference
            print("[PerfSmoke] \(url.lastPathComponent) pages=\(document.pageCount) duration=\(String(format: "%.3f", duration))s")
        }

        // Basic sanity: ensure we actually processed 5 PDFs
        XCTAssertEqual(durations.count, 5)
    }
}


