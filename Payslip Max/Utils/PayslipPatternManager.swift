import Foundation

/// A utility class for extracting data from payslips using regex patterns.
///
/// This class provides methods for extracting various data points from payslip text
/// using regular expressions tailored to specific payslip formats.
class PayslipPatternManager {
    // Dependencies
    private let patternProvider: PatternProvider
    private let textExtractor: TextExtractor
    private let validator: PayslipValidator
    private let payslipBuilder: PayslipBuilder
    private let textExtractorImpl: TextExtractorImplementation
    
    // MARK: - Initialization
    
    /// Default initializer
    init() {
        let provider = DefaultPatternProvider()
        self.patternProvider = provider
        self.validator = PayslipValidator(patternProvider: provider)
        self.textExtractor = DefaultTextExtractor(patternProvider: provider)
        self.textExtractorImpl = TextExtractorImplementation(patternProvider: provider)
        self.payslipBuilder = PayslipBuilder(patternProvider: provider, validator: validator)
    }
    
    /// Dependency injection initializer
    init(patternProvider: PatternProvider,
         textExtractor: TextExtractor,
         validator: PayslipValidator,
         payslipBuilder: PayslipBuilder) {
        self.patternProvider = patternProvider
        self.textExtractor = textExtractor
        self.validator = validator
        self.payslipBuilder = payslipBuilder
        self.textExtractorImpl = TextExtractorImplementation(patternProvider: patternProvider)
    }
    
    // MARK: - Public Methods
    
    /// Adds a new pattern to the patterns dictionary.
    ///
    /// - Parameters:
    ///   - key: The key for the pattern.
    ///   - pattern: The regex pattern.
    func addPattern(key: String, pattern: String) {
        patternProvider.addPattern(key: key, pattern: pattern)
    }
    
    /// Checks if a term is blacklisted in a specific context
    ///
    /// - Parameters:
    ///   - term: The term to check
    ///   - context: The context (e.g., "earnings" or "deductions")
    /// - Returns: True if the term is blacklisted in the given context
    func isBlacklisted(_ term: String, in context: String) -> Bool {
        return textExtractorImpl.isBlacklisted(term, in: context)
    }
    
    /// Attempts to extract a clean code from a potentially merged code
    ///
    /// - Parameter code: The code to clean
    /// - Returns: A tuple containing the cleaned code and any extracted value
    func extractCleanCode(from code: String) -> (cleanedCode: String, extractedValue: Double?) {
        return textExtractorImpl.extractCleanCode(from: code)
    }
    
    /// Extracts data from text using the patterns dictionary.
    ///
    /// - Parameter text: The text to extract data from.
    /// - Returns: A dictionary of extracted data.
    func extractData(from text: String) -> [String: String] {
        return textExtractor.extractData(from: text)
    }
    
    /// Extracts tabular data from text.
    ///
    /// - Parameter text: The text to extract data from.
    /// - Returns: A tuple containing earnings and deductions dictionaries.
    func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        return textExtractor.extractTabularData(from: text)
    }
    
    /// Calculates total earnings from a dictionary of earnings.
    ///
    /// - Parameter earnings: The earnings dictionary.
    /// - Returns: The total earnings.
    func calculateTotalEarnings(from earnings: [String: Double]) -> Double {
        return earnings.values.reduce(0, +)
    }
    
    /// Calculates total deductions from a dictionary of deductions.
    ///
    /// - Parameter deductions: The deductions dictionary.
    /// - Returns: The total deductions.
    func calculateTotalDeductions(from deductions: [String: Double]) -> Double {
        return deductions.values.reduce(0, +)
    }
    
    /// Validates financial data to ensure values are reasonable.
    ///
    /// - Parameter data: The financial data to validate.
    /// - Returns: Validated financial data.
    func validateFinancialData(_ data: [String: Double]) -> [String: Double] {
        return validator.validateFinancialData(data)
    }
    
    /// Creates a PayslipItem from extracted data.
    ///
    /// - Parameters:
    ///   - extractedData: The extracted data dictionary.
    ///   - earnings: The earnings dictionary.
    ///   - deductions: The deductions dictionary.
    ///   - pdfData: The PDF data.
    /// - Returns: A PayslipItem.
    func createPayslipItem(
        from extractedData: [String: String],
        earnings: [String: Double],
        deductions: [String: Double],
        pdfData: Data? = nil
    ) -> PayslipItem {
        return payslipBuilder.createPayslipItem(
            from: extractedData,
            earnings: earnings,
            deductions: deductions,
            pdfData: pdfData
        )
    }
    
    /// Get description for Risk & Hardship components
    ///
    /// - Parameter code: The component code (e.g., "RH11", "RH23")
    /// - Returns: A human-readable description of the Risk & Hardship component, or nil if not a valid RH code
    func getRiskHardshipDescription(for code: String) -> String? {
        return textExtractorImpl.getRiskHardshipDescription(for: code)
    }
    
    /// Extracts a numeric value from text
    /// - Parameters:
    ///   - text: The text to extract from
    ///   - pattern: The regex pattern to use
    /// - Returns: The extracted numeric value as a Double, or nil if not found
    func extractNumericValue(from text: String, using pattern: String) -> Double? {
        return textExtractorImpl.extractNumericValue(from: text, using: pattern)
    }
    
    /// Extracts month and year from text
    /// - Parameter text: The text to parse
    /// - Returns: A tuple containing the month and year, or nil if not found
    func extractMonthAndYear(from text: String) -> (month: String?, year: String?) {
        return textExtractorImpl.extractMonthAndYear(from: text)
    }
    
    /// Cleans up a numeric string value
    /// - Parameter value: The string value to clean
    /// - Returns: A cleaned numeric string
    func cleanNumericValue(_ value: String) -> String {
        return textExtractorImpl.cleanNumericValue(value)
    }
    
    /// Parse a payslip from text
    /// - Parameter text: The payslip text
    /// - Returns: A PayslipItem if successful, nil otherwise
    func parsePayslipData(_ text: String) -> PayslipItem? {
        let extractedData = textExtractor.extractData(from: text)
        let (earnings, deductions) = textExtractor.extractTabularData(from: text)
        
        // Create PayslipItem with extracted data
        return createPayslipItem(
            from: extractedData,
            earnings: earnings,
            deductions: deductions
        )
    }
    
    /// Parses an amount string into a Double value.
    ///
    /// - Parameter amountString: The amount string to parse.
    /// - Returns: The parsed amount as a Double, or nil if parsing fails.
    static func parseAmount(_ amountString: String) -> Double? {
        // Remove currency symbols, commas, and whitespace
        let cleanedString = amountString
            .replacingOccurrences(of: "[$₹,\\s]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Double(cleanedString)
    }
    
    // MARK: - Static Methods for Backward Compatibility
    
    // For backward compatibility, provide static versions of key methods
    
    /// Static version of extractData for backward compatibility
    static func extractData(from text: String) -> [String: String] {
        let manager = PayslipPatternManager()
        return manager.extractData(from: text)
    }
    
    /// Static version of extractTabularData for backward compatibility
    static func extractTabularData(from text: String) -> ([String: Double], [String: Double]) {
        let manager = PayslipPatternManager()
        return manager.extractTabularData(from: text)
    }
    
    /// Static version of calculateTotalEarnings for backward compatibility
    static func calculateTotalEarnings(from earnings: [String: Double]) -> Double {
        return earnings.values.reduce(0, +)
    }
    
    /// Static version of calculateTotalDeductions for backward compatibility
    static func calculateTotalDeductions(from deductions: [String: Double]) -> Double {
        return deductions.values.reduce(0, +)
    }
    
    /// Static version of validateFinancialData for backward compatibility
    static func validateFinancialData(_ data: [String: Double]) -> [String: Double] {
        let manager = PayslipPatternManager()
        return manager.validateFinancialData(data)
    }
    
    /// Static version of createPayslipItem for backward compatibility
    static func createPayslipItem(
        from extractedData: [String: String],
        earnings: [String: Double],
        deductions: [String: Double],
        pdfData: Data? = nil
    ) -> PayslipItem {
        let manager = PayslipPatternManager()
        return manager.createPayslipItem(
            from: extractedData,
            earnings: earnings,
            deductions: deductions,
            pdfData: pdfData
        )
    }
    
    /// Static version of parsePayslipData for backward compatibility
    static func parsePayslipData(_ text: String) -> PayslipItem? {
        let manager = PayslipPatternManager()
        return manager.parsePayslipData(text)
    }
    
    /// Static version of extractMonthAndYear for backward compatibility
    static func extractMonthAndYear(from text: String) -> (month: String?, year: String?) {
        let manager = PayslipPatternManager()
        return manager.extractMonthAndYear(from: text)
    }
    
    /// Static version of cleanNumericValue for backward compatibility
    static func cleanNumericValue(_ value: String) -> String {
        let manager = PayslipPatternManager()
        return manager.cleanNumericValue(value)
    }
    
    /// Static version of isBlacklisted for backward compatibility
    static func isBlacklisted(_ term: String, in context: String) -> Bool {
        let manager = PayslipPatternManager()
        return manager.isBlacklisted(term, in: context)
    }
    
    /// Static version of addPattern for backward compatibility
    static func addPattern(key: String, pattern: String) {
        let manager = PayslipPatternManager()
        manager.addPattern(key: key, pattern: pattern)
    }
    
    // Static properties for backward compatibility
    static var patterns: [String: String] {
        return DefaultPatternProvider().patterns
    }
    
    static var earningsPatterns: [String: String] {
        return DefaultPatternProvider().earningsPatterns
    }
    
    static var deductionsPatterns: [String: String] {
        return DefaultPatternProvider().deductionsPatterns
    }
    
    static var standardEarningsComponents: [String] {
        return DefaultPatternProvider().standardEarningsComponents
    }
    
    static var standardDeductionsComponents: [String] {
        return DefaultPatternProvider().standardDeductionsComponents
    }
    
    static var blacklistedTerms: [String] {
        return DefaultPatternProvider().blacklistedTerms
    }
    
    static var contextSpecificBlacklist: [String: [String]] {
        return DefaultPatternProvider().contextSpecificBlacklist
    }
    
    static var mergedCodePatterns: [String: String] {
        return DefaultPatternProvider().mergedCodePatterns
    }
    
    static var minimumEarningsAmount: Double {
        return DefaultPatternProvider().minimumEarningsAmount
    }
    
    static var minimumDeductionsAmount: Double {
        return DefaultPatternProvider().minimumDeductionsAmount
    }
    
    static var minimumDSOPAmount: Double {
        return DefaultPatternProvider().minimumDSOPAmount
    }
    
    static var minimumTaxAmount: Double {
        return DefaultPatternProvider().minimumTaxAmount
    }
} 
