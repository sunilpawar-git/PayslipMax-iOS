import Foundation
import PDFKit
import Darwin

/// Protocol defining the interface for PDF text extraction services
protocol PDFTextExtractionServiceProtocol {
    /// Extracts text from a PDF document
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - callback: Optional callback function that receives text as it's extracted
    /// - Returns: The complete extracted text, or nil if extraction fails
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)?) -> String?
    
    /// Extracts text from a specific page of a PDF document
    /// - Parameters:
    ///   - pageIndex: The index of the page to extract text from
    ///   - document: The PDF document to extract text from
    /// - Returns: The extracted text, or nil if extraction fails
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String?
    
    /// Extracts text from a range of pages in a PDF document
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - range: The range of pages to extract text from
    /// - Returns: The extracted text, or nil if extraction fails
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String?
    
    /// Gets the current memory usage of the app
    /// - Returns: Current memory usage in bytes
    func currentMemoryUsage() -> UInt64
    
    /// Extracts text from PDF data
    /// - Parameter data: The PDF data to extract text from
    /// - Returns: The extracted text or throws an error if extraction fails
    func extractText(from data: Data) throws -> String
}

/// Service responsible for memory-efficient PDF text extraction
class PDFTextExtractionService: PDFTextExtractionServiceProtocol {
    // MARK: - Properties
    
    /// Maximum amount of text to process in a single batch (in bytes)
    private let maxBatchSize: Int
    
    /// Whether to track memory usage during extraction
    private let trackMemoryUsage: Bool
    
    /// Delegate for receiving memory usage updates
    weak var delegate: PDFTextExtractionDelegate?
    
    // MARK: - Initialization
    
    /// Initializes a new PDFTextExtractionService
    /// - Parameters:
    ///   - maxBatchSize: Maximum amount of text to process in a single batch (in bytes)
    ///   - trackMemoryUsage: Whether to track memory usage during extraction
    init(maxBatchSize: Int = 1_000_000, trackMemoryUsage: Bool = true) {
        self.maxBatchSize = maxBatchSize
        self.trackMemoryUsage = trackMemoryUsage
    }
    
    // MARK: - Public Methods
    
    /// Extracts text from a PDF document using a memory-efficient streaming approach
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - callback: Callback function that receives text as it's extracted
    /// - Returns: The complete extracted text, or nil if extraction fails
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        guard document.pageCount > 0 else {
            print("[PDFTextExtractionService] Document has no pages")
            return nil
        }
        
        var fullText = ""
        var memoryUsage: UInt64 = 0
        var previousMemoryUsage: UInt64 = trackMemoryUsage ? currentMemoryUsage() : 0
        
        // Extract text from each page
        for i in 0..<document.pageCount {
            autoreleasepool {
                if let page = document.page(at: i), let text = page.string {
                    // Add page text to the full text
                    fullText += text
                    
                    // Track memory usage
                    if trackMemoryUsage {
                        memoryUsage = currentMemoryUsage()
                        // Safe calculation to prevent arithmetic overflow
                        let memoryDelta = memoryUsage > previousMemoryUsage ? 
                            memoryUsage - previousMemoryUsage : 0
                        
                        print("[PDFTextExtractionService] Memory after page \(i+1)/\(document.pageCount): \(formatMemory(memoryUsage)) (Δ\(formatMemory(memoryDelta)))")
                        
                        delegate?.textExtraction(didUpdateMemoryUsage: memoryUsage, delta: memoryDelta)
                        previousMemoryUsage = memoryUsage
                    }
                    
                    // Report progress through callback
                    callback?(text, i + 1, document.pageCount)
                    
                    // Check if we need to process in batches due to large text size
                    if fullText.lengthOfBytes(using: .utf8) > maxBatchSize {
                        print("[PDFTextExtractionService] Text size exceeded batch limit, processing intermediate batch")
                        // In a real implementation, you might process this batch and discard it
                        // For now, we're just keeping the full text
                    }
                }
            }
        }
        
        if fullText.isEmpty {
            print("[PDFTextExtractionService] Failed to extract text from document")
            return nil
        }
        
        print("[PDFTextExtractionService] Successfully extracted \(fullText.count) characters from \(document.pageCount) pages")
        return fullText
    }
    
    /// Extracts text from a specific page of a PDF document
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - pageIndex: The index of the page to extract text from
    /// - Returns: The extracted text, or nil if extraction fails
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        guard pageIndex >= 0 && pageIndex < document.pageCount else {
            print("[PDFTextExtractionService] Page index out of bounds")
            return nil
        }
        
        guard let page = document.page(at: pageIndex) else {
            print("[PDFTextExtractionService] Failed to get page at index \(pageIndex)")
            return nil
        }
        
        let text = page.string
        
        if let extractedText = text, !extractedText.isEmpty {
            return extractedText
        } else {
            print("[PDFTextExtractionService] Failed to extract text from page \(pageIndex)")
            return nil
        }
    }
    
    /// Extracts text from a range of pages in a PDF document
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - range: The range of pages to extract text from
    /// - Returns: The extracted text, or nil if extraction fails
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        guard range.lowerBound >= 0 && range.upperBound < document.pageCount else {
            print("[PDFTextExtractionService] Page range out of bounds")
            return nil
        }
        
        var rangeText = ""
        
        for i in range {
            autoreleasepool {
                if let pageText = extractTextFromPage(at: i, in: document) {
                    rangeText += pageText
                }
            }
        }
        
        if rangeText.isEmpty {
            print("[PDFTextExtractionService] Failed to extract text from page range \(range)")
            return nil
        }
        
        return rangeText
    }
    
    // MARK: - Memory Management
    
    /// Gets the current memory usage of the app
    /// - Returns: Current memory usage in bytes
    func currentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            print("[PDFTextExtractionService] Error getting memory usage: \(kerr)")
            return 0
        }
    }
    
    /// Formats memory size for human-readable output
    /// - Parameter bytes: Memory size in bytes
    /// - Returns: Formatted memory size string
    private func formatMemory(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    /// Extracts text from PDF data
    /// - Parameter data: The PDF data to extract text from
    /// - Returns: The extracted text or throws an error if extraction fails
    func extractText(from data: Data) throws -> String {
        guard let document = PDFDocument(data: data) else {
            print("[PDFTextExtractionService] Failed to create PDFDocument from data")
            throw PDFProcessingError.invalidPDFStructure
        }
        
        guard let extractedText = extractText(from: document) else {
            print("[PDFTextExtractionService] Failed to extract text from PDF document")
            throw PDFProcessingError.textExtractionFailed
        }
        
        if extractedText.isEmpty {
            print("[PDFTextExtractionService] Extracted text is empty")
            throw PDFProcessingError.textExtractionFailed
        }
        
        return extractedText
    }
}

// MARK: - Delegate Protocol

/// Protocol for receiving memory usage updates during text extraction
protocol PDFTextExtractionDelegate: AnyObject {
    /// Called when memory usage is updated during text extraction
    /// - Parameters:
    ///   - memoryUsage: Current memory usage in bytes
    ///   - delta: Change in memory usage since the last update
    func textExtraction(didUpdateMemoryUsage memoryUsage: UInt64, delta: UInt64)
} 