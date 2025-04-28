import Foundation
import PDFKit

/// Protocol for PayslipParserCoordinator
protocol PayslipParserCoordinatorProtocol {
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A Result containing either a PayslipItem or an error
    /// - Throws: Errors related to parser selection or underlying parsing failures.
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PCDAPayslipParserResult<PayslipItem>
    
    /// Gets available parser names
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String]
    
    /// Selects the best parser for a given document
    /// - Parameter pdfDocument: The PDF document
    /// - Returns: The best parser for the document
    /// - Throws: Potential errors during text extraction or analysis.
    func selectBestParser(for pdfDocument: PDFDocument) async throws -> PayslipParser?
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
    private let textExtractor: TextExtractor
    
    /// Abbreviation manager for handling abbreviations
    private let abbreviationManager: AbbreviationManager
    
    /// Pattern manager for extracting data from text
    private let patternManager: PayslipPatternManager
    
    /// Cache for previously parsed documents
    private var cache: [String: (result: PCDAPayslipParserResult<PayslipItem>, timestamp: Date)] = [:]
    
    /// Cache expiration time in seconds (default: 1 hour)
    private let cacheExpirationTime: TimeInterval = 3600
    
    /// Maximum cache size
    private let maxCacheSize = 50
    
    // MARK: - Initialization
    
    init(textExtractor: TextExtractor = DefaultTextExtractor(), 
         abbreviationManager: AbbreviationManager = AbbreviationManager(),
         patternManager: PayslipPatternManager = PayslipPatternManager()) {
        self.textExtractor = textExtractor
        self.abbreviationManager = abbreviationManager
        self.patternManager = patternManager
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
        // Register the PCDA parser with needed dependencies
        parsers.append(PCDAPayslipParser(abbreviationManager: abbreviationManager))
        
        // Register other parsers as needed
    }
    
    // MARK: - PayslipParserCoordinatorProtocol
    
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A Result containing either a PayslipItem or an error
    /// - Throws: Errors related to parser selection or underlying parsing failures.
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PCDAPayslipParserResult<PayslipItem> {
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
        
        // Extract text from the document
        let extractedText = await textExtractor.extractText(from: pdfDocument)
        
        // Try direct pattern-based parsing first using PayslipPatternManager
        if let payslipItem = patternManager.parsePayslipData(extractedText) {
            print("[PayslipParserCoordinator] Successfully parsed using pattern manager")
            let result: PCDAPayslipParserResult<PayslipItem> = .success(payslipItem)
            cacheResult(result, for: pdfDocument)
            return result
        }
        
        // If pattern-based parsing fails, fall back to specialized parsers
        guard let parser = try await selectBestParser(for: pdfDocument) else {
            print("[PayslipParserCoordinator] No suitable parser found")
            return .failure(.unknown(message: "No suitable parser found for this document"))
        }
        
        print("[PayslipParserCoordinator] Using parser: \(parser.name)")
        
        // If it's a PCDAPayslipParser, use its result-based parsing method (now async)
        if let pcdaParser = parser as? PCDAPayslipParser {
            let result = await pcdaParser.parsePayslipWithResult(pdfDocument: pdfDocument)
            
            // Cache the result if successful
            if case .success = result {
                cacheResult(result, for: pdfDocument)
            }
            
            return result
        } else {
            // For other parsers, adapt their output to our result type
            if let payslipItem = try await parser.parsePayslip(pdfDocument: pdfDocument) {
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
    /// - Throws: Potential errors during text extraction or analysis.
    func selectBestParser(for pdfDocument: PDFDocument) async throws -> PayslipParser? {
        // Extract text from the document to identify format
        let text = await textExtractor.extractText(from: pdfDocument)
        
        // Try to extract some data using the pattern manager to check compatibility
        let extractedData = patternManager.extractData(from: text)
        let (earnings, deductions) = patternManager.extractTabularData(from: text)
        
        // If we extracted significant data, give preference to pattern-based parsing
        let hasSignificantData = !extractedData.isEmpty && 
                                 (earnings.count > 2 || deductions.count > 2)
        
        if hasSignificantData {
            // Find the most compatible parser based on the extracted data
            return findMostCompatibleParser(for: extractedData, earnings: earnings, deductions: deductions)
        }
        
        // Find matches for all parsers using the traditional method
        let matches = findParserMatches(for: text)
        
        // Return the parser with the highest confidence score if any
        return matches.first?.parser
    }
    
    /// Finds the most compatible parser based on extracted data
    /// - Parameters:
    ///   - extractedData: The extracted data dictionary
    ///   - earnings: The extracted earnings
    ///   - deductions: The extracted deductions
    /// - Returns: The most compatible parser
    private func findMostCompatibleParser(
        for extractedData: [String: String],
        earnings: [String: Double],
        deductions: [String: Double]
    ) -> PayslipParser? {
        // If we have military-specific keys, prefer the PCDA parser
        let militaryKeys = ["DSOP", "CDA", "PCDA", "Service Number"]
        
        for key in militaryKeys {
            if extractedData.keys.contains(where: { $0.contains(key) }) {
                return parsers.first { $0 is PCDAPayslipParser }
            }
        }
        
        // Check for terms in earnings/deductions that might indicate format
        let militaryTerms = ["X Pay", "Grade Pay", "MSP", "NPA", "DA"]
        let hasMilitaryTerms = earnings.keys.contains { term in
            militaryTerms.contains { term.contains($0) }
        }
        
        if hasMilitaryTerms {
            return parsers.first { $0 is PCDAPayslipParser }
        }
        
        // Default to the first parser if no specific matches
        return parsers.first
    }
    
    /// Finds parser matches with confidence scores
    /// - Parameter text: The text to analyze
    /// - Returns: Array of parser matches sorted by confidence score (descending)
    private func findParserMatches(for text: String) -> [ParserMatch] {
        var matches: [ParserMatch] = []
        
        // Extract potential data points using the pattern manager
        let extractedData = patternManager.extractData(from: text)
        
        // Evaluate each parser
        for parser in parsers {
            let (score, matchedTags) = calculateConfidenceScore(
                parser: parser, 
                text: text,
                extractedData: extractedData
            )
            
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
    ///   - extractedData: Optional pre-extracted data to use in evaluation
    /// - Returns: A tuple containing the confidence score and matched tags
    private func calculateConfidenceScore(
        parser: PayslipParser, 
        text: String,
        extractedData: [String: String]? = nil
    ) -> (Double, [String]) {
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
        
        // If we have extracted data, use it to improve the confidence score
        var dataScore = 0.0
        if let data = extractedData {
            // Calculate how many expected fields were found
            let expectedFields: [String]
            
            if formatType == "military" {
                expectedFields = ["Name", "Service Number", "Rank", "Unit", "DSOP", "Tax"]
            } else {
                expectedFields = ["Name", "Employee ID", "Department", "Designation", "Bank Account"]
            }
            
            let foundFieldsCount = expectedFields.filter { field in
                data.keys.contains { $0.contains(field) }
            }.count
            
            dataScore = Double(foundFieldsCount) / Double(expectedFields.count)
        }
        
        // Calculate the final confidence score with equal weight to patterns and extracted data
        let confidenceScore = (patternScore + (dataScore * 1.5)) / 2.5
        
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
    ///   - result: The result to cache
    ///   - pdfDocument: The PDF document
    private func cacheResult(_ result: PCDAPayslipParserResult<PayslipItem>, for pdfDocument: PDFDocument) {
        let key = generateCacheKey(for: pdfDocument)
        
        // Add to cache with current timestamp
        cache[key] = (result: result, timestamp: Date())
        
        // Check if cache size exceeds maximum
        if cache.count > maxCacheSize {
            // Remove oldest entries
            let oldestEntries = cache.sorted { $0.value.timestamp < $1.value.timestamp }
                .prefix(cache.count - maxCacheSize)
            
            for (key, _) in oldestEntries {
                cache.removeValue(forKey: key)
            }
        }
    }
    
    /// Generates a cache key for a PDF document
    /// - Parameter pdfDocument: The PDF document
    /// - Returns: A string key for the cache
    private func generateCacheKey(for pdfDocument: PDFDocument) -> String {
        // Generate a key based on the first page text and page count
        let firstPageText = pdfDocument.page(at: 0)?.string ?? ""
        let pageCount = pdfDocument.pageCount
        
        // Use a hash of the content as the key
        let contentHash = "\(firstPageText)\(pageCount)".data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        
        return contentHash
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