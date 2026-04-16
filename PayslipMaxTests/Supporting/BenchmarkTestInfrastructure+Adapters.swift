import Foundation
import PDFKit
@testable import PayslipMax

// MARK: - PDFTextExtractionService Stub

class BenchmarkPDFTextExtractionService: PDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        var result = ""

        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                result += page.string ?? ""
                if i < document.pageCount - 1 {
                    result += "\n\n"
                }
            }
        }

        return result
    }

    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        guard pageIndex >= 0 && pageIndex < document.pageCount else { return nil }
        return document.page(at: pageIndex)?.string
    }

    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        var result = ""
        for i in range {
            if let page = document.page(at: i) {
                result += page.string ?? ""
            }
        }
        return result
    }

    func currentMemoryUsage() -> UInt64 {
        return 0
    }

    func extractText(from data: Data) throws -> String {
        guard let document = PDFDocument(data: data) else {
            throw NSError(domain: "BenchmarkPDFTextExtractionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF document from data"])
        }
        return extractText(from: document) ?? ""
    }
}

// MARK: - Required Protocols

protocol BenchmarkTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String
}

protocol BenchmarkPDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String
}

private struct StandardExtractor: BenchmarkPDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String {
        var text = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                text += page.string ?? ""
            }
        }
        return text
    }
}

private struct VisionExtractor: BenchmarkPDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) -> String {
        var text = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                text += page.string ?? ""
                text += " [Enhanced with Vision]"
            }
        }
        return text
    }
}

// MARK: - Adapters for Main Protocol

struct StandardTextExtractorAdapter: PDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        let start = CFAbsoluteTimeGetCurrent()
        let text = service.extractText(from: document, callback: callback)
        Thread.sleep(forTimeInterval: 0.5)
        let end = CFAbsoluteTimeGetCurrent()

        print("StandardExtractor time: \(end - start) seconds")
        return text
    }

    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        return service.extractTextFromPage(at: pageIndex, in: document)
    }

    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        return service.extractText(from: document, in: range)
    }

    func currentMemoryUsage() -> UInt64 {
        return 0
    }

    func extractText(from data: Data) throws -> String {
        let service = BenchmarkPDFTextExtractionService()
        return try service.extractText(from: data)
    }
}

struct VisionTextExtractorAdapter: PDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        let start = CFAbsoluteTimeGetCurrent()
        let text = service.extractText(from: document, callback: callback)
        Thread.sleep(forTimeInterval: 1.5)
        let end = CFAbsoluteTimeGetCurrent()

        print("VisionExtractor time: \(end - start) seconds")
        return text
    }

    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        Thread.sleep(forTimeInterval: 0.2)
        return service.extractTextFromPage(at: pageIndex, in: document)
    }

    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        let service = BenchmarkPDFTextExtractionService()
        Thread.sleep(forTimeInterval: 0.5)
        return service.extractText(from: document, in: range)
    }

    func currentMemoryUsage() -> UInt64 {
        return 10_000_000
    }

    func extractText(from data: Data) throws -> String {
        let service = BenchmarkPDFTextExtractionService()
        Thread.sleep(forTimeInterval: 0.3)
        return try service.extractText(from: data)
    }
}
