import Foundation

/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: [REFACTORED]/300 lines
/// Core service interface for data extraction - delegates complex logic to specialized components

/// Provides utility functions for extracting structured data (financial figures, dates, personal info)
/// from raw text content, typically derived from PDF documents or filenames.
/// Uses dependency injection to coordinate between extraction algorithms and validation components.
@MainActor
final class DataExtractionService: DataExtractionServiceProtocol {
    
    // MARK: - Dependencies
    
    private let algorithms: DataExtractionAlgorithms
    private let validation: DataExtractionValidation
    
    // MARK: - Initialization
    
    init(
        algorithms: DataExtractionAlgorithms = DataExtractionAlgorithms(),
        validation: DataExtractionValidation = DataExtractionValidation()
    ) {
        self.algorithms = algorithms
        self.validation = validation
    }
    
    // MARK: - Public Interface
    
    /// Extracts financial data from text using predefined and common patterns.
    /// Attempts to identify specific earnings/deductions and calculates totals if needed.
    /// - Parameter text: The text to analyze
    /// - Returns: Dictionary mapping data keys to values
    func extractFinancialData(from text: String) -> [String: Double] {
        print("[DataExtractionService] Starting financial data extraction")
        
        // Delegate to algorithms component
        let extractedData = algorithms.extractFinancialData(from: text)
        
        // Validate the extracted data
        let validationResult = validation.validateFinancialData(extractedData)
        validation.logValidationResult(validationResult, context: "Financial Data Extraction")
        
        // Log suggestions if quality is low
        if validationResult.qualityScore < 0.7 {
            let suggestions = validation.getImprovementSuggestions(for: validationResult)
            for suggestion in suggestions {
                print("[DataExtractionService] SUGGESTION: \(suggestion)")
            }
        }
        
        print("[DataExtractionService] Completed financial data extraction with quality score: \(String(format: "%.2f", validationResult.qualityScore * 100))%")
        return extractedData
    }
    
    /// Extracts the payslip statement date (month and year) from the text.
    /// Tries multiple common patterns like "STATEMENT OF ACCOUNT FOR MM/YYYY" and "Month YYYY".
    /// - Parameter text: The text to analyze
    /// - Returns: Tuple containing month name and year if found
    func extractStatementDate(from text: String) -> (month: String, year: Int)? {
        print("[DataExtractionService] Starting statement date extraction")
        
        // Delegate to algorithms component
        let extractedDate = algorithms.extractStatementDate(from: text)
        
        // Validate the extracted date if found
        if let date = extractedDate {
            let validationResult = validation.validateDate(month: date.month, year: date.year)
            validation.logValidationResult(validationResult, context: "Statement Date Extraction")
            
            // Return the date even if there are warnings (unless there are errors)
            if validationResult.isValid {
                print("[DataExtractionService] Successfully extracted statement date: \(date.month) \(date.year)")
                return date
            } else {
                print("[DataExtractionService] Extracted date failed validation")
                return nil
            }
        }
        
        print("[DataExtractionService] No statement date found in text")
        return nil
    }
    
    /// Extracts the month and year from a filename string.
    /// Attempts various common date patterns found in filenames (e.g., "Dec 2024.pdf", "12-2024.pdf").
    /// - Parameter filename: The filename to analyze
    /// - Returns: Tuple containing month name and year if found
    func extractMonthAndYearFromFilename(_ filename: String) -> (String, Int)? {
        print("[DataExtractionService] Starting filename date extraction")
        
        // Validate filename first
        let filenameValidation = validation.validateFilename(filename)
        validation.logValidationResult(filenameValidation, context: "Filename Validation")
        
        // Delegate to algorithms component
        let extractedDate = algorithms.extractMonthAndYearFromFilename(filename)
        
        // Validate the extracted date if found
        if let date = extractedDate {
            let dateValidation = validation.validateDate(month: date.0, year: date.1)
            validation.logValidationResult(dateValidation, context: "Filename Date Extraction")
            
            // Return the date even if there are warnings (unless there are errors)
            if dateValidation.isValid {
                print("[DataExtractionService] Successfully extracted date from filename: \(date.0) \(date.1)")
                return date
            } else {
                print("[DataExtractionService] Extracted filename date failed validation")
                return nil
            }
        }
        
        print("[DataExtractionService] No date found in filename")
        return nil
    }
    
    // MARK: - Enhanced Extraction Methods
    
    /// Performs comprehensive data extraction with cross-validation between text and filename
    /// - Parameters:
    ///   - text: The document text content
    ///   - filename: The document filename
    /// - Returns: Comprehensive extraction results
    func extractComprehensiveData(
        from text: String, 
        filename: String
    ) -> (financialData: [String: Double], date: (month: String, year: Int)?, qualityScore: Double) {
        print("[DataExtractionService] Starting comprehensive data extraction")
        
        // Extract financial data
        let financialData = extractFinancialData(from: text)
        
        // Extract dates from both sources
        let textDate = extractStatementDate(from: text)
        let filenameDate = extractMonthAndYearFromFilename(filename)
        
        // Cross-validate dates
        let dateConsistencyResult = validation.validateDateConsistency(
            textDate: textDate,
            filenameDate: filenameDate
        )
        validation.logValidationResult(dateConsistencyResult, context: "Date Consistency Check")
        
        // Choose the best date (prefer text date if available, otherwise filename date)
        let finalDate = textDate ?? filenameDate
        
        // Perform overall quality validation
        let overallQuality = validation.validateOverallQuality(
            financialData: financialData,
            date: finalDate,
            extractionMethod: "comprehensive"
        )
        validation.logValidationResult(overallQuality, context: "Overall Quality Assessment")
        
        print("[DataExtractionService] Completed comprehensive extraction - Quality: \(String(format: "%.2f", overallQuality.qualityScore * 100))%")
        
        return (
            financialData: financialData,
            date: finalDate,
            qualityScore: overallQuality.qualityScore
        )
    }
}

// MARK: - Protocol Definition

/// Protocol defining the interface for data extraction services
/// Enables dependency injection and testing
@MainActor
protocol DataExtractionServiceProtocol {
    func extractFinancialData(from text: String) -> [String: Double]
    func extractStatementDate(from text: String) -> (month: String, year: Int)?
    func extractMonthAndYearFromFilename(_ filename: String) -> (String, Int)?
    func extractComprehensiveData(from text: String, filename: String) -> (financialData: [String: Double], date: (month: String, year: Int)?, qualityScore: Double)
} 