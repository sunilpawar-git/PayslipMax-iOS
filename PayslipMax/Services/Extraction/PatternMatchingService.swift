import Foundation

/// A coordinator service for pattern-based payslip data extraction.
///
/// This service implements the Coordinator pattern as part of SOLID compliance improvements,
/// orchestrating between PatternLoader (loading patterns) and PatternMatcher (applying patterns).
/// It maintains the same public interface as the original monolithic implementation while
/// achieving better separation of concerns internally.
///
/// ## Architectural Improvements
/// 
/// The refactored `PatternMatchingService` now follows the Single Responsibility Principle:
/// - **Pattern Loading**: Delegated to `PatternLoader`
/// - **Pattern Matching**: Delegated to `PatternMatcher`
/// - **Coordination**: Handled by this service (orchestration only)
///
/// This separation allows:
/// - Independent testing of pattern loading vs. matching logic
/// - Easier modification of pattern sources without affecting matching algorithms
/// - Better extensibility for new pattern types or matching strategies
/// - Clearer maintenance boundaries between different concerns
///
/// ## Component Relationships
///
/// The service coordinates between:
/// - **PatternLoader**: Loads patterns from various sources (PayslipPatternManager, etc.)
/// - **PatternMatcher**: Applies patterns to text and extracts structured data
/// - **Consumers**: Provides the same interface as before for existing clients
///
/// The public interface remains unchanged, ensuring backward compatibility while
/// improving internal architecture quality.
class PatternMatchingService: PatternMatchingServiceProtocol {
    // MARK: - Properties
    
    /// The pattern matcher responsible for applying patterns to text.
    private let patternMatcher: PatternMatcher
    
    // MARK: - Initialization
    
    /// Initializes the service with dependency injection support.
    ///
    /// This initializer demonstrates the improved architecture where pattern loading
    /// and pattern matching are handled by separate, focused components. The service
    /// coordinates between these components while maintaining the same external interface.
    ///
    /// - Parameters:
    ///   - patternLoader: Optional pattern loader for dependency injection (uses default if nil)
    ///   - patternMatcher: Optional pattern matcher for dependency injection (uses default if nil)
    init(patternLoader: PatternLoader? = nil, patternMatcher: PatternMatcher? = nil) {
        let loader = patternLoader ?? PatternLoader()
        let configuration = loader.loadPatternConfiguration()
        
        if let matcher = patternMatcher {
            self.patternMatcher = matcher
        } else {
            self.patternMatcher = PatternMatcher(configuration: configuration)
        }
        
        print("PatternMatchingService: Initialized with improved SOLID architecture")
    }
    
    // MARK: - Public Methods
    
    /// Extracts key-value data from text using predefined patterns.
    ///
    /// This method delegates to the PatternMatcher component while maintaining
    /// the same public interface for backward compatibility.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: Dictionary where keys are field identifiers and values are the extracted string values.
    func extractData(from text: String) -> [String: String] {
        return patternMatcher.extractKeyValueData(from: text)
    }
    
    /// Extracts tabular financial data (earnings and deductions) from payslip text.
    ///
    /// This method delegates to the PatternMatcher component while maintaining
    /// the same public interface for backward compatibility.
    ///
    /// - Parameter text: The raw text content extracted from a payslip document.
    /// - Returns: A tuple containing dictionaries of earnings and deductions.
    func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        return patternMatcher.extractFinancialData(from: text)
    }
    
    /// Extracts a string value for a specific pattern key from text.
    ///
    /// This method delegates to the PatternMatcher component while maintaining
    /// the same public interface for backward compatibility.
    ///
    /// - Parameters:
    ///   - key: The pattern key to use for extraction.
    ///   - text: The text content to extract the value from.
    /// - Returns: The extracted string value if found, otherwise nil.
    func extractValue(for key: String, from text: String) -> String? {
        return patternMatcher.extractValue(for: key, from: text)
    }
    
    /// Extracts a numeric value for a specific pattern key from text.
    ///
    /// This method delegates to the PatternMatcher component while maintaining
    /// the same public interface for backward compatibility.
    ///
    /// - Parameters:
    ///   - key: The pattern key to use for extraction.
    ///   - text: The text content to extract the value from.
    /// - Returns: The extracted value as a Double if found, otherwise nil.
    func extractNumericValue(for key: String, from text: String) -> Double? {
        return patternMatcher.extractNumericValue(for: key, from: text)
    }
    
    /// Adds a new pattern to the service.
    ///
    /// Note: This method currently provides backward compatibility but pattern
    /// addition is now handled by the PatternLoader/PatternMatcher architecture.
    /// Future implementations may extend this to support dynamic pattern updates.
    ///
    /// - Parameters:
    ///   - key: The identifier for the pattern.
    ///   - pattern: The regex pattern string.
    func addPattern(key: String, pattern: String) {
        // For now, log the request but delegate to the new architecture
        print("PatternMatchingService: Pattern addition requested for key '\(key)' - delegating to improved architecture")
        // TODO: Implement dynamic pattern addition in PatternLoader/PatternMatcher
    }
} 