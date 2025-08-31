import Foundation
import PDFKit
import CoreGraphics

/// A standard implementation of text extraction from PDF documents
class StandardTextExtractionService {
    
    // MARK: - Properties
    
    private let visionExtractor: VisionTextExtractorProtocol?
    private let useVisionFramework: Bool
    
    // MARK: - Initialization
    
    /// Initialize with optional Vision framework support
    /// - Parameters:
    ///   - useVisionFramework: Whether to use Vision framework for enhanced OCR
    ///   - visionExtractor: Optional Vision text extractor (will create default if nil and Vision is enabled)
    init(useVisionFramework: Bool = false, visionExtractor: VisionTextExtractorProtocol? = nil) {
        self.useVisionFramework = useVisionFramework
        self.visionExtractor = useVisionFramework ? (visionExtractor ?? VisionTextExtractor()) : nil
    }
    
    /// Extract text from the entire PDF document
    /// - Parameter document: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from document: PDFDocument) -> String {
        var extractedText = ""
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                if let pageText = page.string {
                    extractedText += pageText + "\n"
                }
            }
        }
        
        return extractedText
    }
    
    /// Extract text from a specific page of the PDF document
    /// - Parameters:
    ///   - pageIndex: The index of the page to extract text from
    ///   - document: The PDF document
    /// - Returns: The extracted text from the specified page
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        guard pageIndex >= 0, pageIndex < document.pageCount, let page = document.page(at: pageIndex) else {
            return nil
        }
        
        return page.string
    }
    
    /// Extract text from a range of pages in the PDF document
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - range: The range of pages to extract text from
    /// - Returns: The extracted text from the specified range
    func extractText(from document: PDFDocument, in range: Range<Int>) -> String {
        var extractedText = ""
        
        let startPage = max(0, range.lowerBound)
        let endPage = min(document.pageCount, range.upperBound)
        
        for i in startPage..<endPage {
            if let page = document.page(at: i), let pageText = page.string {
                extractedText += pageText + "\n"
            }
        }
        
        return extractedText
    }
    
    // MARK: - Enhanced Vision-based Extraction
    
    /// Extract text elements with spatial information using Vision framework
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - completion: Completion handler with text elements or error
    func extractTextElements(from document: PDFDocument, completion: @escaping (Result<[TextElement], Error>) -> Void) {
        extractTextElements(from: document, progressHandler: nil, completion: completion)
    }
    
    /// Extract text elements with progress tracking
    /// - Parameters:
    ///   - document: The PDF document to extract text from
    ///   - progressHandler: Optional progress handler (0.0 to 1.0)
    ///   - completion: Completion handler with text elements or error
    func extractTextElements(from document: PDFDocument, 
                           progressHandler: ((Double) -> Void)?,
                           completion: @escaping (Result<[TextElement], Error>) -> Void) {
        _ = PerformanceTimer(operation: "Standard text extraction")
        
        guard useVisionFramework, let visionExtractor = visionExtractor else {
            OCRLogger.shared.logFallback("Vision framework disabled", 
                                       reason: "useVisionFramework=false or extractor=nil",
                                       details: ["pageCount": document.pageCount])
            
            // Fallback to basic extraction - convert to TextElements
            let basicText = extractText(from: document)
            let fallbackElements = convertBasicTextToElements(basicText)
            completion(.success(fallbackElements))
            return
        }
        
        OCRLogger.shared.logOperation("Starting Vision-based text extraction", 
                                    details: ["pageCount": document.pageCount])
        
        visionExtractor.extractText(from: document, progressHandler: progressHandler) { result in
            switch result {
            case .success(let textElements):
                OCRLogger.shared.logOperation("Vision extraction successful", 
                                            details: ["elementsExtracted": textElements.count])

                // Phase 15: OCR tuning for legacy PCDA grid (languages + custom words)
                if let flags = ServiceRegistry.shared.resolve(FeatureFlagProtocol.self),
                   flags.isEnabled(.pcdaLegacyHardening) {
                    // Phase 15 refinement: per-page ROI crop using detected PCDA grid on each page
                    let vocab = [
                        "BPAY", "BASIC PAY", "DSOPF", "DSOP", "AGIF", "MSP", "TPT",
                        "INCM TAX", "EDUC CESS", "BARRACK", "LICENSE FEE", "DESCRIPTION", "AMOUNT"
                    ]
                    let baseTuned = VisionTextExtractor(
                        recognitionLevel: .accurate,
                        recognitionLanguages: ["en-IN", "hi-IN"],
                        minimumTextHeight: 0.01,
                        preprocessor: ImagePreprocessingService(),
                        customWords: vocab,
                        regionOfInterest: nil
                    )

                    var aggregated: [TextElement] = []

                    func processPage(index: Int) {
                        if index >= document.pageCount {
                            // All pages processed
                            let final = aggregated.isEmpty ? textElements : aggregated
                            completion(.success(final))
                            return
                        }

                        guard let page = document.page(at: index) else {
                            processPage(index: index + 1)
                            return
                        }

                        // Create single-page temp document
                        let temp = PDFDocument()
                        temp.insert(page, at: 0)

                        // First tuned pass on the page (full page, bilingual+vocab)
                        baseTuned.extractText(from: temp) { firstPass in
                            switch firstPass {
                            case .failure:
                                processPage(index: index + 1)
                            case .success(let pageElements):
                                // Detect PCDA grid on this page only
                                let detector = PCDATableDetector()
                                if let pcda = detector.detectPCDATableStructure(from: pageElements) {
                                    // Re-run with ROI equal to grid bounds for stricter crop
                                    let roiExtractor = VisionTextExtractor(
                                        recognitionLevel: .accurate,
                                        recognitionLanguages: ["en-IN", "hi-IN"],
                                        minimumTextHeight: 0.01,
                                        preprocessor: ImagePreprocessingService(),
                                        customWords: vocab,
                                        regionOfInterest: pcda.pcdaTableBounds
                                    )
                                    roiExtractor.extractText(from: temp) { roiResult in
                                        switch roiResult {
                                        case .success(let roiElements):
                                            aggregated.append(contentsOf: roiElements)
                                            processPage(index: index + 1)
                                        case .failure:
                                            aggregated.append(contentsOf: pageElements)
                                            processPage(index: index + 1)
                                        }
                                    }
                                } else {
                                    aggregated.append(contentsOf: pageElements)
                                    processPage(index: index + 1)
                                }
                            }
                        }
                    }

                    processPage(index: 0)
                    return
                }

                completion(.success(textElements))
                
            case .failure(let visionError):
                OCRLogger.shared.logFallback("Vision extraction failed", 
                                           reason: visionError.localizedDescription,
                                           details: ["pageCount": document.pageCount])
                
                // Graceful fallback to basic extraction
                let basicText = self.extractText(from: document)
                let fallbackElements = self.convertBasicTextToElements(basicText)
                
                OCRLogger.shared.logOperation("Fallback extraction completed", 
                                            details: ["elementsExtracted": fallbackElements.count])
                completion(.success(fallbackElements))
            }
        }
    }
    
    /// Extract text elements from a specific page with spatial information
    /// - Parameters:
    ///   - pageIndex: The index of the page to extract text from
    ///   - document: The PDF document
    ///   - completion: Completion handler with text elements or error
    func extractTextElementsFromPage(at pageIndex: Int, in document: PDFDocument, completion: @escaping (Result<[TextElement], Error>) -> Void) {
        guard pageIndex >= 0, pageIndex < document.pageCount, let page = document.page(at: pageIndex) else {
            completion(.success([]))
            return
        }
        
        guard useVisionFramework, let visionExtractor = visionExtractor else {
            // Fallback to basic extraction
            if let basicText = extractTextFromPage(at: pageIndex, in: document) {
                let fallbackElements = convertBasicTextToElements(basicText)
                completion(.success(fallbackElements))
            } else {
                completion(.success([]))
            }
            return
        }
        
        // Convert single page to a temporary document for Vision processing
        let tempDocument = PDFDocument()
        tempDocument.insert(page, at: 0)
        
        visionExtractor.extractText(from: tempDocument) { result in
            switch result {
            case .success(let textElements):
                completion(.success(textElements))
            case .failure(_):
                // Fallback to basic extraction
                if let basicText = self.extractTextFromPage(at: pageIndex, in: document) {
                    let fallbackElements = self.convertBasicTextToElements(basicText)
                    completion(.success(fallbackElements))
                } else {
                    completion(.success([]))
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Convert basic text string to TextElement array for fallback scenarios
    private func convertBasicTextToElements(_ text: String) -> [TextElement] {
        // Create simple TextElements from basic text extraction
        // This is a fallback when spatial information isn't available
        let lines = text.components(separatedBy: .newlines)
        var elements: [TextElement] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            // Create estimated bounds (fallback positioning)
            let bounds = CGRect(
                x: 0,
                y: CGFloat(index) * 20, // Estimated line height
                width: CGFloat(trimmedLine.count) * 8, // Estimated character width
                height: 16 // Estimated line height
            )
            
            let element = TextElement(
                text: trimmedLine,
                bounds: bounds,
                fontSize: 12.0, // Default font size
                confidence: 1.0 // Full confidence for PDF text
            )
            
            elements.append(element)
        }
        
        return elements
    }
} 