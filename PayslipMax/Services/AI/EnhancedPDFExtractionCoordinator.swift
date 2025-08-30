import Foundation
@preconcurrency import PDFKit

/// Enhanced PDF extraction coordinator with LiteRT AI integration
class EnhancedPDFExtractionCoordinator: PDFExtractionCoordinatorProtocol {
    
    // MARK: - Properties
    
    private let basePDFCoordinator: PDFExtractionCoordinator
    private let liteRTService: LiteRTServiceProtocol?
    private let enhancedVisionExtractor: EnhancedVisionTextExtractor
    private let tableDetector: TableStructureDetectorProtocol
    private let useLiteRTProcessing: Bool

    
    // MARK: - Feature Flags
    
    private struct FeatureFlags {
        static let enableLiteRTTableDetection = true
        static let enableHybridProcessing = true
        static let enablePCDAOptimization = true
        static let enablePerformanceMonitoring = true
    }
    
    // MARK: - Initialization
    
    /// Initialize with LiteRT integration
    /// - Parameters:
    ///   - basePDFCoordinator: The base PDF extraction coordinator
    ///   - liteRTService: LiteRT service for AI processing
    ///   - useLiteRTProcessing: Whether to use LiteRT processing
    init(
        basePDFCoordinator: PDFExtractionCoordinator? = nil,
        liteRTService: LiteRTServiceProtocol? = nil,
        useLiteRTProcessing: Bool = true
    ) {
        self.basePDFCoordinator = basePDFCoordinator ?? PDFExtractionCoordinator()
        // Handle main actor isolation by keeping service optional
        self.liteRTService = liteRTService
        self.useLiteRTProcessing = useLiteRTProcessing
        self.tableDetector = TableStructureDetector()
        self.enhancedVisionExtractor = EnhancedVisionTextExtractor(
            liteRTService: self.liteRTService,
            useLiteRTPreprocessing: useLiteRTProcessing
        )
        
        print("[EnhancedPDFExtractionCoordinator] Initialized with LiteRT processing: \(useLiteRTProcessing)")
        
        // Initialize LiteRT service asynchronously
        if useLiteRTProcessing {
            Task {
                await initializeLiteRTService()
            }
        }
    }
    
    // MARK: - PDFExtractionCoordinatorProtocol Implementation
    
    /// Extract payslip data from PDF document with AI enhancement
    func extractPayslipData(from document: PDFDocument) -> PayslipItem? {
        guard useLiteRTProcessing, liteRTService != nil else {
            print("[EnhancedPDFExtractionCoordinator] Using base coordinator (LiteRT disabled or unavailable)")
            return basePDFCoordinator.extractPayslipData(from: document)
        }
        
        print("[EnhancedPDFExtractionCoordinator] Processing document with AI enhancement")
        
        // Use async processing but return synchronously for compatibility
        return processDocumentSynchronously(document)
    }
    
    /// Extract payslip data from text with AI analysis
    func extractPayslipData(from text: String) -> PayslipItem? {
        guard useLiteRTProcessing, liteRTService != nil else {
            return basePDFCoordinator.extractPayslipData(from: text)
        }
        
        print("[EnhancedPDFExtractionCoordinator] Analyzing text with AI enhancement")
        
        // Perform AI-enhanced text analysis
        return processTextWithAI(text)
    }
    
    /// Extract text from PDF document with AI enhancement
    public func extractText(from document: PDFDocument) async -> String {
        guard useLiteRTProcessing, liteRTService != nil else {
            return await basePDFCoordinator.extractText(from: document)
        }
        
        print("[EnhancedPDFExtractionCoordinator] Extracting text with AI enhancement")
        
        do {
            return try await extractTextWithAIEnhancement(from: document)
        } catch {
            print("[EnhancedPDFExtractionCoordinator] AI extraction failed, falling back: \(error)")
            return await basePDFCoordinator.extractText(from: document)
        }
    }
    
    /// Get available parsers including AI-enhanced options
    public func getAvailableParsers() -> [String] {
        var parsers = basePDFCoordinator.getAvailableParsers()
        
        if useLiteRTProcessing && liteRTService != nil {
            parsers.append("AI-Enhanced Parser")
            parsers.append("PCDA-Optimized Parser")
        }
        
        return parsers
    }
    
    // MARK: - AI-Enhanced Processing Methods
    
    /// Extract text with AI enhancement and table structure analysis
    private func extractTextWithAIEnhancement(from document: PDFDocument) async throws -> String {
        var extractedText = ""
        let totalPages = document.pageCount
        
        print("[EnhancedPDFExtractionCoordinator] Processing \(totalPages) pages with AI enhancement")
        
        for pageIndex in 0..<totalPages {
            guard let page = document.page(at: pageIndex) else { continue }
            
            // Convert page to image for AI analysis
            let pageImage = try await renderPageAsImage(page: page)
            
            // Analyze document structure with LiteRT
            guard let service = liteRTService else {
                throw LiteRTError.serviceNotInitialized
            }
            let documentAnalysis = try await service.processDocument(data: pageImage.pngData() ?? Data())
            
            // Extract text with structure-aware processing
            let pageText = try await extractPageTextWithStructureAwareness(
                page: page,
                image: pageImage,
                analysis: documentAnalysis
            )
            
            extractedText += pageText + "\n"
            
            print("[EnhancedPDFExtractionCoordinator] Processed page \(pageIndex + 1)/\(totalPages)")
        }
        
        return extractedText
    }
    
    /// Extract text from a page with structure awareness
    private func extractPageTextWithStructureAwareness(
        page: PDFPage,
        image: UIImage,
        analysis: LiteRTDocumentAnalysisResult
    ) async throws -> String {
        
        if FeatureFlags.enablePCDAOptimization && analysis.tableStructure.isPCDAFormat {
            return try await extractPCDAFormattedText(image: image, analysis: analysis)
        } else {
            return try await extractStandardText(image: image, analysis: analysis)
        }
    }
    
    /// Extract text optimized for PCDA format
    private func extractPCDAFormattedText(image: UIImage, analysis: LiteRTDocumentAnalysisResult) async throws -> String {
        print("[EnhancedPDFExtractionCoordinator] Using PCDA-optimized extraction")
        
        // Use enhanced Vision extractor with PCDA preprocessing
        return try await withCheckedThrowingContinuation { continuation in
            enhancedVisionExtractor.extractText(from: image) { result in
                switch result {
                case .success(let textElements):
                    // Convert LiteRT table structure to legacy format for formatting
                    let convertedStructure = self.convertLiteRTToTableStructure(analysis.tableStructure)
                    let formattedText = self.formatPCDAText(
                        textElements: textElements,
                        tableStructure: convertedStructure
                    )
                    continuation.resume(returning: formattedText)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Extract text using standard AI enhancement
    private func extractStandardText(image: UIImage, analysis: LiteRTDocumentAnalysisResult) async throws -> String {
        print("[EnhancedPDFExtractionCoordinator] Using standard AI-enhanced extraction")
        
        return try await withCheckedThrowingContinuation { continuation in
            enhancedVisionExtractor.extractText(from: image) { result in
                switch result {
                case .success(let textElements):
                    let text = textElements.map { $0.text }.joined(separator: " ")
                    continuation.resume(returning: text)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Format PCDA text elements into structured text
    private func formatPCDAText(textElements: [TextElement], tableStructure: TableStructure) -> String {
        // Group elements by rows
        let rowGroups = Dictionary(grouping: textElements) { element in
            Int(element.bounds.midY / 20) * 20
        }
        
        let sortedRows = rowGroups.keys.sorted()
        var formattedText = ""
        
        for rowY in sortedRows {
            guard let elements = rowGroups[rowY] else { continue }
            
            // Sort elements in row by X position
            let sortedElements = elements.sorted { $0.bounds.minX < $1.bounds.minX }
            
            // Create row text with proper spacing
            let rowText = sortedElements.map { $0.text }.joined(separator: "\t")
            formattedText += rowText + "\n"
        }
        
        return formattedText
    }
    
    /// Process text with AI analysis
    private func processTextWithAI(_ text: String) -> PayslipItem? {
        // Use a semaphore to convert async to sync for API compatibility
        let semaphore = DispatchSemaphore(value: 0)
        var result: PayslipItem?
        
        Task {
            do {
                guard let service = liteRTService else {
                    throw LiteRTError.serviceNotInitialized
                }
                let formatAnalysis = try await service.analyzeDocumentFormat(text: text)
                result = await processTextWithFormatAnalysis(text: text, formatAnalysis: formatAnalysis)
            } catch {
                print("[EnhancedPDFExtractionCoordinator] AI text analysis failed: \(error)")
                result = basePDFCoordinator.extractPayslipData(from: text)
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    /// Process text with format analysis results
    private func processTextWithFormatAnalysis(text: String, formatAnalysis: LiteRTDocumentFormatAnalysis) async -> PayslipItem? {
        
        print("[EnhancedPDFExtractionCoordinator] Processing text with format: \(formatAnalysis.formatType)")
        
        // Use format-specific processing
        switch formatAnalysis.formatType {
        case .pcda, .military:
            return await processMilitaryFormatText(text: text, analysis: formatAnalysis)
        case .corporate:
            return await processCorporateFormatText(text: text, analysis: formatAnalysis)
        default:
            return basePDFCoordinator.extractPayslipData(from: text)
        }
    }
    
    /// Process military/PCDA format text
    private func processMilitaryFormatText(text: String, analysis: LiteRTDocumentFormatAnalysis) async -> PayslipItem? {
        // Apply PCDA-specific processing rules
        let cleanedText = cleanPCDAText(text)
        return basePDFCoordinator.extractPayslipData(from: cleanedText)
    }
    
    /// Process corporate format text
    private func processCorporateFormatText(text: String, analysis: LiteRTDocumentFormatAnalysis) async -> PayslipItem? {
        // Apply corporate-specific processing rules
        let cleanedText = cleanCorporateText(text)
        return basePDFCoordinator.extractPayslipData(from: cleanedText)
    }
    
    /// Clean PCDA text using AI insights
    private func cleanPCDAText(_ text: String) -> String {
        var cleaned = text
        
        // Remove common PCDA formatting artifacts
        cleaned = cleaned.replacingOccurrences(of: "विवरण.*?DESCRIPTION", with: "DESCRIPTION", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "राशि.*?AMOUNT", with: "AMOUNT", options: .regularExpression)
        
        // Clean up spacing and line breaks
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\n\\s*\\n", with: "\n", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Clean corporate text using AI insights
    private func cleanCorporateText(_ text: String) -> String {
        var cleaned = text
        
        // Remove common corporate formatting artifacts
        cleaned = cleaned.replacingOccurrences(of: "\\bPvt\\.?\\s*Ltd\\.?", with: "Pvt Ltd", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Process document synchronously (for API compatibility)
    private func processDocumentSynchronously(_ document: PDFDocument) -> PayslipItem? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: PayslipItem?
        
        Task {
            do {
                result = try await processDocumentWithAI(document)
            } catch {
                print("[EnhancedPDFExtractionCoordinator] AI processing failed: \(error)")
                result = basePDFCoordinator.extractPayslipData(from: document)
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    /// Process document with full AI analysis
    private func processDocumentWithAI(_ document: PDFDocument) async throws -> PayslipItem? {
        
        guard let firstPage = document.page(at: 0) else {
            throw NSError(domain: "EnhancedPDFExtractionCoordinator", code: 1, userInfo: [NSLocalizedDescriptionKey: "No pages found in document"])
        }
        
        // Convert first page to image for analysis
        let pageImage = try await renderPageAsImage(page: firstPage)
        
        // Perform comprehensive AI analysis
        guard let service = liteRTService else {
            throw LiteRTError.serviceNotInitialized
        }
        let documentAnalysis = try await service.processDocument(data: pageImage.pngData() ?? Data())
        
        // Extract text with AI enhancement
        let extractedText = try await extractTextWithAIEnhancement(from: document)
        
        // Process with format-specific logic
        return await processTextWithFormatAnalysis(text: extractedText, formatAnalysis: documentAnalysis.formatAnalysis)
    }
    
    /// Initialize LiteRT service
    private func initializeLiteRTService() async {
        guard let service = liteRTService else {
            print("[EnhancedPDFExtractionCoordinator] No LiteRT service provided")
            return
        }
        
        do {
            try await service.initializeService()
            print("[EnhancedPDFExtractionCoordinator] LiteRT service initialized successfully")
        } catch {
            print("[EnhancedPDFExtractionCoordinator] LiteRT initialization failed: \(error)")
        }
    }
    
    /// Render PDF page as high-resolution image
    private func renderPageAsImage(page: PDFPage) async throws -> UIImage {
        // Render synchronously to avoid Sendable issues with PDFPage
        let pageRect = page.bounds(for: .mediaBox)
        let scaleFactor: CGFloat = 3.0 // High resolution for AI processing
        let scaledSize = CGSize(
            width: pageRect.width * scaleFactor,
            height: pageRect.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // White background for better contrast
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: scaledSize))
            
            // Scale and render page
            cgContext.scaleBy(x: scaleFactor, y: scaleFactor)
            page.draw(with: .mediaBox, to: cgContext)
        }
        
        return image
    }
    
    // MARK: - Performance Monitoring
    
    /// Log performance metrics for AI processing
    private func logPerformanceMetrics(operation: String, duration: TimeInterval, success: Bool) {
        guard FeatureFlags.enablePerformanceMonitoring else { return }
        
        print("[EnhancedPDFExtractionCoordinator] Performance: \(operation) - \(duration)s - Success: \(success)")
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
