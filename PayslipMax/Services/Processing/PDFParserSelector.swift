import Foundation
import PDFKit

/// Handles parser selection and registration logic
final class PDFParserSelector {
    
    // MARK: - Properties
    
    private let parserRegistry: PayslipParserRegistry
    private let abbreviationManager: AbbreviationManager
    
    // MARK: - Initialization
    
    init(parserRegistry: PayslipParserRegistry, abbreviationManager: AbbreviationManager) {
        self.parserRegistry = parserRegistry
        self.abbreviationManager = abbreviationManager
        registerParsers()
    }
    
    // MARK: - Parser Registration
    
    private func registerParsers() {
        // Register the new Vision-based parser
        parserRegistry.register(parser: VisionPayslipParser())
        
        // Add the PCDA parser
        parserRegistry.register(parser: PCDAPayslipParser(abbreviationManager: abbreviationManager))
        
        // Note: PageAwarePayslipParser is not a PayslipParser protocol conformant, so not registered here
        
        // Add more parsers as needed
    }
    
    // MARK: - Parser Selection
    
    /// Selects the best parser for a given text
    /// - Parameter text: The text to analyze
    /// - Returns: The best parser for the text, or nil if no suitable parser is found
    func selectBestParser(for text: String) -> PayslipParser? {
        return parserRegistry.selectBestParser(for: text)
    }
    
    /// Gets all available parsers
    /// - Returns: Array of all registered parsers
    func getAllParsers() -> [PayslipParser] {
        return parserRegistry.parsers
    }
    
    /// Gets the names of all available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String] {
        return parserRegistry.parsers.map { $0.name }
    }
    
    /// Gets a specific parser by name
    /// - Parameter name: The name of the parser to retrieve
    /// - Returns: The parser if found, nil otherwise
    func getParser(named name: String) -> PayslipParser? {
        return parserRegistry.parsers.first { $0.name == name }
    }
    
    /// Determines if a document appears to be military format
    /// - Parameter text: The document text to analyze
    /// - Returns: True if military format is detected
    func isMilitaryFormat(_ text: String) -> Bool {
        let militaryTerms = [
            "Ministry of Defence", "ARMY", "NAVY", "AIR FORCE", 
            "PCDA", "CDA", "Defence", "DSOP FUND", "Military"
        ]
        
        return militaryTerms.contains { text.contains($0) }
    }
    
    /// Gets parsers suitable for military format documents
    /// - Returns: Array of parsers that handle military formats well
    func getMilitaryParsers() -> [PayslipParser] {
        return parserRegistry.parsers.filter { parser in
            parser.name.contains("PCDA") || 
            parser.name.contains("Military") || 
            parser.name.contains("PageAware")
        }
    }
} 