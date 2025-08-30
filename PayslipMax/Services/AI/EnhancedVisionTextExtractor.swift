import Foundation
import Vision
import CoreGraphics
@preconcurrency import PDFKit
import UIKit

/// Enhanced Vision text extractor with LiteRT preprocessing integration
public class EnhancedVisionTextExtractor: VisionTextExtractorProtocol {
    
    // MARK: - Properties
    
    private let baseExtractor: VisionTextExtractor
    private let liteRTService: LiteRTServiceProtocol?
    private let tableDetector: TableStructureDetectorProtocol
    private let useLiteRTPreprocessing: Bool
    
    // MARK: - Initialization
    
    /// Initialize with LiteRT integration
    /// - Parameters:
    ///   - baseExtractor: The base Vision text extractor
    ///   - liteRTService: LiteRT service for AI preprocessing
    ///   - tableDetector: Table structure detector
    ///   - useLiteRTPreprocessing: Whether to use LiteRT preprocessing
    public init(
        baseExtractor: VisionTextExtractor = VisionTextExtractor(),
        liteRTService: LiteRTServiceProtocol? = nil,
        tableDetector: TableStructureDetectorProtocol = TableStructureDetector(),
        useLiteRTPreprocessing: Bool = true
    ) {
        self.baseExtractor = baseExtractor
        // Handle main actor isolation by keeping service optional
        self.liteRTService = liteRTService
        self.tableDetector = tableDetector
        self.useLiteRTPreprocessing = useLiteRTPreprocessing
        
        print("[EnhancedVisionTextExtractor] Initialized with LiteRT integration: \(useLiteRTPreprocessing)")
    }
    
    // MARK: - VisionTextExtractorProtocol Implementation
    
    /// Extract text from image with optional LiteRT preprocessing
    nonisolated public func extractText(from image: UIImage, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) {
        
        Task {
            guard useLiteRTPreprocessing else {
                // Fallback to base extractor if LiteRT is not available
                print("[EnhancedVisionTextExtractor] Using base Vision extractor (LiteRT not available)")
                baseExtractor.extractText(from: image, completion: completion)
                return
            }
            
            print("[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing")
            do {
                // Step 1: Use LiteRT for table structure analysis
                let tableStructure = try await tableDetector.detectTableStructure(in: image)
                
                // Step 2: Apply table-aware preprocessing (using LiteRT structure)
                let preprocessedImage = try await applyTableAwarePreprocessing(
                    image: image,
                    tableStructure: tableStructure
                )
                
                // Step 3: Extract text using enhanced Vision processing (using LiteRT structure)
                try await performEnhancedTextExtraction(
                    from: preprocessedImage,
                    tableStructure: tableStructure,
                    completion: completion
                )
                
            } catch {
                print("[EnhancedVisionTextExtractor] Enhanced extraction failed, falling back to base extractor: \(error)")
                baseExtractor.extractText(from: image, completion: completion)
            }
        }
    }
    
    /// Extract text from PDF document with enhanced processing
    nonisolated public func extractText(from pdfDocument: PDFDocument, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) {
        extractText(from: pdfDocument, progressHandler: nil, completion: completion)
    }
    
    /// Extract text from PDF document with progress tracking and enhanced processing
    nonisolated public func extractText(from pdfDocument: PDFDocument, progressHandler: ((Double) -> Void)?, completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void) {
        
        Task {
            guard useLiteRTPreprocessing else {
                // Fallback to base extractor
                baseExtractor.extractText(from: pdfDocument, progressHandler: progressHandler, completion: completion)
                return
            }
            
            print("[EnhancedVisionTextExtractor] Processing PDF with enhanced extraction")
            do {
                var allTextElements: [TextElement] = []
                let totalPages = pdfDocument.pageCount
                
                for pageIndex in 0..<totalPages {
                    guard let page = pdfDocument.page(at: pageIndex) else { continue }
                    
                    // Convert page to image
                    let pageImage = try await renderPageAsImage(page: page)
                    
                    // Process with enhanced extraction
                    let pageElements = try await extractTextElementsWithLiteRT(from: pageImage, pageOffset: pageIndex)
                    allTextElements.append(contentsOf: pageElements)
                    
                    // Update progress
                    progressHandler?(Double(pageIndex + 1) / Double(totalPages))
                }
                
                completion(.success(allTextElements))
                
            } catch {
                print("[EnhancedVisionTextExtractor] Enhanced PDF extraction failed: \(error)")
                baseExtractor.extractText(from: pdfDocument, progressHandler: progressHandler, completion: completion)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Apply table-aware preprocessing to improve OCR accuracy
    private func applyTableAwarePreprocessing(image: UIImage, tableStructure: LiteRTTableStructure) async throws -> UIImage {
        
        guard tableStructure.isPCDAFormat else {
            // For non-PCDA formats, return original image
            return image
        }
        
        print("[EnhancedVisionTextExtractor] Applying PCDA-specific preprocessing")
        
        // Convert to legacy format for existing methods
        let convertedStructure = convertLiteRTToTableStructure(tableStructure)
        
        // Create table mask to suppress right-panel contamination
        let tableMask = createTableMask(for: convertedStructure, imageSize: image.size)
        
        // Apply mask to image
        let maskedImage = try await applyTableMask(to: image, mask: tableMask)
        
        // Enhance table regions for better OCR
        let enhancedImage = try await enhanceTableRegions(image: maskedImage, tableStructure: convertedStructure)
        
        return enhancedImage
    }
    
    /// Create a mask to isolate table regions and suppress contamination
    private func createTableMask(for tableStructure: TableStructure, imageSize: CGSize) -> UIImage {
        
        // Create a mask image with table regions highlighted
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Fill background with black (masked areas)
            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: imageSize))
            
            // Fill table bounds with white (unmasked areas)
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(tableStructure.bounds)
            
            // Create additional masks for important regions
            for column in tableStructure.columns {
                cgContext.setFillColor(UIColor.white.cgColor)
                cgContext.fill(column.bounds)
            }
        }
    }
    
    /// Apply table mask to image
    private func applyTableMask(to image: UIImage, mask: UIImage) async throws -> UIImage {
        
        guard let imageCI = CIImage(image: image),
              let maskCI = CIImage(image: mask) else {
            throw VisionTextExtractionError.imageConversionFailed
        }
        
        // Apply mask using Core Image
        let filter = CIFilter.blendWithMask()
        filter.inputImage = imageCI
        filter.backgroundImage = CIImage(color: .white).cropped(to: imageCI.extent)
        filter.maskImage = maskCI
        
        guard let outputImage = filter.outputImage,
              let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            throw VisionTextExtractionError.imageConversionFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Enhance table regions for better OCR accuracy
    private func enhanceTableRegions(image: UIImage, tableStructure: TableStructure) async throws -> UIImage {
        
        guard let ciImage = CIImage(image: image) else {
            throw VisionTextExtractionError.imageConversionFailed
        }
        
        // Apply contrast enhancement to table regions
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = ciImage
        contrastFilter.contrast = 1.2 // Increase contrast slightly
        contrastFilter.brightness = 0.1 // Slight brightness increase
        
        // Apply sharpening for text clarity
        let sharpenFilter = CIFilter.sharpenLuminance()
        sharpenFilter.inputImage = contrastFilter.outputImage
        sharpenFilter.sharpness = 0.4
        
        guard let outputImage = sharpenFilter.outputImage,
              let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            throw VisionTextExtractionError.imageConversionFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Perform enhanced text extraction with LiteRT guidance
    private func performEnhancedTextExtraction(
        from image: UIImage,
        tableStructure: LiteRTTableStructure,
        completion: @escaping (Result<[TextElement], VisionTextExtractionError>) -> Void
    ) async throws {
        
        // Use base extractor with enhanced image
        baseExtractor.extractText(from: image) { result in
            switch result {
            case .success(let textElements):
                // Post-process text elements using table structure information
                let enhancedElements = self.postProcessTextElements(
                    textElements,
                    tableStructure: tableStructure
                )
                completion(.success(enhancedElements))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Extract text elements using LiteRT guidance
    private func extractTextElementsWithLiteRT(from image: UIImage, pageOffset: Int) async throws -> [TextElement] {
        
        // Detect table structure for this page
        let tableStructure = try await tableDetector.detectTableStructure(in: image)
        
        // Apply preprocessing
        let preprocessedImage = try await applyTableAwarePreprocessing(
            image: image,
            tableStructure: tableStructure
        )
        
        // Extract text elements
        return try await withCheckedThrowingContinuation { continuation in
            baseExtractor.extractText(from: preprocessedImage) { result in
                switch result {
                case .success(let elements):
                    // Adjust coordinates for page offset and post-process
                    let adjustedElements = elements.map { element in
                        var adjustedBounds = element.bounds
                        adjustedBounds.origin.y += CGFloat(pageOffset) * image.size.height
                        
                        return TextElement(
                            text: element.text,
                            bounds: adjustedBounds,
                            fontSize: element.fontSize,
                            confidence: element.confidence
                        )
                    }
                    
                    let enhancedElements = self.postProcessTextElements(
                        adjustedElements,
                        tableStructure: tableStructure
                    )
                    
                    continuation.resume(returning: enhancedElements)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Post-process text elements using table structure information
    private func postProcessTextElements(_ textElements: [TextElement], tableStructure: LiteRTTableStructure) -> [TextElement] {
        
        guard tableStructure.isPCDAFormat else {
            return textElements
        }
        
        print("[EnhancedVisionTextExtractor] Post-processing \(textElements.count) text elements for PCDA format")
        
        var enhancedElements: [TextElement] = []
        
        for element in textElements {
            // Find which column this element belongs to
            let columnIndex = findColumnIndex(for: element, in: tableStructure.columns)
            
            // Apply column-specific processing
            let processedElement = applyColumnSpecificProcessing(
                element: element,
                columnIndex: columnIndex,
                columnType: columnIndex < tableStructure.columns.count ? tableStructure.columns[columnIndex].columnType : .other
            )
            
            // Filter out elements outside table bounds
            if tableStructure.bounds.intersects(element.bounds) {
                enhancedElements.append(processedElement)
            }
        }
        
        print("[EnhancedVisionTextExtractor] Post-processing completed: \(enhancedElements.count) elements retained")
        return enhancedElements
    }
    
    /// Find which column a text element belongs to
    private func findColumnIndex(for element: TextElement, in columns: [LiteRTTableColumn]) -> Int {
        for (index, column) in columns.enumerated() {
            let elementCenter = CGPoint(x: element.bounds.midX, y: element.bounds.midY)
            if column.bounds.contains(elementCenter) ||
               abs(column.bounds.midX - element.bounds.midX) < 30 {
                return index
            }
        }
        return 0 // Default to first column
    }
    
    /// Apply column-specific text processing
    private func applyColumnSpecificProcessing(element: TextElement, columnIndex: Int, columnType: LiteRTColumnType) -> TextElement {
        var processedText = element.text
        var adjustedConfidence = element.confidence
        
        switch columnType {
        case .amount:
            // Apply amount-specific cleaning
            processedText = cleanAmountText(processedText)
            adjustedConfidence = enhanceAmountConfidence(element.confidence, text: processedText)
            
        case .description:
            // Apply description-specific cleaning
            processedText = cleanDescriptionText(processedText)
            
        case .code:
            // Apply code-specific cleaning
            processedText = cleanCodeText(processedText)
            
        case .other:
            // Generic cleaning
            processedText = element.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return TextElement(
            text: processedText,
            bounds: element.bounds,
            fontSize: element.fontSize,
            confidence: adjustedConfidence
        )
    }
    
    /// Clean amount text for better accuracy
    private func cleanAmountText(_ text: String) -> String {
        var cleaned = text
        
        // Common OCR corrections for amounts
        cleaned = cleaned.replacingOccurrences(of: "O", with: "0") // O -> 0
        cleaned = cleaned.replacingOccurrences(of: "l", with: "1") // l -> 1
        cleaned = cleaned.replacingOccurrences(of: "S", with: "5") // S -> 5
        
        // Remove non-numeric characters except decimal points and commas
        cleaned = cleaned.replacingOccurrences(of: "[^0-9.,₹]", with: "", options: .regularExpression)
        
        return cleaned
    }
    
    /// Clean description text
    private func cleanDescriptionText(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Clean code text
    private func cleanCodeText(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
    
    /// Enhance confidence for amount fields based on format validation
    private func enhanceAmountConfidence(_ originalConfidence: Float, text: String) -> Float {
        let amountPattern = try? NSRegularExpression(pattern: "^[₹]?[0-9,]+\\.?[0-9]*$", options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if amountPattern?.firstMatch(in: text, options: [], range: range) != nil {
            return min(originalConfidence + 0.1, 1.0) // Boost confidence for valid amounts
        }
        
        return originalConfidence
    }
    
    /// Render PDF page as image
    private func renderPageAsImage(page: PDFPage) async throws -> UIImage {
        // Render synchronously to avoid Sendable issues with PDFPage
        let pageRect = page.bounds(for: .mediaBox)
        let scaleFactor: CGFloat = 2.0 // High resolution for better OCR
        let scaledSize = CGSize(
            width: pageRect.width * scaleFactor,
            height: pageRect.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: scaledSize))
            cgContext.scaleBy(x: scaleFactor, y: scaleFactor)
            page.draw(with: .mediaBox, to: cgContext)
        }
        
        return image
    }
    
    /// Convert LiteRTTableStructure to the existing TableStructure format
    private func convertLiteRTToTableStructure(_ liteRTStructure: LiteRTTableStructure) -> TableStructure {
        let tableRows = liteRTStructure.rows.enumerated().map { index, row in
            TableStructure.TableRow(
                index: index,
                yPosition: row.bounds.origin.y,
                height: row.bounds.height,
                bounds: row.bounds
            )
        }
        
        let tableColumns = liteRTStructure.columns.enumerated().map { index, column in
            TableStructure.TableColumn(
                index: index,
                xPosition: column.bounds.origin.x,
                width: column.bounds.width,
                bounds: column.bounds
            )
        }
        
        return TableStructure(
            rows: tableRows,
            columns: tableColumns,
            bounds: liteRTStructure.bounds
        )
    }
}

// MARK: - Extensions

// CGRect center extension already exists in the project
