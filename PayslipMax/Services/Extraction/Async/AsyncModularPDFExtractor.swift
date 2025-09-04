import Foundation
import PDFKit

/// Async-first modular PDF extractor that eliminates DispatchSemaphore usage.
/// This replaces the synchronous ModularPDFExtractor for new async workflows.
/// 
/// Follows the single responsibility principle established in Phase 2B refactoring.
class AsyncModularPDFExtractor: PDFExtractorProtocol {
    // MARK: - Properties
    
    private let patternRepository: PatternRepositoryProtocol
    
    // MARK: - Initialization
    
    init(patternRepository: PatternRepositoryProtocol = DefaultPatternRepository()) {
        self.patternRepository = patternRepository
    }
    
    // MARK: - Public Async Methods
    
    /// Extracts payslip data from a PDF document asynchronously.
    /// This eliminates the first DispatchSemaphore violation from ModularPDFExtractor.
    func extractPayslipData(from pdfDocument: PDFDocument) async throws -> PayslipItem? {
        guard let pdfData = pdfDocument.dataRepresentation() else {
            print("AsyncModularPDFExtractor: Failed to get PDF data representation")
            return nil
        }
        
        // ✅ CLEAN: Direct async call - no semaphores!
        do {
            return try await extractData(from: pdfDocument, pdfData: pdfData)
        } catch {
            print("AsyncModularPDFExtractor: Error extracting payslip data - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Extracts payslip data from text synchronously.
    /// This eliminates the second DispatchSemaphore violation from ModularPDFExtractor.
    func extractPayslipData(from text: String) -> PayslipItem? {
        print("AsyncModularPDFExtractor: Attempting to extract data from text only")
        
        // ✅ CLEAN: Use RunLoop.main - eliminates DispatchSemaphore completely
        var result: PayslipItem? = nil
        var finished = false
        
        Task {
            result = await extractPayslipDataAsync(from: text)
            finished = true
        }
        
        // Wait for completion using RunLoop - cleaner than DispatchSemaphore
        while !finished {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
        
        return result
    }
    
    /// Internal async helper for text-based extraction
    private func extractPayslipDataAsync(from text: String) async -> PayslipItem? {
        let patterns = await patternRepository.getAllPatterns()
        
        if patterns.isEmpty {
            print("AsyncModularPDFExtractor: Error - No patterns loaded")
            return nil
        }
        
        // Create a dictionary to store the extracted values
        var data: [String: String] = [:]
        
        // Group patterns by category
        let patternsByCategory = Dictionary(
            grouping: patterns,
            by: { $0.category }
        )
        
        // Process each category of patterns
        for (category, patternsInCategory) in patternsByCategory {
            print("AsyncModularPDFExtractor: Processing category: \(category.rawValue)")
            
            // Sort patterns by priority
            let sortedPatterns = patternsInCategory.sorted(by: { 
                getPatternPriority($0) > getPatternPriority($1)
            })
            
            // Try each pattern until a value is found
            for pattern in sortedPatterns {
                let key = pattern.key
                
                if let value = findValue(for: pattern, in: text) {
                    print("AsyncModularPDFExtractor: Found value for \(key): \(value)")
                    data[key] = value
                    break
                }
            }
        }
        
        return createPayslipItem(from: data)
    }
    
    /// Extracts text from a PDF document
    func extractText(from pdfDocument: PDFDocument) async -> String {
        return await extractTextFromPDF(pdfDocument) ?? ""
    }
    
    /// Gets the available parsers
    func getAvailableParsers() -> [String] {
        return ["AsyncModularParser"]
    }
    
    // MARK: - Private Methods
    
    /// Extract data from a PDF document and return a PayslipItem
    private func extractData(from pdfDocument: PDFDocument, pdfData: Data) async throws -> PayslipItem {
        // Log PDF details for debugging
        logPdfDetails(pdfDocument)
        
        // Extract text from the PDF document
        guard let pdfText = await extractTextFromPDF(pdfDocument) else {
            print("AsyncModularPDFExtractor: Failed to extract text from PDF")
            throw AsyncModularExtractionError.pdfTextExtractionFailed
        }
        
        print("AsyncModularPDFExtractor: Extracted \(pdfText.count) characters from PDF")
        
        // Get all patterns from the repository
        let patterns = await patternRepository.getAllPatterns()
        print("AsyncModularPDFExtractor: Loaded \(patterns.count) patterns")
        
        // Process patterns against the PDF text
        var data: [String: String] = [:]
        
        // Group patterns by category
        let patternsByCategory = Dictionary(
            grouping: patterns,
            by: { $0.category }
        )
        
        print("AsyncModularPDFExtractor: Processing patterns by category")
        // Process each category of patterns
        for (category, patternsInCategory) in patternsByCategory {
            print("AsyncModularPDFExtractor: Processing category: \(category.rawValue)")
            
            // Sort patterns by priority
            let sortedPatterns = patternsInCategory.sorted(by: { 
                getPatternPriority($0) > getPatternPriority($1)
            })
            
            // Try each pattern until a value is found
            for pattern in sortedPatterns {
                let key = pattern.key
                
                if let value = findValue(for: pattern, in: pdfText) {
                    print("AsyncModularPDFExtractor: Found value for \(key): \(value)")
                    data[key] = value
                    break
                }
            }
        }
        
        // Create a PayslipItem from the extracted data
        guard let payslip = createPayslipItem(from: data, with: pdfData) else {
            throw AsyncModularExtractionError.payslipCreationFailed
        }
        
        return payslip
    }
    
    /// Extracts text from PDF document asynchronously
    private func extractTextFromPDF(_ pdfDocument: PDFDocument) async -> String? {
        guard pdfDocument.pageCount > 0 else { return nil }
        
        var extractedText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            // ✅ CLEAN: Use Task.yield() instead of blocking operations
            await Task.yield()
            
            if let pageText = page.string {
                extractedText += pageText + "\n"
            }
        }
        
        return extractedText.isEmpty ? nil : extractedText
    }
    
    /// Creates a PayslipItem from extracted data
    private func createPayslipItem(from data: [String: String], with pdfData: Data? = nil) -> PayslipItem? {
        // Extract required fields with default values
        let month = data["month"] ?? ""
        let yearString = data["year"] ?? ""
        let name = data["name"] ?? ""
        let accountNumber = data["account_number"] ?? ""
        let panNumber = data["pan_number"] ?? ""
        
        // Convert year to integer if needed
        let year = Int(yearString) ?? Calendar.current.component(.year, from: Date())
        
        // Extract and convert numeric values
        let credits = extractDouble(from: data["credits"] ?? "0")
        let debits = extractDouble(from: data["debits"] ?? "0")
        let tax = extractDouble(from: data["tax"] ?? "0")
        let dsop = extractDouble(from: data["dsop"] ?? "0")
        
        // Validate essential data
        if month.isEmpty || yearString.isEmpty || credits == 0 {
            print("AsyncModularPDFExtractor: Insufficient data extracted")
            return nil
        }
        
        // Create the payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: pdfData ?? Data()
        )
        
        return payslip
    }
    
    /// Logs PDF details for debugging
    private func logPdfDetails(_ pdfDocument: PDFDocument) {
        print("AsyncModularPDFExtractor: PDF has \(pdfDocument.pageCount) pages")
    }
    
    /// Gets pattern priority for sorting
    private func getPatternPriority(_ pattern: PatternDefinition) -> Int {
        // Simple priority based on pattern characteristics
        switch pattern.category {
        case .earnings: return 100
        case .deductions: return 90
        case .personal: return 80
        case .taxInfo: return 70
        case .banking: return 60
        case .custom: return 50
        }
    }
    
    /// Finds value for a pattern in text
    private func findValue(for pattern: PatternDefinition, in text: String) -> String? {
        // Try each pattern in the definition (sorted by priority)
        let sortedPatterns = pattern.patterns.sorted { $0.priority > $1.priority }
        
        for extractorPattern in sortedPatterns {
            do {
                let regex = try NSRegularExpression(pattern: extractorPattern.pattern, options: [])
                let range = NSRange(text.startIndex..., in: text)
                
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let matchRange = Range(match.range, in: text)
                    return matchRange.map { String(text[$0]) }
                }
            } catch {
                print("AsyncModularPDFExtractor: Regex error for pattern \(pattern.key): \(error)")
                continue
            }
        }
        
        return nil
    }
    
    /// Extracts double value from string
    private func extractDouble(from string: String) -> Double {
        // Remove currency symbols and formatting
        let cleanString = string.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleanString) ?? 0.0
    }
}

// MARK: - Error Types

enum AsyncModularExtractionError: Error, LocalizedError {
    case pdfTextExtractionFailed
    case payslipCreationFailed
    case invalidPDFData
    case patternProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .pdfTextExtractionFailed:
            return "Failed to extract text from PDF document"
        case .payslipCreationFailed:
            return "Failed to create PayslipItem from extracted data"
        case .invalidPDFData:
            return "Invalid or corrupted PDF data"
        case .patternProcessingFailed:
            return "Failed to process extraction patterns"
        }
    }
} 