import Foundation

/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: [REFACTORED]/300 lines
/// Contains core validation logic for data extraction - uses extracted types

/// Handles validation rules, error handling, and data quality checks for extracted information.
/// Ensures extracted data meets quality standards and business rules.
/// Uses extracted types to maintain single responsibility principle and stay under 300 lines.
final class DataExtractionValidation {
    
    // MARK: - Type Aliases for Convenience
    
    typealias ValidationError = DataExtractionValidationTypes.ValidationError
    typealias ValidationResult = DataExtractionValidationTypes.ValidationResult
    typealias FinancialFieldRules = DataExtractionValidationTypes.FinancialFieldRules
    typealias DateValidationRules = DataExtractionValidationTypes.DateValidationRules
    typealias QualityThresholds = DataExtractionValidationTypes.QualityThresholds
    
    // MARK: - Financial Data Validation
    
    /// Validates extracted financial data for consistency and completeness
    /// - Parameter financialData: The extracted financial data dictionary
    /// - Returns: ValidationResult containing validation status and any issues
    func validateFinancialData(_ financialData: [String: Double]) -> ValidationResult {
        let errors: [ValidationError] = []
        var warnings: [String] = []
        var qualityScore: Double = 1.0
        
        // Validate each field against its rules
        for (key, value) in financialData {
            let rules = FinancialFieldRules.getRules(for: key)
            
            if value < rules.minValue || value > rules.maxValue {
                if value < 0 && !rules.allowNegative {
                    warnings.append("Negative value detected for \(key): \(value)")
                    qualityScore -= 0.1
                } else {
                    warnings.append("Value out of range for \(key): \(value)")
                    qualityScore -= 0.05
                }
            }
        }
        
        // Validate financial consistency
        qualityScore = validateFinancialConsistency(financialData, currentScore: qualityScore, warnings: &warnings)
        
        // Check for missing common fields
        qualityScore = checkMissingFields(financialData, currentScore: qualityScore, warnings: &warnings)
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            qualityScore: max(0.0, qualityScore)
        )
    }
    
    /// Validates individual financial values during extraction
    /// - Parameters:
    ///   - value: The string value to validate
    ///   - key: The key/field name for context
    /// - Returns: True if the value is valid for extraction
    func isValidFinancialValue(_ value: String, forKey key: String) -> Bool {
        let cleanValue = value.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let doubleValue = Double(cleanValue) else { return false }
        
        let rules = FinancialFieldRules.getRules(for: key)
        return doubleValue >= rules.minValue && doubleValue <= rules.maxValue && (rules.allowNegative || doubleValue >= 0)
    }
    
    // MARK: - Private Helper Methods
    
    private func validateFinancialConsistency(_ data: [String: Double], currentScore: Double, warnings: inout [String]) -> Double {
        var score = currentScore
        
        if let credits = data["credits"], let debits = data["debits"] {
            let difference = abs(credits - debits)
            let tolerance = max(credits, debits) * 0.01
            
            if difference > tolerance && difference > 100 {
                warnings.append("Large difference between credits (\(credits)) and debits (\(debits))")
                score -= 0.1
            }
            
            if debits > credits {
                warnings.append("Debits (\(debits)) exceed credits (\(credits)) - unusual but possible")
                score -= 0.05
            }
        }
        
        return score
    }
    
    private func checkMissingFields(_ data: [String: Double], currentScore: Double, warnings: inout [String]) -> Double {
        let commonFields = ["BPAY", "DA", "ITAX"]
        let missingFields = commonFields.filter { !data.keys.contains($0) }
        
        if !missingFields.isEmpty {
            warnings.append("Missing common fields: \(missingFields.joined(separator: ", "))")
            return currentScore - Double(missingFields.count) * 0.05
        }
        
        return currentScore
    }
    
    // MARK: - Date Validation
    
    /// Validates extracted date information
    /// - Parameters:
    ///   - month: The extracted month name
    ///   - year: The extracted year
    /// - Returns: ValidationResult for the date
    func validateDate(month: String, year: Int) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [String] = []
        var qualityScore: Double = 1.0
        
        // Validate year range
        if !DateValidationRules.validYearRange.contains(year) {
            errors.append(.invalidYearRange(year: year))
            qualityScore = 0.0
        }
        
        // Validate month name
        if !DateValidationRules.validMonths.contains(month) {
            errors.append(.invalidMonthValue(month: month))
            qualityScore = 0.0
        }
        
        // Check for warnings
        let currentYear = Calendar.current.component(.year, from: Date())
        if year > currentYear {
            warnings.append("Future date detected: \(month) \(year)")
            qualityScore -= 0.1
        }
        
        if year < DateValidationRules.oldDateThreshold {
            warnings.append("Very old date detected: \(month) \(year)")
            qualityScore -= 0.05
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            qualityScore: max(0.0, qualityScore)
        )
    }
    
    /// Validates filename format and content
    /// - Parameter filename: The filename to validate
    /// - Returns: ValidationResult for the filename
    func validateFilename(_ filename: String) -> ValidationResult {
        var warnings: [String] = []
        var qualityScore: Double = 1.0
        
        // Basic filename checks
        if filename.count > 255 {
            warnings.append("Filename is very long")
            qualityScore -= 0.1
        }
        
        if filename.rangeOfCharacter(from: CharacterSet(charactersIn: "<>:\"|?*")) != nil {
            warnings.append("Filename contains problematic characters")
            qualityScore -= 0.1
        }
        
        if filename.range(of: "\\d{4}", options: .regularExpression) == nil {
            warnings.append("Filename doesn't contain a year")
            qualityScore -= 0.2
        }
        
        if !filename.lowercased().hasSuffix(".pdf") {
            warnings.append("File is not a PDF")
            qualityScore -= 0.1
        }
        
        return ValidationResult(isValid: true, errors: [], warnings: warnings, qualityScore: max(0.0, qualityScore))
    }
    
    // MARK: - Cross-Validation Methods
    
    /// Performs cross-validation between different extraction methods
    func validateDateConsistency(
        textDate: (month: String, year: Int)?,
        filenameDate: (month: String, year: Int)?
    ) -> ValidationResult {
        guard let textDate = textDate, let filenameDate = filenameDate else {
            return ValidationResult.valid
        }
        
        var warnings: [String] = []
        var qualityScore: Double = 1.0
        
        if textDate.year != filenameDate.year {
            warnings.append("Year mismatch: text=\(textDate.year), filename=\(filenameDate.year)")
            qualityScore -= 0.3
        }
        
        if textDate.month != filenameDate.month {
            warnings.append("Month mismatch: text=\(textDate.month), filename=\(filenameDate.month)")
            qualityScore -= 0.2
        }
        
        return ValidationResult(isValid: true, errors: [], warnings: warnings, qualityScore: max(0.0, qualityScore))
    }
    
    /// Validates the overall extraction quality
    func validateOverallQuality(
        financialData: [String: Double],
        date: (month: String, year: Int)?,
        extractionMethod: String
    ) -> ValidationResult {
        let financialValidation = validateFinancialData(financialData)
        var overallWarnings = financialValidation.warnings
        var overallQualityScore = financialValidation.qualityScore
        
        // Check for empty extraction
        if financialData.isEmpty {
            overallWarnings.append("No financial data extracted")
            overallQualityScore = 0.0
        }
        
        // Validate date if available
        if let date = date {
            let dateValidation = validateDate(month: date.month, year: date.year)
            overallWarnings.append(contentsOf: dateValidation.warnings)
            overallQualityScore = min(overallQualityScore, dateValidation.qualityScore)
        } else {
            overallWarnings.append("No date information extracted")
            overallQualityScore -= 0.1
        }
        
        // Adjust score based on extraction method
        overallQualityScore *= getMethodConfidenceMultiplier(extractionMethod)
        
        return ValidationResult(
            isValid: financialValidation.isValid,
            errors: financialValidation.errors,
            warnings: overallWarnings,
            qualityScore: max(0.0, overallQualityScore)
        )
    }
    
    // MARK: - Helper Methods
    
    /// Logs validation results for monitoring and debugging
    func logValidationResult(_ result: ValidationResult, context: String) {
        let prefix = "[DataExtractionValidation] \(context)"
        
        if result.isValid {
            print("\(prefix) - Quality: \(String(format: "%.2f", result.qualityScore * 100))%")
        } else {
            print("\(prefix) - VALIDATION FAILED")
            result.errors.forEach { print("\(prefix) - ERROR: \($0.localizedDescription)") }
        }
        
        result.warnings.forEach { print("\(prefix) - WARNING: \($0)") }
    }
    
    /// Provides suggestions for improving extraction quality
    func getImprovementSuggestions(for result: ValidationResult) -> [String] {
        var suggestions: [String] = []
        
        if result.qualityScore < QualityThresholds.acceptable {
            suggestions.append("Consider using alternative extraction methods")
            suggestions.append("Verify PDF quality and text extraction")
        }
        
        if result.warnings.contains(where: { $0.contains("missing") }) {
            suggestions.append("Check if document contains all required fields")
            suggestions.append("Consider updating extraction patterns")
        }
        
        if result.warnings.contains(where: { $0.contains("mismatch") }) {
            suggestions.append("Verify document integrity")
            suggestions.append("Check filename consistency with content")
        }
        
        return suggestions
    }
    
    private func getMethodConfidenceMultiplier(_ method: String) -> Double {
        switch method.lowercased() {
        case "enhanced_structure_preservation": return 1.0
        case "table_extraction": return 0.9
        case "fallback_patterns": return 0.8
        default: return 0.7
        }
    }
}
