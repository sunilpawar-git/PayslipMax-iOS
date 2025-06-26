import Foundation
import SwiftUI

/// Handles error handling and data validation for analytics operations
@MainActor
class AnalyticsErrorHandler: ObservableObject {
    
    // MARK: - Constants
    private struct ValidationConstants {
        static let minimumDataPointsForAnalysis = 3
        static let maximumReasonableIncome = 10000000.0 // 1 crore
        static let minimumReasonableIncome = 1000.0 // 1000 rupees
    }
    
    // MARK: - Error Handling for Insufficient Data
    
    func handleInsufficientData() async -> (FinancialHealthScore, [PredictiveInsight], [ProfessionalRecommendation]) {
        let healthScore = FinancialHealthScore(
            overallScore: 50,
            categories: [],
            trend: .stable,
            lastUpdated: Date()
        )
        
        let insights: [PredictiveInsight] = []
        
        let recommendations = [
            ProfessionalRecommendation(
                category: .careerGrowth,
                title: "Upload More Payslips",
                summary: "We need more data to provide accurate insights",
                detailedAnalysis: "Please upload at least 3 months of payslips for comprehensive analysis.",
                actionSteps: ["Upload recent payslips", "Ensure data accuracy"],
                potentialSavings: nil,
                priority: .medium,
                source: .aiAnalysis
            )
        ]
        
        return (healthScore, insights, recommendations)
    }
    
    // MARK: - Data Validation
    
    func validatePayslipData(_ payslips: [PayslipItem]) async -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Check minimum data points
        if payslips.count < ValidationConstants.minimumDataPointsForAnalysis {
            errors.append(.insufficientData(count: payslips.count, required: ValidationConstants.minimumDataPointsForAnalysis))
        }
        
        // Validate individual payslips
        for (index, payslip) in payslips.enumerated() {
            let payslipErrors = validateIndividualPayslip(payslip, index: index)
            errors.append(contentsOf: payslipErrors.errors)
            warnings.append(contentsOf: payslipErrors.warnings)
        }
        
        // Check for data consistency
        let consistencyIssues = validateDataConsistency(payslips)
        warnings.append(contentsOf: consistencyIssues)
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            canProceedWithWarnings: errors.isEmpty
        )
    }
    
    private func validateIndividualPayslip(_ payslip: PayslipItem, index: Int) -> (errors: [ValidationError], warnings: [ValidationWarning]) {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Validate income range
        if payslip.credits < ValidationConstants.minimumReasonableIncome {
            warnings.append(.unreasonableValue(field: "credits", value: payslip.credits, payslipIndex: index))
        }
        
        if payslip.credits > ValidationConstants.maximumReasonableIncome {
            warnings.append(.unreasonableValue(field: "credits", value: payslip.credits, payslipIndex: index))
        }
        
        // Validate negative values
        if payslip.credits < 0 {
            errors.append(.negativeValue(field: "credits", value: payslip.credits, payslipIndex: index))
        }
        
        if payslip.debits < 0 {
            errors.append(.negativeValue(field: "debits", value: payslip.debits, payslipIndex: index))
        }
        
        if payslip.tax < 0 {
            errors.append(.negativeValue(field: "tax", value: payslip.tax, payslipIndex: index))
        }
        
        if payslip.dsop < 0 {
            errors.append(.negativeValue(field: "dsop", value: payslip.dsop, payslipIndex: index))
        }
        
        // Validate deduction ratios
        let totalDeductions = payslip.debits + payslip.tax + payslip.dsop
        if totalDeductions > payslip.credits {
            warnings.append(.deductionsExceedIncome(income: payslip.credits, deductions: totalDeductions, payslipIndex: index))
        }
        
        // Validate date
        if payslip.timestamp > Date() {
            warnings.append(.futureDate(date: payslip.timestamp, payslipIndex: index))
        }
        
        return (errors, warnings)
    }
    
    private func validateDataConsistency(_ payslips: [PayslipItem]) -> [ValidationWarning] {
        var warnings: [ValidationWarning] = []
        
        guard payslips.count >= 2 else { return warnings }
        
        let incomes = payslips.map { $0.credits }
        let mean = incomes.reduce(0, +) / Double(incomes.count)
        let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
        let volatility = sqrt(variance) / mean
        
        // Check for extreme volatility
        if volatility > 0.5 {
            warnings.append(.extremeVolatility(volatility: volatility))
        }
        
        // Check for duplicate dates
        let dates = payslips.map { Calendar.current.dateInterval(of: .month, for: $0.timestamp) }
        let uniqueDates = Set(dates.compactMap { $0?.start })
        if uniqueDates.count < dates.count {
            warnings.append(.duplicateMonths)
        }
        
        return warnings
    }
    
    // MARK: - Error Recovery Strategies
    
    func attemptDataRecovery(_ payslips: [PayslipItem]) async -> [PayslipItem] {
        var recoveredPayslips = payslips
        
        // Remove payslips with critical errors
        recoveredPayslips = recoveredPayslips.filter { payslip in
            payslip.credits >= 0 && payslip.debits >= 0 && payslip.tax >= 0 && payslip.dsop >= 0
        }
        
        // Sort by date to ensure chronological order
        recoveredPayslips.sort { $0.timestamp > $1.timestamp }
        
        // Remove extreme outliers (beyond 3 standard deviations)
        if recoveredPayslips.count >= 3 {
            let incomes = recoveredPayslips.map { $0.credits }
            let mean = incomes.reduce(0, +) / Double(incomes.count)
            let variance = incomes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(incomes.count)
            let standardDeviation = sqrt(variance)
            
            recoveredPayslips = recoveredPayslips.filter { payslip in
                abs(payslip.credits - mean) <= 3 * standardDeviation
            }
        }
        
        return recoveredPayslips
    }
    
    // MARK: - Safe Calculation Wrappers
    
    func safeCalculateAverage(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    func safeCalculateGrowthRate(current: Double, previous: Double) -> Double {
        guard previous > 0 else { return 0.0 }
        return (current - previous) / previous
    }
    
    func safeCalculateRatio(numerator: Double, denominator: Double) -> Double {
        guard denominator > 0 else { return 0.0 }
        return numerator / denominator
    }
    
    func safeCalculatePercentile(values: [Double], percentile: Double) -> Double {
        guard !values.isEmpty else { return 0.0 }
        guard percentile >= 0 && percentile <= 1 else { return 0.0 }
        
        let sortedValues = values.sorted()
        let index = percentile * Double(sortedValues.count - 1)
        let lower = Int(floor(index))
        let upper = Int(ceil(index))
        
        if lower == upper {
            return sortedValues[lower]
        } else {
            let weight = index - Double(lower)
            return sortedValues[lower] * (1 - weight) + sortedValues[upper] * weight
        }
    }
    
    // MARK: - Logging and Monitoring
    
    func logAnalyticsError(_ error: AnalyticsError, context: String) {
        // In a real implementation, this would log to analytics service
        print("Analytics Error in \(context): \(error)")
    }
    
    func logValidationWarning(_ warning: ValidationWarning, context: String) {
        // In a real implementation, this would log to analytics service
        print("Validation Warning in \(context): \(warning)")
    }
}

// MARK: - Supporting Types

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]
    let canProceedWithWarnings: Bool
}

enum ValidationError: Error, CustomStringConvertible {
    case insufficientData(count: Int, required: Int)
    case negativeValue(field: String, value: Double, payslipIndex: Int)
    case invalidDateRange(startDate: Date, endDate: Date)
    case corruptedData(payslipIndex: Int)
    
    var description: String {
        switch self {
        case .insufficientData(let count, let required):
            return "Insufficient data: \(count) payslips provided, \(required) required"
        case .negativeValue(let field, let value, let index):
            return "Negative value in \(field): \(value) at payslip \(index)"
        case .invalidDateRange(let start, let end):
            return "Invalid date range: \(start) to \(end)"
        case .corruptedData(let index):
            return "Corrupted data at payslip \(index)"
        }
    }
}

enum ValidationWarning: CustomStringConvertible {
    case unreasonableValue(field: String, value: Double, payslipIndex: Int)
    case deductionsExceedIncome(income: Double, deductions: Double, payslipIndex: Int)
    case futureDate(date: Date, payslipIndex: Int)
    case extremeVolatility(volatility: Double)
    case duplicateMonths
    case missingOptionalData(field: String, payslipIndex: Int)
    
    var description: String {
        switch self {
        case .unreasonableValue(let field, let value, let index):
            return "Unreasonable value in \(field): \(value) at payslip \(index)"
        case .deductionsExceedIncome(let income, let deductions, let index):
            return "Deductions (\(deductions)) exceed income (\(income)) at payslip \(index)"
        case .futureDate(let date, let index):
            return "Future date \(date) at payslip \(index)"
        case .extremeVolatility(let volatility):
            return "Extreme income volatility detected: \(volatility)"
        case .duplicateMonths:
            return "Multiple payslips found for the same month"
        case .missingOptionalData(let field, let index):
            return "Missing optional data in \(field) at payslip \(index)"
        }
    }
}

enum AnalyticsError: Error {
    case calculationFailed(operation: String)
    case invalidInput(parameter: String)
    case serviceUnavailable
    case timeoutError
} 