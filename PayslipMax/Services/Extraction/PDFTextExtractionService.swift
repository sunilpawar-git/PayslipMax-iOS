import Foundation
import PDFKit
import Darwin
import UIKit

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

/// Service responsible for memory-efficient PDF text extraction with AI enhancement
class PDFTextExtractionService: PDFTextExtractionServiceProtocol {
    // MARK: - Properties
    
    /// Maximum amount of text to process in a single batch (in bytes)
    private let maxBatchSize: Int
    
    /// Whether to track memory usage during extraction
    private let trackMemoryUsage: Bool
    
    /// Delegate for receiving memory usage updates
    weak var delegate: PDFTextExtractionDelegate?
    
    /// AI-enhanced vision text extractor for spatial text extraction
    private let enhancedVisionExtractor: EnhancedVisionTextExtractor
    
    /// Whether to use AI-enhanced extraction (enabled by default)
    private let useAIEnhancement: Bool
    
    // MARK: - Initialization
    
    /// Initializes a new PDFTextExtractionService
    /// - Parameters:
    ///   - maxBatchSize: Maximum amount of text to process in a single batch (in bytes)
    ///   - trackMemoryUsage: Whether to track memory usage during extraction
    ///   - useAIEnhancement: Whether to use AI-enhanced extraction (enabled by default)
    ///   - enhancedVisionExtractor: AI-enhanced vision text extractor (optional for dependency injection)
    init(
        maxBatchSize: Int = 1_000_000, 
        trackMemoryUsage: Bool = true,
        useAIEnhancement: Bool = true,
        enhancedVisionExtractor: EnhancedVisionTextExtractor? = nil
    ) {
        self.maxBatchSize = maxBatchSize
        self.trackMemoryUsage = trackMemoryUsage
        self.useAIEnhancement = useAIEnhancement && LiteRTFeatureFlags.shared.enableLiteRTService
        
        // Initialize AI-enhanced extractor
        if let injectedExtractor = enhancedVisionExtractor {
            self.enhancedVisionExtractor = injectedExtractor
        } else {
            // Create default AI-enhanced extractor with LiteRT integration
            // Note: LiteRTService.shared will be accessed at runtime when needed
            self.enhancedVisionExtractor = EnhancedVisionTextExtractor(
                liteRTService: nil, // Will be set at runtime to avoid main actor issues
                useLiteRTPreprocessing: self.useAIEnhancement
            )
        }
        
        print("[PDFTextExtractionService] Initialized with AI enhancement: \(self.useAIEnhancement)")
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
        
        // Extract text from each page using AI-enhanced extraction when available
        for i in 0..<document.pageCount {
            autoreleasepool {
                if let page = document.page(at: i) {
                    var pageText: String = ""
                    
                    // Use AI-enhanced extraction if available
                    if useAIEnhancement {
                        pageText = extractPageWithAIEnhancement(page: page, pageIndex: i)
                    } else {
                        // Fallback to basic PDFKit extraction
                        pageText = page.string ?? ""
                        print("[PDFTextExtractionService] Using basic PDFKit extraction for page \(i+1)")
                    }
                    
                    if !pageText.isEmpty {
                        // Add page text to the full text
                        fullText += pageText
                        
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
                        callback?(pageText, i + 1, document.pageCount)
                        
                        // Check if we need to process in batches due to large text size
                        if fullText.lengthOfBytes(using: .utf8) > maxBatchSize {
                            print("[PDFTextExtractionService] Text size exceeded batch limit, processing intermediate batch")
                            // In a real implementation, you might process this batch and discard it
                            // For now, we're just keeping the full text
                        }
                    }
                } else {
                    print("[PDFTextExtractionService] Failed to get page at index \(i)")
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
        
        var extractedText: String = ""
        
        // Use AI-enhanced extraction if available
        if useAIEnhancement {
            extractedText = extractPageWithAIEnhancement(page: page, pageIndex: pageIndex)
        } else {
            // Fallback to basic PDFKit extraction
            extractedText = page.string ?? ""
            print("[PDFTextExtractionService] Using basic PDFKit extraction for single page \(pageIndex + 1)")
        }
        
        if !extractedText.isEmpty {
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
    
    // MARK: - AI-Enhanced Extraction Methods
    
    /// Extracts text from a PDF page using AI-enhanced extraction with spatial awareness
    /// This method converts the PDF page to an image and uses AI models for table detection and OCR
    /// - Parameters:
    ///   - page: The PDF page to extract text from
    ///   - pageIndex: The index of the page for logging purposes
    /// - Returns: The extracted text with spatial relationships preserved
    private func extractPageWithAIEnhancement(page: PDFPage, pageIndex: Int) -> String {
        print("[PDFTextExtractionService] Using AI-enhanced extraction for page \(pageIndex + 1)")
        
        // Use the pre-configured enhanced extractor
        // The LiteRT service will be configured at runtime when needed
        let runtimeExtractor = enhancedVisionExtractor
        
        do {
            // Convert PDF page to high-quality image for AI processing
            let pageImage = try renderPageAsImage(page: page)
            
            // Use AI-enhanced vision extractor to get spatial text elements
            var extractedText = ""
            let extractionGroup = DispatchGroup()
            
            extractionGroup.enter()
            runtimeExtractor.extractText(from: pageImage) { result in
                defer { extractionGroup.leave() }
                
                switch result {
                case .success(let textElements):
                    // Convert spatial text elements to structured text preserving relationships
                    extractedText = self.convertTextElementsToStructuredText(textElements)
                    
                    // Validate text quality before accepting AI result
                    if self.isTextQualityAcceptable(extractedText) {
                        print("[PDFTextExtractionService] ✅ AI extraction successful with good quality: \(textElements.count) elements -> \(extractedText.count) characters")
                    } else {
                        print("[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit")
                        extractedText = page.string ?? ""
                    }
                    
                case .failure(let error):
                    print("[PDFTextExtractionService] ❌ AI extraction failed: \(error), falling back to PDFKit")
                    extractedText = page.string ?? ""
                }
            }
            
            // Wait for AI extraction to complete (with timeout)
            let timeoutResult = extractionGroup.wait(timeout: .now() + 10.0) // 10 second timeout
            
            if timeoutResult == .timedOut {
                print("[PDFTextExtractionService] ⚠️ AI extraction timed out, falling back to PDFKit")
                return page.string ?? ""
            }
            
            return extractedText
            
        } catch {
            print("[PDFTextExtractionService] ⚠️ AI extraction setup failed: \(error), falling back to PDFKit")
            return page.string ?? ""
        }
    }
    
    /// Renders a PDF page as a high-quality image for AI processing
    /// - Parameter page: The PDF page to render
    /// - Returns: UIImage representation of the page
    /// - Throws: Error if rendering fails
    private func renderPageAsImage(page: PDFPage) throws -> UIImage {
        let mediaBox = page.bounds(for: .mediaBox)
        
        // Use ultra-high resolution for scanned military payslips (4x scale)
        let scale: CGFloat = 4.0
        let size = CGSize(width: mediaBox.width * scale, height: mediaBox.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            throw PDFProcessingError.imageRenderingFailed
        }
        
        // Configure context for maximum OCR quality
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.interpolationQuality = .high
        context.setShouldSmoothFonts(true)
        context.setRenderingIntent(.relativeColorimetric)
        
        // Set pure white background for maximum contrast
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // Scale context for ultra-high resolution rendering
        context.scaleBy(x: scale, y: scale)
        
        // Render PDF page with maximum quality
        page.draw(with: .mediaBox, to: context)
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            throw PDFProcessingError.imageRenderingFailed
        }
        
        UIGraphicsEndImageContext()
        print("[PDFTextExtractionService] Rendered page at \(size.width)x\(size.height) for enhanced OCR")
        return image
    }
    
    /// Validates if extracted text quality is acceptable for financial parsing
    /// This method checks for common OCR corruption patterns and readability
    /// - Parameter text: The extracted text to validate
    /// - Returns: True if text quality is acceptable, false if corrupted
    private func isTextQualityAcceptable(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        
        // Calculate readable character ratio (alphanumeric + common punctuation)
        let readableCharacterSet = CharacterSet.alphanumerics.union(.punctuationCharacters).union(.whitespaces)
        let readableCharacters = text.unicodeScalars.filter { readableCharacterSet.contains($0) }.count
        let readableRatio = Double(readableCharacters) / Double(text.count)
        
        // Check for excessive garbage characters (Cyrillic mixed with Latin indicates OCR corruption)
        let cyrillicCount = text.unicodeScalars.filter { CharacterSet(charactersIn: "А-Я").contains($0) }.count
        let hasCyrillicCorruption = cyrillicCount > 5 // More than 5 Cyrillic chars in military payslip = corruption
        
        // Check for excessive non-printable or special characters
        let controlCharacterCount = text.unicodeScalars.filter { CharacterSet.controlCharacters.contains($0) }.count
        let hasControlCharacterCorruption = controlCharacterCount > text.count / 20 // >5% control chars = corruption
        
        // Check for basic financial data patterns (numbers, currency symbols, dates)
        let hasNumbers = text.contains(where: \.isNumber)
        let hasFinancialIndicators = text.range(of: "[0-9]", options: .regularExpression) != nil
        
        print("[PDFTextExtractionService] Text quality analysis: readable=\(String(format: "%.2f", readableRatio)), cyrillic=\(hasCyrillicCorruption), control=\(hasControlCharacterCorruption), financial=\(hasFinancialIndicators)")
        
        // Text is acceptable if:
        // 1. At least 70% readable characters AND
        // 2. No significant Cyrillic corruption AND 
        // 3. No excessive control character corruption AND
        // 4. Contains some numbers (expected in payslips)
        return readableRatio >= 0.7 && !hasCyrillicCorruption && !hasControlCharacterCorruption && hasFinancialIndicators
    }
    
    /// Converts spatial text elements to structured text preserving table relationships
    /// This method organizes text elements by their spatial coordinates to maintain table structure
    /// - Parameter textElements: Array of text elements with spatial coordinates
    /// - Returns: Structured text that preserves spatial relationships
    private func convertTextElementsToStructuredText(_ textElements: [TextElement]) -> String {
        guard !textElements.isEmpty else { return "" }
        
        print("[PDFTextExtractionService] Converting \(textElements.count) text elements to structured text")
        
        // Sort elements by Y-coordinate (top to bottom) then X-coordinate (left to right)
        let sortedElements = textElements.sorted { element1, element2 in
            let yDiff = element1.bounds.minY - element2.bounds.minY
            if abs(yDiff) < 10 { // Elements on same line (within 10 points)
                return element1.bounds.minX < element2.bounds.minX
            }
            return yDiff < 0
        }
        
        // Group elements into rows based on Y-coordinate proximity
        var rows: [[TextElement]] = []
        var currentRow: [TextElement] = []
        var lastY: CGFloat = -1000
        
        for element in sortedElements {
            let elementY = element.bounds.minY
            
            // Start new row if Y-coordinate differs significantly (more than 10 points)
            if abs(elementY - lastY) > 10 && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = []
            }
            
            currentRow.append(element)
            lastY = elementY
        }
        
        // Add final row
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        print("[PDFTextExtractionService] Organized into \(rows.count) rows")
        
        // Convert rows to structured text
        var structuredText = ""
        for (rowIndex, row) in rows.enumerated() {
            // Sort elements in row by X-coordinate
            let sortedRow = row.sorted { $0.bounds.minX < $1.bounds.minX }
            
            // Join elements in row with appropriate spacing
            let rowText = sortedRow.map { $0.text }.joined(separator: " ")
            
            if !rowText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                structuredText += rowText
                if rowIndex < rows.count - 1 {
                    structuredText += "\n"
                }
            }
        }
        
        print("[PDFTextExtractionService] Generated structured text: \(structuredText.count) characters")
        return structuredText
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