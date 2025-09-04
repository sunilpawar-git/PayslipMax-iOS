import Foundation
import PDFKit

/// A registry for payslip parsers that allows registration, retrieval, and selection of appropriate parsers
class StandardPayslipParserRegistry: PayslipParserRegistry {
    // MARK: - Properties
    
    /// All registered parsers
    private(set) var parsers: [PayslipParser] = []
    
    /// Format detection patterns for different types of payslips
    private var formatPatterns: [String: [String]] = [:]
    
    // MARK: - Initialization
    
    /// Initializes a new StandardPayslipParserRegistry
    init() {
        setupFormatPatterns()
    }
    
    /// Sets up format detection patterns for different types of payslips
    private func setupFormatPatterns() {
        // Military format detection patterns
        formatPatterns["military"] = [
            "Ministry of Defence", "ARMY", "NAVY", "AIR FORCE", "PCDA", "CDA", 
            "Defence", "DSOP FUND", "Military", "ARMED FORCES"
        ]
        
        // Note: Only military format patterns needed since PayslipMax is exclusively for defense personnel
    }
    
    // MARK: - Registry Protocol Implementation
    
    /// Registers a parser with the registry
    /// - Parameter parser: The parser to register
    func register(parser: PayslipParser) {
        // Check if a parser with the same name already exists
        if let existingIndex = parsers.firstIndex(where: { $0.name == parser.name }) {
            // Replace the existing parser
            parsers[existingIndex] = parser
            print("[PayslipParserRegistry] Replaced existing parser: \(parser.name)")
        } else {
            // Add the new parser
            parsers.append(parser)
            print("[PayslipParserRegistry] Registered new parser: \(parser.name)")
        }
    }
    
    /// Registers multiple parsers with the registry
    /// - Parameter parsers: The parsers to register
    func register(parsers: [PayslipParser]) {
        for parser in parsers {
            register(parser: parser)
        }
    }
    
    /// Removes a parser from the registry
    /// - Parameter name: The name of the parser to remove
    func removeParser(withName name: String) {
        if let index = parsers.firstIndex(where: { $0.name == name }) {
            parsers.remove(at: index)
            print("[PayslipParserRegistry] Removed parser: \(name)")
        } else {
            print("[PayslipParserRegistry] Parser not found for removal: \(name)")
        }
    }
    
    /// Gets a parser by name
    /// - Parameter name: The name of the parser to retrieve
    /// - Returns: The parser with the specified name, or nil if not found
    func getParser(withName name: String) -> PayslipParser? {
        return parsers.first { $0.name == name }
    }
    
    /// Selects the best parser for a given PDF text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: The most suitable parser for the text, or nil if no suitable parser is found
    func selectBestParser(for text: String) -> PayslipParser? {
        // Short circuit if we have no parsers
        if parsers.isEmpty {
            print("[PayslipParserRegistry] No parsers registered")
            return nil
        }
        
        // Get format matches with scores
        let formatMatches = detectFormat(in: text)
        
        // If we have a clear military format, try to find a military parser
        if formatMatches["military"] ?? 0 > 0.5 {
            print("[PayslipParserRegistry] Detected military format, searching for military parser")
            if let militaryParser = parsers.first(where: { $0 is MilitaryPayslipParser }) {
                return militaryParser
            }
        }
        
        // Corporate parsing removed - PayslipMax is exclusively for defense personnel
        
        // If we have a clear bank format, try to find a bank parser
        if formatMatches["bank"] ?? 0 > 0.5 {
            print("[PayslipParserRegistry] Detected bank format, searching for bank parser")
            // Note: Bank parser protocol not yet defined, use generic parser
        }
        
        // If no specific format detected or no matching parser found, try each parser for confidence
        print("[PayslipParserRegistry] No clear format match or specific parser found, evaluating all parsers")
        var bestParser: PayslipParser? = nil
        var bestScore = 0
        
        for parser in parsers {
            let score = evaluateParserConfidence(parser, for: text)
            if score > bestScore {
                bestScore = score
                bestParser = parser
            }
        }
        
        if let parser = bestParser {
            print("[PayslipParserRegistry] Selected parser \(parser.name) with confidence score \(bestScore)")
            return parser
        }
        
        // If all else fails, return the first parser as a fallback
        print("[PayslipParserRegistry] No suitable parser found, using first parser as fallback")
        return parsers.first
    }
    
    // MARK: - Helper Methods
    
    /// Detects the format of a payslip based on text content
    /// - Parameter text: The text to analyze
    /// - Returns: A dictionary mapping format names to confidence scores (0-1)
    private func detectFormat(in text: String) -> [String: Double] {
        var scores: [String: Double] = [:]
        
        // Check each format's patterns
        for (format, patterns) in formatPatterns {
            let matchCount = patterns.filter { text.contains($0) }.count
            let score = Double(matchCount) / Double(patterns.count)
            scores[format] = score
        }
        
        return scores
    }
    
    /// Evaluates a parser's confidence for handling a specific text
    /// - Parameters:
    ///   - parser: The parser to evaluate
    ///   - text: The text to analyze
    /// - Returns: A confidence score (higher is better)
    private func evaluateParserConfidence(_ parser: PayslipParser, for text: String) -> Int {
        // Military parser confidence
        if let militaryParser = parser as? MilitaryPayslipParser {
            if militaryParser.canHandleMilitaryFormat(text: text) {
                return 100
            }
        }
        
        // Default confidence based on parser type (defense personnel only)
        if parser is MilitaryPayslipParser {
            return 50
        } else {
            return 30
        }
    }
} 