import Foundation
import PDFKit

/// Protocol for PayslipParserCoordinator
protocol PayslipParserCoordinatorProtocol {
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A Result containing either a PayslipItem or an error
    func parsePayslip(pdfDocument: PDFDocument) -> PCDAPayslipParserResult<PayslipItem>
    
    /// Gets available parser names
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String]
    
    /// Selects the best parser for a given document
    /// - Parameter pdfDocument: The PDF document
    /// - Returns: The best parser for the document
    func selectBestParser(for pdfDocument: PDFDocument) -> PayslipParser?
}

/// Struct representing a parser match with confidence score
struct ParserMatch {
    /// The parser instance
    let parser: PayslipParser
    
    /// Confidence score for this parser (0.0 to 1.0)
    let confidenceScore: Double
    
    /// Format detection tags that matched
    let matchedTags: [String]
}

/// Coordinator for payslip parsing operations
class PayslipParserCoordinator: PayslipParserCoordinatorProtocol {
    // MARK: - Properties
    
    /// Available parsers
    private var parsers: [PayslipParser] = []
    
    /// Format detection patterns
    private var formatPatterns: [String: [String]] = [:]
    
    /// Text extractor for handling PDF text extraction
    private let textExtractor: PDFTextExtractor
    
    /// Abbreviation manager for handling abbreviations
    private let abbreviationManager: AbbreviationManager
    
    /// Cache for previously parsed documents
    private var cache: [String: (result: PCDAPayslipParserResult<PayslipItem>, timestamp: Date)] = [:]
    
    /// Cache expiration time in seconds (default: 1 hour)
    private let cacheExpirationTime: TimeInterval = 3600
    
    /// Maximum cache size
    private let maxCacheSize = 50
    
    // MARK: - Initialization
    
    init(textExtractor: PDFTextExtractor = PDFTextExtractor(), 
         abbreviationManager: AbbreviationManager = AbbreviationManager()) {
        self.textExtractor = textExtractor
        self.abbreviationManager = abbreviationManager
        setupFormatPatterns()
        registerParsers()
    }
    
    // MARK: - Setup
    
    /// Sets up format detection patterns
    private func setupFormatPatterns() {
        // Military format detection patterns
        formatPatterns["military"] = [
            "Ministry of Defence", "ARMY", "NAVY", "AIR FORCE", "PCDA", "CDA", 
            "Defence", "DSOP FUND", "Military", "ARMED FORCES"
        ]
        
        // Corporate format detection patterns
        formatPatterns["corporate"] = [
            "Salary Slip", "Pay Slip", "Earnings", "Deductions", "Net Pay",
            "Gross Salary", "Employee Code", "Employee ID", "PF Number"
        ]
        
        // Bank format detection patterns
        formatPatterns["bank"] = [
            "Bank Statement", "Account Number", "Statement Period",
            "Opening Balance", "Closing Balance", "Transaction Date"
        ]
        
        // Add more format patterns as needed
    }
    
    // MARK: - Parser Registration
    
    /// Registers available parsers
    private func registerParsers() {
        // Register the PCDA parser
        parsers.append(PCDAPayslipParser(abbreviationManager: abbreviationManager))
        
        // Register other parsers as needed
    }
    
    // MARK: - PayslipParserCoordinatorProtocol
    
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A Result containing either a PayslipItem or an error
    func parsePayslip(pdfDocument: PDFDocument) -> PCDAPayslipParserResult<PayslipItem> {
        // Check if the PDF is empty
        if pdfDocument.pageCount == 0 {
            print("[PayslipParserCoordinator] PDF document is empty")
            return .failure(.emptyPDF)
        }
        
        // Check if we have a cached result
        if let cachedResult = getCachedResult(for: pdfDocument) {
            print("[PayslipParserCoordinator] Using cached result")
            return cachedResult
        }
        
        // Select the best parser for this document
        guard let parser = selectBestParser(for: pdfDocument) else {
            print("[PayslipParserCoordinator] No suitable parser found")
            return .failure(.unknown(message: "No suitable parser found for this document"))
        }
        
        print("[PayslipParserCoordinator] Using parser: \(parser.name)")
        
        // If it's a PCDAPayslipParser, use its result-based parsing method
        if let pcdaParser = parser as? PCDAPayslipParser {
            let result = pcdaParser.parsePayslipWithResult(pdfDocument: pdfDocument)
            
            // Cache the result if successful
            if case .success = result {
                cacheResult(result, for: pdfDocument)
            }
            
            return result
        } else {
            // For other parsers, adapt their output to our result type
            if let payslipItem = parser.parsePayslip(pdfDocument: pdfDocument) {
                let confidence = parser.evaluateConfidence(for: payslipItem)
                
                // Only cache if confidence is medium or high
                if confidence != .low {
                    let result: PCDAPayslipParserResult<PayslipItem> = .success(payslipItem)
                    cacheResult(result, for: pdfDocument)
                }
                
                return .success(payslipItem)
            } else {
                return .failure(.extractionFailed)
            }
        }
    }
    
    /// Gets available parser names
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String] {
        return parsers.map { $0.name }
    }
    
    /// Selects the best parser for a given document
    /// - Parameter pdfDocument: The PDF document
    /// - Returns: The best parser for the document
    func selectBestParser(for pdfDocument: PDFDocument) -> PayslipParser? {
        // Extract text from the document to identify format
        let text = textExtractor.extractText(from: pdfDocument)
        
        // Find matches for all parsers
        let matches = findParserMatches(for: text)
        
        // Return the parser with the highest confidence score if any
        return matches.first?.parser
    }
    
    /// Finds parser matches with confidence scores
    /// - Parameter text: The text to analyze
    /// - Returns: Array of parser matches sorted by confidence score (descending)
    private func findParserMatches(for text: String) -> [ParserMatch] {
        var matches: [ParserMatch] = []
        
        // Evaluate each parser
        for parser in parsers {
            let (score, matchedTags) = calculateConfidenceScore(parser: parser, text: text)
            
            // Only consider parsers with a minimum confidence score
            if score > 0.2 {
                matches.append(ParserMatch(parser: parser, confidenceScore: score, matchedTags: matchedTags))
            }
        }
        
        // Sort matches by confidence score (descending)
        return matches.sorted { $0.confidenceScore > $1.confidenceScore }
    }
    
    /// Calculates a confidence score for a parser based on the text
    /// - Parameters:
    ///   - parser: The parser to evaluate
    ///   - text: The text to analyze
    /// - Returns: A tuple containing the confidence score and matched tags
    private func calculateConfidenceScore(parser: PayslipParser, text: String) -> (Double, [String]) {
        // Determine the format patterns to check based on the parser type
        var formatType = "corporate" // Default format
        var matchedTags: [String] = []
        
        if parser is PCDAPayslipParser {
            formatType = "military"
        }
        
        // Check for format-specific patterns
        if let patterns = formatPatterns[formatType] {
            for pattern in patterns {
                if text.contains(pattern) {
                    matchedTags.append(pattern)
                }
            }
        }
        
        // Calculate a basic confidence score based on matched patterns
        let patternMatches = Double(matchedTags.count)
        let totalPatterns = Double(formatPatterns[formatType]?.count ?? 1)
        let patternScore = patternMatches / totalPatterns
        
        // Add more confidence calculation factors here if needed
        
        // Calculate the final confidence score
        let confidenceScore = patternScore
        
        return (confidenceScore, matchedTags)
    }
    
    // MARK: - Caching Methods
    
    /// Gets a cached result for a PDF document
    /// - Parameter pdfDocument: The PDF document
    /// - Returns: The cached result, if available and not expired
    private func getCachedResult(for pdfDocument: PDFDocument) -> PCDAPayslipParserResult<PayslipItem>? {
        let key = generateCacheKey(for: pdfDocument)
        
        guard let cachedEntry = cache[key] else { return nil }
        
        // Check if the cache entry has expired
        let now = Date()
        if now.timeIntervalSince(cachedEntry.timestamp) > cacheExpirationTime {
            // Remove expired entry
            cache.removeValue(forKey: key)
            return nil
        }
        
        return cachedEntry.result
    }
    
    /// Caches a parsing result for a PDF document
    /// - Parameters:
    ///   - result: The parsing result to cache
    ///   - pdfDocument: The PDF document
    private func cacheResult(_ result: PCDAPayslipParserResult<PayslipItem>, for pdfDocument: PDFDocument) {
        let key = generateCacheKey(for: pdfDocument)
        
        // Add the new entry with current timestamp
        cache[key] = (result: result, timestamp: Date())
        
        // Clean up the cache if it exceeds maximum size
        if cache.count > maxCacheSize {
            // Remove the oldest entries
            let sortedKeys = cache.sorted { $0.value.timestamp < $1.value.timestamp }.map { $0.key }
            let keysToRemove = sortedKeys.prefix(cache.count - maxCacheSize)
            
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
    }
    
    /// Generates a cache key for a PDF document
    /// - Parameter pdfDocument: The PDF document
    /// - Returns: A unique cache key
    private func generateCacheKey(for pdfDocument: PDFDocument) -> String {
        // Extract text samples from multiple pages for a more robust key
        var samples: [String] = []
        
        // Get text from first, middle, and last page
        let pageCount = pdfDocument.pageCount
        let pagesToSample = [
            0,
            pageCount > 2 ? pageCount / 2 : min(1, pageCount - 1),
            pageCount > 1 ? pageCount - 1 : 0
        ]
        
        for pageIndex in pagesToSample {
            if let page = pdfDocument.page(at: pageIndex), let text = page.string {
                // Take a sample of text from each page
                let sample = text.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines)
                samples.append(sample)
            }
        }
        
        // Combine samples and hash the result for a stable key
        let combinedSample = samples.joined(separator: "-")
        return combinedSample.isEmpty ? UUID().uuidString : combinedSample
    }
    
    // MARK: - Utility Methods
    
    /// Clears the parsing cache
    func clearCache() {
        cache.removeAll()
    }
    
    /// Removes expired cache entries
    func cleanCache() {
        let now = Date()
        let expiredKeys = cache.filter { now.timeIntervalSince($0.value.timestamp) > cacheExpirationTime }.map { $0.key }
        
        for key in expiredKeys {
            cache.removeValue(forKey: key)
        }
    }
} 