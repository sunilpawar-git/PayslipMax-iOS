import Foundation

/// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
/// Current: [NEW_FILE]/300 lines
/// Contains validation types, enums, and result structures

/// Defines validation error types and result structures for data extraction validation.
/// Separated to maintain single responsibility and keep validation logic files under 300 lines.
struct DataExtractionValidationTypes {
    
    // MARK: - Validation Error Types
    
    enum ValidationError: Error, LocalizedError {
        case invalidFinancialValue(key: String, value: String)
        case missingRequiredData(key: String)
        case invalidDateFormat(input: String)
        case invalidYearRange(year: Int)
        case invalidMonthValue(month: String)
        case inconsistentFinancialData(credits: Double, debits: Double, difference: Double)
        
        var errorDescription: String? {
            switch self {
            case .invalidFinancialValue(let key, let value):
                return "Invalid financial value for \(key): \(value)"
            case .missingRequiredData(let key):
                return "Missing required data: \(key)"
            case .invalidDateFormat(let input):
                return "Invalid date format: \(input)"
            case .invalidYearRange(let year):
                return "Year out of valid range: \(year)"
            case .invalidMonthValue(let month):
                return "Invalid month value: \(month)"
            case .inconsistentFinancialData(let credits, let debits, let difference):
                return "Inconsistent financial data - Credits: \(credits), Debits: \(debits), Difference: \(difference)"
            }
        }
    }
    
    // MARK: - Validation Result Structure
    
    struct ValidationResult {
        let isValid: Bool
        let errors: [ValidationError]
        let warnings: [String]
        let qualityScore: Double // 0.0 to 1.0
        
        static let valid = ValidationResult(isValid: true, errors: [], warnings: [], qualityScore: 1.0)
        
        /// Creates a failed validation result
        static func failed(errors: [ValidationError], warnings: [String] = []) -> ValidationResult {
            return ValidationResult(isValid: false, errors: errors, warnings: warnings, qualityScore: 0.0)
        }
        
        /// Creates a warning-only validation result
        static func warning(_ warnings: [String], qualityScore: Double = 0.8) -> ValidationResult {
            return ValidationResult(isValid: true, errors: [], warnings: warnings, qualityScore: qualityScore)
        }
    }
    
    // MARK: - Field Validation Rules
    
    struct FinancialFieldRules {
        let minValue: Double
        let maxValue: Double
        let allowNegative: Bool
        let fieldType: FieldType
        
        enum FieldType {
            case tax
            case income
            case deduction
            case total
            case other
        }
        
        static let standardRules: [String: FinancialFieldRules] = [
            "ITAX": FinancialFieldRules(minValue: 0, maxValue: 500_000, allowNegative: false, fieldType: .tax),
            "EHCESS": FinancialFieldRules(minValue: 0, maxValue: 50_000, allowNegative: false, fieldType: .tax),
            "BPAY": FinancialFieldRules(minValue: 1, maxValue: 1_000_000, allowNegative: false, fieldType: .income),
            "DA": FinancialFieldRules(minValue: 0, maxValue: 500_000, allowNegative: false, fieldType: .income),
            "MSP": FinancialFieldRules(minValue: 0, maxValue: 200_000, allowNegative: false, fieldType: .income),
            "credits": FinancialFieldRules(minValue: 1000, maxValue: 2_000_000, allowNegative: false, fieldType: .total),
            "debits": FinancialFieldRules(minValue: 0, maxValue: 1_000_000, allowNegative: false, fieldType: .total)
        ]
        
        static func getRules(for key: String) -> FinancialFieldRules {
            return standardRules[key.uppercased()] ?? FinancialFieldRules(
                minValue: 0,
                maxValue: 1_000_000,
                allowNegative: false,
                fieldType: .other
            )
        }
    }
    
    // MARK: - Date Validation Rules
    
    struct DateValidationRules {
        static let validYearRange: ClosedRange<Int> = {
            let currentYear = Calendar.current.component(.year, from: Date())
            return 2000...currentYear + 1
        }()
        
        static let validMonths = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]
        
        static let oldDateThreshold: Int = {
            Calendar.current.component(.year, from: Date()) - 10
        }()
    }
    
    // MARK: - Quality Score Thresholds
    
    struct QualityThresholds {
        static let excellent: Double = 0.9
        static let good: Double = 0.7
        static let acceptable: Double = 0.5
        static let poor: Double = 0.3
        
        static func getQualityDescription(for score: Double) -> String {
            switch score {
            case excellent...1.0:
                return "Excellent"
            case good..<excellent:
                return "Good"
            case acceptable..<good:
                return "Acceptable"
            case poor..<acceptable:
                return "Poor"
            default:
                return "Very Poor"
            }
        }
    }
    
    // MARK: - Validation Context
    
    struct ValidationContext {
        let extractionMethod: String
        let dataSource: DataSource
        let timestamp: Date
        
        enum DataSource {
            case textContent
            case filename
            case comprehensive
            case crossValidation
        }
        
        init(extractionMethod: String, dataSource: DataSource) {
            self.extractionMethod = extractionMethod
            self.dataSource = dataSource
            self.timestamp = Date()
        }
    }
    
    // MARK: - Validation Metrics
    
    struct ValidationMetrics {
        let totalFields: Int
        let validFields: Int
        let warningFields: Int
        let errorFields: Int
        let overallScore: Double
        
        var completenessRatio: Double {
            return totalFields > 0 ? Double(validFields) / Double(totalFields) : 0.0
        }
        
        var errorRatio: Double {
            return totalFields > 0 ? Double(errorFields) / Double(totalFields) : 0.0
        }
        
        init(totalFields: Int, validFields: Int, warningFields: Int, errorFields: Int, overallScore: Double) {
            self.totalFields = totalFields
            self.validFields = validFields
            self.warningFields = warningFields
            self.errorFields = errorFields
            self.overallScore = overallScore
        }
    }
}
