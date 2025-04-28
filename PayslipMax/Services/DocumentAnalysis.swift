import Foundation
import PDFKit
import Vision

/// Model representing the analysis results of a PDF document
struct DocumentAnalysis {
    /// The total number of pages in the document
    let pageCount: Int
    
    /// Whether the document contains scanned content or images
    let containsScannedContent: Bool
    
    /// Whether the document has complex layout (multiple columns, tables, etc.)
    let hasComplexLayout: Bool
    
    /// Text density value (0.0-1.0) - higher means more text content
    let textDensity: Double
    
    /// Estimated memory requirement to process the document
    let estimatedMemoryRequirement: Int64
    
    /// Whether the document contains tables
    let containsTables: Bool
    
    /// Whether the document contains text
    var hasText: Bool = true
    
    /// Number of images in the document
    var imageCount: Int = 0
    
    /// Whether the document is considered large based on page count or file size
    var isLargeDocument: Bool {
        return pageCount >= DocumentAnalysisService.Thresholds.largeDocumentPageCount || 
               estimatedMemoryRequirement >= DocumentAnalysisService.Thresholds.largeDocumentFileSize
    }
    
    /// Whether the document is considered text-heavy based on text density
    var isTextHeavy: Bool {
        return textDensity >= DocumentAnalysisService.Thresholds.textHeavyDensity
    }
    
    /// Alternative property name for consistency with some code paths
    var hasScannedContent: Bool {
        return containsScannedContent
    }
    
    /// Whether the document contains form elements
    var containsFormElements: Bool = false
    
    /// Whether the document contains graphics (non-text elements)
    var containsGraphics: Bool {
        return containsScannedContent // As a simplified approximation, assume graphics if scanned content
    }
    
    /// Alternative property name for consistency
    var hasTables: Bool {
        return containsTables
    }
    
    /// Recommended extraction strategies based on document characteristics
    var recommendedExtractionStrategies: [ExtractionStrategy] {
        var strategies: [ExtractionStrategy] = []
        
        if containsScannedContent {
            strategies.append(.ocrExtraction)
        }
        
        if textDensity > 0.3 {
            strategies.append(.nativeTextExtraction)
        }
        
        if containsTables {
            strategies.append(.tableExtraction)
        }
        
        if containsScannedContent && isTextHeavy {
            strategies.append(.hybridExtraction)
        }
        
        if isLargeDocument {
            strategies.append(.streamingExtraction)
        }
        
        // If no specific strategies were determined, default to native extraction
        if strategies.isEmpty {
            strategies.append(.nativeTextExtraction)
        }
        
        return strategies
    }
}

/// Protocol for document analysis service
protocol DocumentAnalysisServiceProtocol {
    /// Analyze a PDF document to determine its characteristics
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Analysis results
    func analyzeDocument(_ document: PDFDocument) throws -> DocumentAnalysis
    
    /// Analyze a PDF document at the given URL
    /// - Parameter url: URL to the PDF document
    /// - Returns: Analysis results
    func analyzeDocument(at url: URL) throws -> DocumentAnalysis
}

/// Service for analyzing PDF documents to determine their characteristics and optimal processing strategies.
///
/// This service analyzes documents to identify features such as text density, layout complexity,
/// image content, and other characteristics that influence parsing strategies. It also provides
/// recommendations for extraction parameters based on document analysis.
///
/// - Note: This service is thread-safe and can be used concurrently.
class DocumentAnalysisService: DocumentAnalysisServiceProtocol {
    // MARK: - Thresholds
    
    /// Thresholds for document classification
    struct Thresholds {
        /// Minimum percentage of images to consider a document as containing scanned content
        static let scannedContentThreshold: Double = 0.3
        
        /// Minimum number of columns to consider a layout complex
        static let complexLayoutColumnCount: Int = 2
        
        /// Minimum text density to consider a document text-heavy
        static let textHeavyDensity: Double = 0.6
        
        /// Minimum page count to consider as a large document
        static let largeDocumentPageCount: Int = 50
        
        /// Minimum file size in bytes to consider as a large document
        static let largeDocumentFileSize: Int64 = 10 * 1024 * 1024 // 10 MB
    }
    
    // MARK: - Public Methods
    
    /// Analyzes a PDF document to determine its characteristics.
    ///
    /// This method examines various aspects of the document including text density,
    /// layout complexity, presence of images, and table structures to create a
    /// comprehensive analysis result.
    ///
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Analysis results containing document characteristics
    /// - Throws: `DocumentAnalysisError` if analysis fails
    func analyzeDocument(_ document: PDFDocument) throws -> DocumentAnalysis {
        let pageCount = document.pageCount
        
        // For large documents, only sample a subset of pages to improve performance
        let pagesToAnalyze = min(pageCount, 10)
        let pageIndices = selectRepresentativePages(total: pageCount, sample: pagesToAnalyze)
        
        // Analyze document characteristics
        let hasScanned = detectScannedContent(in: document, pageIndices: pageIndices)
        let layoutResult = analyzeLayoutComplexity(of: document, pageIndices: pageIndices)
        let textDensity = analyzeTextDensity(in: document, pageIndices: pageIndices)
        let sizeResult = analyzeSizeCharacteristics(of: document)
        let hasTables = detectTables(in: document, pageIndices: pageIndices)
        let hasForms = detectFormElements(in: document, pageIndices: pageIndices)
        
        // Check if document has any text
        let hasText = detectText(in: document, pageIndices: pageIndices)
        
        // Count images in the document
        let imageCount = countImages(in: document, pageIndices: pageIndices)
        
        var analysis = DocumentAnalysis(
            pageCount: pageCount,
            containsScannedContent: hasScanned,
            hasComplexLayout: layoutResult.isComplex,
            textDensity: textDensity,
            estimatedMemoryRequirement: sizeResult.estimatedMemory,
            containsTables: hasTables
        )
        
        // Set additional properties
        analysis.containsFormElements = hasForms
        analysis.hasText = hasText
        analysis.imageCount = imageCount
        
        return analysis
    }
    
    /// Analyze a PDF document at the given URL
    /// - Parameter url: URL to the PDF document
    /// - Returns: Analysis results
    func analyzeDocument(at url: URL) throws -> DocumentAnalysis {
        guard let document = PDFDocument(url: url) else {
            throw NSError(domain: "DocumentAnalysis", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PDF document from URL"])
        }
        
        return try analyzeDocument(document)
    }
    
    /// Gets recommended extraction parameters based on document analysis.
    ///
    /// This method determines the optimal extraction strategy and parameters
    /// based on the document's characteristics such as text density, layout complexity,
    /// and content types.
    ///
    /// - Parameter analysisResult: The document analysis result
    /// - Returns: Recommended extraction parameters
    /// - Throws: `DocumentAnalysisError` if parameter generation fails
    func getRecommendedParameters(for analysisResult: DocumentAnalysis) throws -> ExtractionParameters {
        var parameters = ExtractionParameters()
        
        // Basic configuration based on document characteristics
        parameters.extractText = analysisResult.hasText
        parameters.extractImages = analysisResult.imageCount > 0
        parameters.extractTables = analysisResult.hasTables
        
        // OCR requirements
        parameters.useOCR = analysisResult.hasScannedContent
        
        // Streaming for large documents
        parameters.useStreaming = analysisResult.isLargeDocument
        
        // Quality settings based on content complexity
        if analysisResult.hasComplexLayout {
            parameters.quality = .high
            parameters.useGridDetection = true
            parameters.preserveFormatting = true
        } else if analysisResult.isTextHeavy {
            parameters.quality = .standard
            parameters.preferNativeTextWhenAvailable = true
        } else {
            parameters.quality = .standard
        }
        
        // Performance optimizations
        if analysisResult.imageCount > 10 {
            parameters.downscaleFactor = 0.8 // Reduce image resolution for better performance
        }
        
        return parameters
    }
    
    /// Calculates the complexity score for a document.
    ///
    /// The complexity score is a numerical representation of how difficult a document
    /// is to process, based on factors like layout complexity, content types, and size.
    ///
    /// - Parameter analysisResult: The document analysis result
    /// - Returns: Complexity score between 0.0 (simple) and 1.0 (very complex)
    /// - Throws: `DocumentAnalysisError` if complexity calculation fails
    func calculateComplexityScore(for analysisResult: DocumentAnalysis) throws -> Double {
        var score = 0.0
        
        // Add complexity for layout
        if analysisResult.hasComplexLayout {
            score += 0.3
        }
        
        // Add complexity for mixed content
        if analysisResult.hasText && analysisResult.imageCount > 0 {
            score += 0.15
        }
        
        // Add complexity for tables
        if analysisResult.hasTables {
            score += 0.2
        }
        
        // Add complexity for scanned content
        if analysisResult.hasScannedContent {
            score += 0.25
        }
        
        // Add complexity for size
        if analysisResult.isLargeDocument {
            score += 0.1
        }
        
        // Ensure the score is between 0 and 1
        return min(max(score, 0.0), 1.0)
    }
    
    // MARK: - Private Methods
    
    /// Select a representative sample of pages to analyze
    /// - Parameters:
    ///   - total: Total number of pages
    ///   - sample: Number of pages to sample
    /// - Returns: Array of page indices to analyze
    private func selectRepresentativePages(total: Int, sample: Int) -> [Int] {
        guard total > 0 else { return [] }
        
        if total <= sample {
            return Array(0..<total)
        }
        
        var indices = [0] // Always include first page
        
        // Always include last page if there's more than one page
        if total > 1 {
            indices.append(total - 1)
        }
        
        // Add evenly distributed pages in between
        if sample > 2 && total > 2 {
            let step = Double(total - 2) / Double(sample - 2)
            for i in 1..<(sample - 1) {
                let pageIndex = 1 + Int(Double(i) * step)
                if pageIndex < total - 1 && !indices.contains(pageIndex) {
                    indices.append(pageIndex)
                }
            }
        }
        
        return indices.sorted()
    }
    
    /// Detect if a document contains scanned content or images
    /// - Parameters:
    ///   - document: The PDF document
    ///   - pageIndices: Indices of pages to analyze
    /// - Returns: True if document contains significant scanned content
    private func detectScannedContent(in document: PDFDocument, pageIndices: [Int]) -> Bool {
        var imageCount = 0
        var totalElements = 0
        
        for pageIndex in pageIndices {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Check for images in page annotations
            for annotation in page.annotations {
                // Check annotation type using string comparison 
                if let typeString = annotation.type {
                    // Compare with known annotation types for images/stamps
                    if typeString == "Stamp" || typeString == "Widget" {
                        imageCount += 1
                    }
                }
                totalElements += 1
            }
            
            // Simple heuristic - low text to document size ratio may indicate scanned content
            if let text = page.string, let data = document.dataRepresentation() {
                let textSize = text.count
                let dataSize = data.count
                
                if textSize > 0 && dataSize > 0 {
                    let ratio = Double(textSize) / Double(dataSize)
                    if ratio < 0.01 { // Very low text ratio suggests scanned content
                        return true
                    }
                }
            }
        }
        
        // If a significant percentage of elements are images, consider it scanned content
        return totalElements > 0 && Double(imageCount) / Double(totalElements) >= Thresholds.scannedContentThreshold
    }
    
    /// Analyze layout complexity of document
    /// - Parameters:
    ///   - document: The PDF document
    ///   - pageIndices: Indices of pages to analyze
    /// - Returns: Layout complexity analysis result
    private func analyzeLayoutComplexity(of document: PDFDocument, pageIndices: [Int]) -> (isComplex: Bool, columnCount: Int) {
        var maxColumnCount = 1
        
        for pageIndex in pageIndices {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Detect columns using text layout analysis
            if let text = page.string {
                let columnCount = estimateColumnCount(from: text, pageWidth: page.bounds(for: .mediaBox).width)
                maxColumnCount = max(maxColumnCount, columnCount)
            }
        }
        
        return (maxColumnCount >= Thresholds.complexLayoutColumnCount, maxColumnCount)
    }
    
    /// Analyze text density in document
    /// - Parameters:
    ///   - document: The PDF document
    ///   - pageIndices: Indices of pages to analyze
    /// - Returns: Text density (0.0-1.0)
    private func analyzeTextDensity(in document: PDFDocument, pageIndices: [Int]) -> Double {
        var totalTextLength = 0
        var totalPageArea: CGFloat = 0
        
        for pageIndex in pageIndices {
            guard let page = document.page(at: pageIndex) else { continue }
            
            if let text = page.string {
                totalTextLength += text.count
            }
            
            let pageSize = page.bounds(for: .mediaBox).size
            totalPageArea += pageSize.width * pageSize.height
        }
        
        // Calculate text density (characters per unit area)
        let density = totalPageArea > 0 ? Double(totalTextLength) / Double(totalPageArea) : 0
        let normalizedDensity = min(1.0, density / 0.1) // Normalize with a reasonable max density
        
        return normalizedDensity
    }
    
    /// Analyze size characteristics of the document
    /// - Parameter document: The PDF document
    /// - Returns: Size analysis result
    private func analyzeSizeCharacteristics(of document: PDFDocument) -> (isLarge: Bool, estimatedMemory: Int64) {
        let pageCount = document.pageCount
        var estimatedMemory: Int64 = 0
        
        // Get data representation for file size estimation
        if let data = document.dataRepresentation() {
            let fileSize = Int64(data.count)
            
            // Estimate memory requirements (typically 3-5x file size for processing)
            estimatedMemory = fileSize * 4
            
            // Check if large by file size
            if fileSize > Thresholds.largeDocumentFileSize {
                return (true, estimatedMemory)
            }
        }
        
        // Check if large by page count
        return (pageCount >= Thresholds.largeDocumentPageCount, estimatedMemory)
    }
    
    /// Detect tables in the document
    /// - Parameters:
    ///   - document: The PDF document
    ///   - pageIndices: Indices of pages to analyze
    /// - Returns: True if tables are detected
    private func detectTables(in document: PDFDocument, pageIndices: [Int]) -> Bool {
        for pageIndex in pageIndices {
            guard let page = document.page(at: pageIndex), let text = page.string else { continue }
            
            // Simple heuristic: Look for consistent spacing or tabular structures
            if hasTabularStructure(text) {
                return true
            }
        }
        
        return false
    }
    
    /// Check if text has tabular structure
    /// - Parameter text: The text to analyze
    /// - Returns: True if tabular structure is detected
    private func hasTabularStructure(_ text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        var consecutiveTabLines = 0
        
        for line in lines {
            if line.contains("\t") || hasConsistentSpacing(line) {
                consecutiveTabLines += 1
                if consecutiveTabLines >= 3 {
                    return true
                }
            } else {
                consecutiveTabLines = 0
            }
        }
        
        return false
    }
    
    /// Check if a line has consistent spacing (indicative of tables)
    /// - Parameter line: The line to analyze
    /// - Returns: True if consistent spacing is detected
    private func hasConsistentSpacing(_ line: String) -> Bool {
        // Count spaces between non-space characters
        var spaceGroups: [Int] = []
        var currentSpaceCount = 0
        var inSpace = false
        
        for char in line {
            if char == " " {
                if !inSpace {
                    inSpace = true
                    currentSpaceCount = 1
                } else {
                    currentSpaceCount += 1
                }
            } else {
                if inSpace {
                    inSpace = false
                    spaceGroups.append(currentSpaceCount)
                    currentSpaceCount = 0
                }
            }
        }
        
        // Check if space groups are consistent in size (indicative of table columns)
        if spaceGroups.count >= 2 {
            let uniqueGroups = Set(spaceGroups)
            // If most space groups are similar in size, likely a table
            return Double(uniqueGroups.count) / Double(spaceGroups.count) <= 0.5
        }
        
        return false
    }
    
    /// Estimate the number of columns in a page
    /// - Parameters:
    ///   - text: The page text
    ///   - pageWidth: Width of the page
    /// - Returns: Estimated number of columns
    private func estimateColumnCount(from text: String, pageWidth: CGFloat) -> Int {
        // Simple heuristic: estimate based on line lengths
        let lines = text.components(separatedBy: .newlines)
        var lineLengths: [Int] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                lineLengths.append(trimmed.count)
            }
        }
        
        guard !lineLengths.isEmpty else { return 1 }
        
        // Sort line lengths
        lineLengths.sort()
        
        // If there's a bimodal or multimodal distribution, it might indicate multiple columns
        let median = lineLengths[lineLengths.count / 2]
        let thresholdValue = Double(median) * 0.6
        let shortLines = lineLengths.filter { Double($0) < thresholdValue }.count
        let longLines = lineLengths.filter { Double($0) > thresholdValue }.count
        
        if shortLines > lineLengths.count / 3 && longLines > lineLengths.count / 3 {
            return 2
        }
        
        // For very wide pages, assume multi-column layout
        if pageWidth > 800 {
            return 2
        }
        
        return 1
    }
    
    /// Detect form elements in the document
    /// - Parameters:
    ///   - document: The PDF document
    ///   - pageIndices: Indices of pages to analyze
    /// - Returns: True if form elements are detected
    private func detectFormElements(in document: PDFDocument, pageIndices: [Int]) -> Bool {
        for pageIndex in pageIndices {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Check if page has annotations that might be form elements
            for annotation in page.annotations {
                // Check for Widget annotations (commonly used for form elements)
                if let typeString = annotation.type, typeString == "Widget" {
                    return true
                }
            }
            
            // Check if text content has patterns that indicate form fields
            if let text = page.string {
                // Look for common form field patterns like underscores, checkboxes, or text field labels
                if containsFormFieldPatterns(text) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Check if text contains patterns commonly found in forms
    /// - Parameter text: The text to analyze
    /// - Returns: True if form field patterns are detected
    private func containsFormFieldPatterns(_ text: String) -> Bool {
        // Common form field patterns:
        // 1. Lines of underscores (blank fields)
        if text.contains("_________") || text.contains("__________") {
            return true
        }
        
        // 2. Checkbox symbols
        if text.contains("□") || text.contains("☐") || text.contains("[ ]") || text.contains("[  ]") {
            return true
        }
        
        // 3. Common form field labels followed by blank space
        let formLabels = ["Name:", "Address:", "Phone:", "Email:", "Date:", "Signature:"]
        for label in formLabels {
            if text.contains(label) {
                return true
            }
        }
        
        // 4. Date field patterns (MM/DD/YYYY or similar)
        if text.contains("__/__/____") || text.contains("MM/DD/YYYY") ||
           text.contains("DD/MM/YYYY") || text.contains("YYYY/MM/DD") {
            return true
        }
        
        return false
    }
    
    /// Detect if a document contains any extractable text
    /// - Parameters:
    ///   - document: The PDF document
    ///   - pageIndices: Indices of pages to analyze
    /// - Returns: True if the document contains extractable text
    private func detectText(in document: PDFDocument, pageIndices: [Int]) -> Bool {
        for pageIndex in pageIndices {
            guard let page = document.page(at: pageIndex) else { continue }
            
            if let text = page.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
        }
        
        return false
    }
    
    /// Count the number of images in the document
    /// - Parameters:
    ///   - document: The PDF document
    ///   - pageIndices: Indices of pages to analyze
    /// - Returns: Estimated number of images in the document
    private func countImages(in document: PDFDocument, pageIndices: [Int]) -> Int {
        var imageCount = 0
        
        for pageIndex in pageIndices {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Count image annotations
            for annotation in page.annotations {
                if let typeString = annotation.type {
                    if typeString == "Stamp" || typeString == "Widget" {
                        imageCount += 1
                    }
                }
            }
            
            // If page has little text but significant data, it likely contains images
            if let text = page.string, let data = document.dataRepresentation() {
                let textSize = text.count
                let dataSize = data.count / document.pageCount // Approximate per-page data size
                
                if textSize < 100 && dataSize > 5000 {
                    // Page has little text but significant data - likely contains images
                    imageCount += 1
                }
            }
        }
        
        // Scale up the count for sampled pages
        if document.pageCount > pageIndices.count {
            let scaleFactor = Double(document.pageCount) / Double(pageIndices.count)
            imageCount = Int(Double(imageCount) * scaleFactor)
        }
        
        return imageCount
    }
} 