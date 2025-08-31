import Foundation
import SwiftData

/// Protocol for AI-powered anomaly detection in payslip data
protocol AnomalyDetectionServiceProtocol {
    /// Detects unusual amounts in payslip components
    func detectAmountAnomalies(
        payslip: Payslip,
        historicalPayslips: [Payslip]
    ) async throws -> AmountAnomalyResult

    /// Identifies format anomalies in payslip structure
    func detectFormatAnomalies(
        payslip: Payslip,
        expectedFormat: LiteRTDocumentFormatType
    ) async throws -> FormatAnomalyResult

    /// Performs comprehensive fraud detection analysis
    func detectFraudIndicators(
        payslip: Payslip,
        historicalPayslips: [Payslip]
    ) async throws -> FraudDetectionResult

    /// Updates anomaly detection models with user feedback
    func updateWithUserFeedback(
        anomalyId: String,
        isFalsePositive: Bool
    ) async throws
}

/// Result of amount anomaly detection
public struct AmountAnomalyResult {
    let anomalies: [AmountAnomaly]
    let overallRisk: AnomalyRiskLevel
    let confidence: Double
    let recommendations: [String]
}

/// Individual amount anomaly
public struct AmountAnomaly {
    let component: PayslipComponent
    let expectedValue: Double
    let actualValue: Double
    let deviation: Double
    let confidence: Double
    let riskLevel: AnomalyRiskLevel
    let explanation: String
    let anomalyId: String
}

/// Payslip component types for anomaly detection
public enum PayslipComponent: Hashable {
    case basicPay
    case allowance(name: String)
    case deduction(name: String)
    case netPay
}

/// Risk levels for anomalies
public enum AnomalyRiskLevel {
    case low
    case medium
    case high
    case critical
}

/// Result of format anomaly detection
public struct FormatAnomalyResult {
    let anomalies: [FormatAnomaly]
    let formatConsistency: Double
    let structuralIntegrity: Bool
    let recommendations: [String]
}

/// Individual format anomaly
public struct FormatAnomaly {
    let anomalyType: FormatAnomalyType
    let severity: AnomalySeverity
    let location: String
    let description: String
    let suggestedCorrection: String?
}

/// Types of format anomalies
public enum FormatAnomalyType {
    case missingComponent
    case incorrectFormat
    case inconsistentStructure
    case invalidData
    case securityConcern

    /// Human-readable description of the anomaly type
    public var description: String {
        switch self {
        case .missingComponent:
            return "Missing Component"
        case .incorrectFormat:
            return "Incorrect Format"
        case .inconsistentStructure:
            return "Inconsistent Structure"
        case .invalidData:
            return "Invalid Data"
        case .securityConcern:
            return "Security Concern"
        }
    }
}

/// Severity levels for format anomalies

/// Result of fraud detection analysis
public struct FraudDetectionResult {
    let fraudIndicators: [FraudIndicator]
    let overallRisk: FraudRiskLevel
    let confidence: Double
    let recommendedActions: [String]
    let investigationPriority: InvestigationPriority
}

/// Individual fraud indicator
public struct FraudIndicator {
    let indicatorType: FraudIndicatorType
    let severity: FraudSeverity
    let evidence: String
    let confidence: Double
    let riskScore: Double
}

/// Types of fraud indicators
public enum FraudIndicatorType {
    case amountManipulation
    case duplicateEntry
    case timingAnomaly
    case formatTampering
    case statisticalOutlier
    case patternInconsistency
}

/// Severity of fraud indicators
public enum FraudSeverity {
    case low
    case medium
    case high
    case critical
}

/// Overall fraud risk levels
public enum FraudRiskLevel {
    case none
    case low
    case medium
    case high
    case critical
}

/// Investigation priority levels
public enum InvestigationPriority {
    case routine
    case priority
    case urgent
    case immediate
}

/// AI-powered anomaly detection service
@MainActor
public final class AnomalyDetectionService: @preconcurrency AnomalyDetectionServiceProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext
    private var falsePositivePatterns: [String: Int] = [:]
    private let calendar = Calendar.current

    // MARK: - Initialization

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Amount Anomaly Detection

    func detectAmountAnomalies(
        payslip: Payslip,
        historicalPayslips: [Payslip]
    ) async throws -> AmountAnomalyResult {

        guard !historicalPayslips.isEmpty else {
            throw AnomalyDetectionError.insufficientHistoricalData
        }

        var anomalies: [AmountAnomaly] = []

        // Detect basic pay anomalies
        if let basicPayAnomaly = detectBasicPayAnomaly(payslip, historicalPayslips) {
            anomalies.append(basicPayAnomaly)
        }

        // Detect allowance anomalies
        for allowance in payslip.allowances {
            if let allowanceAnomaly = detectAllowanceAnomaly(allowance, payslip, historicalPayslips) {
                anomalies.append(allowanceAnomaly)
            }
        }

        // Detect deduction anomalies
        for deduction in payslip.deductions {
            if let deductionAnomaly = detectDeductionAnomaly(deduction, payslip, historicalPayslips) {
                anomalies.append(deductionAnomaly)
            }
        }

        // Detect net pay anomalies
        if let netPayAnomaly = detectNetPayAnomaly(payslip, historicalPayslips) {
            anomalies.append(netPayAnomaly)
        }

        let overallRisk = calculateOverallRisk(anomalies)
        let confidence = calculateDetectionConfidence(historicalPayslips)
        let recommendations = generateAmountRecommendations(anomalies, overallRisk)

        return AmountAnomalyResult(
            anomalies: anomalies,
            overallRisk: overallRisk,
            confidence: confidence,
            recommendations: recommendations
        )
    }

    // MARK: - Format Anomaly Detection

    func detectFormatAnomalies(
        payslip: Payslip,
        expectedFormat: LiteRTDocumentFormatType
    ) async throws -> FormatAnomalyResult {

        var anomalies: [FormatAnomaly] = []

        // Check for missing critical components
        let missingComponents = detectMissingComponents(payslip, expectedFormat)
        anomalies.append(contentsOf: missingComponents)

        // Check format consistency
        let formatIssues = detectFormatInconsistencies(payslip, expectedFormat)
        anomalies.append(contentsOf: formatIssues)

        // Check data validity
        let dataIssues = detectDataValidityIssues(payslip)
        anomalies.append(contentsOf: dataIssues)

        // Check structural integrity
        let structuralIssues = detectStructuralIssues(payslip)
        anomalies.append(contentsOf: structuralIssues)

        let formatConsistency = calculateFormatConsistency(payslip, expectedFormat, anomalies)
        let structuralIntegrity = !anomalies.contains(where: { $0.severity == .critical })
        let recommendations = generateFormatRecommendations(anomalies)

        return FormatAnomalyResult(
            anomalies: anomalies,
            formatConsistency: formatConsistency,
            structuralIntegrity: structuralIntegrity,
            recommendations: recommendations
        )
    }

    // MARK: - Fraud Detection

    func detectFraudIndicators(
        payslip: Payslip,
        historicalPayslips: [Payslip]
    ) async throws -> FraudDetectionResult {

        var indicators: [FraudIndicator] = []

        // Statistical analysis for outliers
        let statisticalIndicators = detectStatisticalAnomalies(payslip, historicalPayslips)
        indicators.append(contentsOf: statisticalIndicators)

        // Pattern analysis
        let patternIndicators = detectPatternInconsistencies(payslip, historicalPayslips)
        indicators.append(contentsOf: patternIndicators)

        // Timing analysis
        let timingIndicators = detectTimingAnomalies(payslip, historicalPayslips)
        indicators.append(contentsOf: timingIndicators)

        // Amount manipulation detection
        let manipulationIndicators = detectAmountManipulation(payslip, historicalPayslips)
        indicators.append(contentsOf: manipulationIndicators)

        // Duplicate detection
        let duplicateIndicators = detectDuplicateEntries(payslip, historicalPayslips)
        indicators.append(contentsOf: duplicateIndicators)

        let overallRisk = calculateFraudRisk(indicators)
        let confidence = calculateFraudConfidence(indicators, historicalPayslips)
        let actions = generateFraudActions(indicators, overallRisk)
        let priority = determineInvestigationPriority(overallRisk, indicators)

        return FraudDetectionResult(
            fraudIndicators: indicators,
            overallRisk: overallRisk,
            confidence: confidence,
            recommendedActions: actions,
            investigationPriority: priority
        )
    }

    // MARK: - User Feedback Integration

    public func updateWithUserFeedback(
        anomalyId: String,
        isFalsePositive: Bool
    ) async throws {

        if isFalsePositive {
            falsePositivePatterns[anomalyId, default: 0] += 1
        }

        // In a real implementation, this would update machine learning models
        // For now, we just track false positive patterns for improved detection
        try await persistFalsePositiveData()
    }

    // MARK: - Private Helper Methods

    private func detectBasicPayAnomaly(
        _ payslip: Payslip,
        _ historicalPayslips: [Payslip]
    ) -> AmountAnomaly? {

        let historicalBasicPays = historicalPayslips.map { $0.basicPay }
        guard let stats = calculateStatisticalSummary(historicalBasicPays) else { return nil }

        let currentPay = payslip.basicPay
        let deviation = abs(currentPay - stats.mean) / stats.mean
        let zScore = (currentPay - stats.mean) / stats.standardDeviation

        guard deviation > 0.1 || abs(zScore) > 2.0 else { return nil } // 10% threshold or 2 SD

        let riskLevel = determineAmountRiskLevel(deviation, zScore)
        let explanation = generateBasicPayExplanation(currentPay, stats, deviation, zScore)

        return AmountAnomaly(
            component: .basicPay,
            expectedValue: stats.mean,
            actualValue: currentPay,
            deviation: deviation,
            confidence: min(1.0, max(0.1, 1.0 - abs(deviation) / 0.5)), // Simple confidence calculation
            riskLevel: riskLevel,
            explanation: explanation,
            anomalyId: "basic_pay_\(payslip.id.uuidString)"
        )
    }

    private func detectAllowanceAnomaly(
        _ allowance: Allowance,
        _ payslip: Payslip,
        _ historicalPayslips: [Payslip]
    ) -> AmountAnomaly? {

        let historicalAllowances = historicalPayslips.compactMap { histPayslip in
            histPayslip.allowances.first { $0.name == allowance.name }
        }.map { $0.amount }

        guard !historicalAllowances.isEmpty,
              let stats = calculateStatisticalSummary(historicalAllowances) else { return nil }

        let currentAmount = allowance.amount
        let deviation = abs(currentAmount - stats.mean) / max(stats.mean, 1.0) // Avoid division by zero
        let zScore = (currentAmount - stats.mean) / max(stats.standardDeviation, 1.0)

        guard deviation > 0.15 || abs(zScore) > 2.5 else { return nil } // Slightly higher threshold for allowances

        let riskLevel = determineAmountRiskLevel(deviation, zScore)
        let explanation = generateAllowanceExplanation(allowance.name, currentAmount, stats, deviation)

        return AmountAnomaly(
            component: .allowance(name: allowance.name),
            expectedValue: stats.mean,
            actualValue: currentAmount,
            deviation: deviation,
            confidence: min(1.0, max(0.1, 1.0 - abs(deviation) / 0.5)), // Simple confidence calculation
            riskLevel: riskLevel,
            explanation: explanation,
            anomalyId: "allowance_\(allowance.name)_\(payslip.id.uuidString)"
        )
    }

    private func detectDeductionAnomaly(
        _ deduction: Deduction,
        _ payslip: Payslip,
        _ historicalPayslips: [Payslip]
    ) -> AmountAnomaly? {

        let historicalDeductions = historicalPayslips.compactMap { histPayslip in
            histPayslip.deductions.first { $0.name == deduction.name }
        }.map { $0.amount }

        guard !historicalDeductions.isEmpty,
              let stats = calculateStatisticalSummary(historicalDeductions) else { return nil }

        let currentAmount = deduction.amount
        let deviation = abs(currentAmount - stats.mean) / max(stats.mean, 1.0)
        let zScore = (currentAmount - stats.mean) / max(stats.standardDeviation, 1.0)

        guard deviation > 0.12 || abs(zScore) > 2.2 else { return nil }

        let riskLevel = determineAmountRiskLevel(deviation, zScore)
        let explanation = generateDeductionExplanation(deduction.name, currentAmount, stats, deviation)

        return AmountAnomaly(
            component: .deduction(name: deduction.name),
            expectedValue: stats.mean,
            actualValue: currentAmount,
            deviation: deviation,
            confidence: min(1.0, max(0.1, 1.0 - abs(deviation) / 0.5)), // Simple confidence calculation
            riskLevel: riskLevel,
            explanation: explanation,
            anomalyId: "deduction_\(deduction.name)_\(payslip.id.uuidString)"
        )
    }

    private func detectNetPayAnomaly(
        _ payslip: Payslip,
        _ historicalPayslips: [Payslip]
    ) -> AmountAnomaly? {

        let historicalNetPays = historicalPayslips.map { $0.netPay }
        guard let stats = calculateStatisticalSummary(historicalNetPays) else { return nil }

        let currentNetPay = payslip.netPay
        let deviation = abs(currentNetPay - stats.mean) / stats.mean
        let zScore = (currentNetPay - stats.mean) / stats.standardDeviation

        // Net pay should be more consistent, so lower threshold
        guard deviation > 0.08 || abs(zScore) > 1.8 else { return nil }

        let riskLevel = determineAmountRiskLevel(deviation, zScore)
        let explanation = generateNetPayExplanation(currentNetPay, stats, deviation)

        return AmountAnomaly(
            component: .netPay,
            expectedValue: stats.mean,
            actualValue: currentNetPay,
            deviation: deviation,
            confidence: min(1.0, max(0.1, 1.0 - abs(deviation) / 0.5)), // Simple confidence calculation
            riskLevel: riskLevel,
            explanation: explanation,
            anomalyId: "net_pay_\(payslip.id.uuidString)"
        )
    }

    private func calculateStatisticalSummary(_ values: [Double]) -> StatisticalSummary? {
        guard !values.isEmpty else { return nil }

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)

        return StatisticalSummary(
            mean: mean,
            standardDeviation: standardDeviation,
            min: values.min() ?? 0,
            max: values.max() ?? 0,
            count: values.count
        )
    }

    private func determineAmountRiskLevel(_ deviation: Double, _ zScore: Double) -> AnomalyRiskLevel {
        let absZScore = abs(zScore)

        if deviation > 0.5 || absZScore > 3.5 {
            return .critical
        } else if deviation > 0.3 || absZScore > 2.8 {
            return .high
        } else if deviation > 0.15 || absZScore > 2.0 {
            return .medium
        } else {
            return .low
        }
    }

    private func calculateOverallRisk(_ anomalies: [AmountAnomaly]) -> AnomalyRiskLevel {
        guard !anomalies.isEmpty else { return .low }

        let riskScores = anomalies.map { anomaly -> Double in
            switch anomaly.riskLevel {
            case .low: return 1.0
            case .medium: return 2.0
            case .high: return 3.0
            case .critical: return 4.0
            }
        }

        let averageRisk = riskScores.reduce(0, +) / Double(riskScores.count)

        if averageRisk >= 3.5 { return .critical }
        else if averageRisk >= 2.5 { return .high }
        else if averageRisk >= 1.5 { return .medium }
        else { return .low }
    }

    private func calculateDetectionConfidence(_ historicalPayslips: [Payslip]) -> Double {
        let dataPoints = historicalPayslips.count
        let timeSpan = calculateTimeSpan(historicalPayslips)

        // Confidence increases with more data and longer time spans
        let dataConfidence = min(1.0, Double(dataPoints) / 12.0) // Max at 12 months
        let timeConfidence = min(1.0, timeSpan / (365.0 * 24.0 * 3600.0)) // Max at 1 year

        return (dataConfidence + timeConfidence) / 2.0
    }

    private func calculateTimeSpan(_ payslips: [Payslip]) -> TimeInterval {
        guard let first = payslips.first?.timestamp,
              let last = payslips.last?.timestamp else { return 0 }

        return last.timeIntervalSince(first)
    }

    private func generateAmountRecommendations(
        _ anomalies: [AmountAnomaly],
        _ overallRisk: AnomalyRiskLevel
    ) -> [String] {

        var recommendations: [String] = []

        if overallRisk == .critical {
            recommendations.append("URGENT: Multiple critical anomalies detected - verify payslip authenticity with issuing authority")
        }

        if anomalies.contains(where: { $0.riskLevel == .high }) {
            recommendations.append("Review high-risk anomalies with HR/finance department")
        }

        let componentTypes = Set(anomalies.map { $0.component })
        if componentTypes.count > 2 {
            recommendations.append("Multiple component anomalies suggest systematic issue - comprehensive review recommended")
        }

        if anomalies.isEmpty {
            recommendations.append("No anomalies detected - payslip appears consistent with historical patterns")
        }

        return recommendations
    }

    private func detectMissingComponents(
        _ payslip: Payslip,
        _ expectedFormat: LiteRTDocumentFormatType
    ) -> [FormatAnomaly] {

        var anomalies: [FormatAnomaly] = []

        // Check for critical components based on format
        switch expectedFormat {
        case .military:
            if payslip.rank.isEmpty {
                anomalies.append(FormatAnomaly(
                    anomalyType: .missingComponent,
                    severity: .significant,
                    location: "Header",
                    description: "Military rank is missing",
                    suggestedCorrection: "Verify rank information in payslip header"
                ))
            }

            if payslip.serviceNumber.isEmpty {
                anomalies.append(FormatAnomaly(
                    anomalyType: .missingComponent,
                    severity: .significant,
                    location: "Header",
                    description: "Service number is missing",
                    suggestedCorrection: "Verify service number in payslip header"
                ))
            }

        case .pcda:
            // PCDA format checks would go here
            break

        case .corporate:
            // Corporate format checks would go here
            break

        case .bank, .psu:
            // Bank/PSU specific checks
            break
            
        case .unknown:
            // Unknown format - minimal checks
            break
        }

        return anomalies
    }

    private func detectFormatInconsistencies(
        _ payslip: Payslip,
        _ expectedFormat: LiteRTDocumentFormatType
    ) -> [FormatAnomaly] {

        var anomalies: [FormatAnomaly] = []

        // Check amount formats and consistency
        let totalCredits = payslip.basicPay + payslip.allowances.reduce(0) { $0 + $1.amount }
        let totalDebits = payslip.deductions.reduce(0) { $0 + $1.amount }
        let calculatedNetPay = totalCredits - totalDebits

        if abs(calculatedNetPay - payslip.netPay) > 1.0 { // Allow for rounding differences
            anomalies.append(FormatAnomaly(
                anomalyType: .inconsistentStructure,
                severity: .moderate,
                location: "Calculations",
                description: "Net pay calculation inconsistency detected",
                suggestedCorrection: "Verify addition of credits and subtraction of debits"
            ))
        }

        return anomalies
    }

    private func detectDataValidityIssues(_ payslip: Payslip) -> [FormatAnomaly] {
        var anomalies: [FormatAnomaly] = []

        // Check for negative amounts
        if payslip.basicPay < 0 {
            anomalies.append(FormatAnomaly(
                anomalyType: .invalidData,
                severity: .critical,
                location: "Basic Pay",
                description: "Negative basic pay amount",
                suggestedCorrection: "Verify basic pay calculation"
            ))
        }

        for allowance in payslip.allowances where allowance.amount < 0 {
            anomalies.append(FormatAnomaly(
                anomalyType: .invalidData,
                severity: .significant,
                location: "Allowances",
                description: "Negative allowance amount: \(allowance.name)",
                suggestedCorrection: "Verify allowance calculation"
            ))
        }

        // Check for unusually high amounts
        let totalCredits = payslip.basicPay + payslip.allowances.reduce(0) { $0 + $1.amount }
        if totalCredits > 1_000_000 { // 10 lakhs threshold
            anomalies.append(FormatAnomaly(
                anomalyType: .invalidData,
                severity: .moderate,
                location: "Total Credits",
                description: "Unusually high total credits detected",
                suggestedCorrection: "Verify total credit calculation and amounts"
            ))
        }

        return anomalies
    }

    private func detectStructuralIssues(_ payslip: Payslip) -> [FormatAnomaly] {
        var anomalies: [FormatAnomaly] = []

        // Check for empty or whitespace-only strings
        if payslip.rank.trimmingCharacters(in: .whitespaces).isEmpty {
            anomalies.append(FormatAnomaly(
                anomalyType: .incorrectFormat,
                severity: .moderate,
                location: "Rank",
                description: "Rank field is empty or contains only whitespace",
                suggestedCorrection: "Verify rank information is properly extracted"
            ))
        }

        return anomalies
    }

    private func calculateFormatConsistency(
        _ payslip: Payslip,
        _ expectedFormat: LiteRTDocumentFormatType,
        _ anomalies: [FormatAnomaly]
    ) -> Double {

        let totalPossibleIssues = 10 // Estimated maximum possible format issues
        let actualIssues = anomalies.count

        return max(0, (Double(totalPossibleIssues - actualIssues) / Double(totalPossibleIssues)))
    }

    private func generateFormatRecommendations(_ anomalies: [FormatAnomaly]) -> [String] {
        var recommendations: [String] = []

        let criticalCount = anomalies.filter { $0.severity == .critical }.count
        let severeCount = anomalies.filter { $0.severity == .significant }.count

        if criticalCount > 0 {
            recommendations.append("CRITICAL: Address \(criticalCount) critical format issues before processing")
        }

        if severeCount > 0 {
            recommendations.append("Review \(severeCount) severe format anomalies")
        }

        if anomalies.isEmpty {
            recommendations.append("Format validation passed - payslip structure appears correct")
        }

        return recommendations
    }

    private func detectStatisticalAnomalies(
        _ payslip: Payslip,
        _ historicalPayslips: [Payslip]
    ) -> [FraudIndicator] {

        var indicators: [FraudIndicator] = []

        // Check for statistical outliers in basic pay
        if let basicPayStats = calculateStatisticalSummary(historicalPayslips.map { $0.basicPay }) {
            let zScore = abs(payslip.basicPay - basicPayStats.mean) / basicPayStats.standardDeviation

            if zScore > 3.0 {
                indicators.append(FraudIndicator(
                    indicatorType: .statisticalOutlier,
                    severity: .high,
                    evidence: "Basic pay Z-score: \(String(format: "%.2f", zScore))",
                    confidence: min(0.95, zScore / 5.0),
                    riskScore: zScore / 4.0
                ))
            }
        }

        return indicators
    }

    private func detectPatternInconsistencies(
        _ payslip: Payslip,
        _ historicalPayslips: [Payslip]
    ) -> [FraudIndicator] {

        var indicators: [FraudIndicator] = []

        // Check for unusual allowance patterns
        let historicalAllowanceNames = Set(historicalPayslips.flatMap { $0.allowances.map { $0.name } })
        let currentAllowanceNames = Set(payslip.allowances.map { $0.name })

        let newAllowances = currentAllowanceNames.subtracting(historicalAllowanceNames)
        if !newAllowances.isEmpty {
            indicators.append(FraudIndicator(
                indicatorType: .patternInconsistency,
                severity: .medium,
                evidence: "New allowances detected: \(newAllowances.joined(separator: ", "))",
                confidence: 0.7,
                riskScore: Double(newAllowances.count) * 0.3
            ))
        }

        return indicators
    }

    private func detectTimingAnomalies(
        _ payslip: Payslip,
        _ historicalPayslips: [Payslip]
    ) -> [FraudIndicator] {

        var indicators: [FraudIndicator] = []

        // Check for payslips dated in the future
        if payslip.timestamp > Date() {
            indicators.append(FraudIndicator(
                indicatorType: .timingAnomaly,
                severity: .critical,
                evidence: "Payslip dated in the future",
                confidence: 0.95,
                riskScore: 0.9
            ))
        }

        // Check for unusual timing patterns
        let sortedPayslips = historicalPayslips.sorted { $0.timestamp < $1.timestamp }
        if let lastHistorical = sortedPayslips.last {
            let daysBetween = calendar.dateComponents([.day], from: lastHistorical.timestamp, to: payslip.timestamp).day ?? 0

            if daysBetween < 25 { // Less than typical month
                indicators.append(FraudIndicator(
                    indicatorType: .timingAnomaly,
                    severity: .medium,
                    evidence: "Unusually frequent payslip generation (\(daysBetween) days)",
                    confidence: 0.6,
                    riskScore: 0.4
                ))
            }
        }

        return indicators
    }

    private func detectAmountManipulation(
        _ payslip: Payslip,
        _ historicalPayslips: [Payslip]
    ) -> [FraudIndicator] {

        var indicators: [FraudIndicator] = []

        // Check for rounded amounts that might indicate manipulation
        let amounts = [payslip.basicPay] + payslip.allowances.map { $0.amount } + payslip.deductions.map { $0.amount }

        let roundedAmounts = amounts.filter { amount in
            let decimalPart = amount - floor(amount)
            return decimalPart == 0 || decimalPart == 0.5 // Perfect rounding
        }

        if Double(roundedAmounts.count) / Double(amounts.count) > 0.8 { // 80% rounded
            indicators.append(FraudIndicator(
                indicatorType: .amountManipulation,
                severity: .medium,
                evidence: "\(roundedAmounts.count) out of \(amounts.count) amounts are perfectly rounded",
                confidence: 0.65,
                riskScore: 0.5
            ))
        }

        return indicators
    }

    private func detectDuplicateEntries(
        _ payslip: Payslip,
        _ historicalPayslips: [Payslip]
    ) -> [FraudIndicator] {

        var indicators: [FraudIndicator] = []

        // Check for exact duplicate amounts across allowances
        let allowanceAmounts = payslip.allowances.map { $0.amount }
        let uniqueAmounts = Set(allowanceAmounts)

        if Double(uniqueAmounts.count) / Double(allowanceAmounts.count) < 0.7 { // Less than 70% unique
            indicators.append(FraudIndicator(
                indicatorType: .duplicateEntry,
                severity: .low,
                evidence: "Potential duplicate allowance amounts detected",
                confidence: 0.5,
                riskScore: 0.2
            ))
        }

        return indicators
    }

    private func calculateFraudRisk(_ indicators: [FraudIndicator]) -> FraudRiskLevel {
        guard !indicators.isEmpty else { return .none }

        let totalRiskScore = indicators.reduce(0) { $0 + $1.riskScore }
        let averageRiskScore = totalRiskScore / Double(indicators.count)

        let criticalCount = indicators.filter { $0.severity == .critical }.count
        let highCount = indicators.filter { $0.severity == .high }.count

        if criticalCount > 0 || averageRiskScore > 0.7 {
            return .critical
        } else if highCount > 0 || averageRiskScore > 0.5 {
            return .high
        } else if averageRiskScore > 0.3 {
            return .medium
        } else if averageRiskScore > 0.1 {
            return .low
        } else {
            return .none
        }
    }

    private func calculateFraudConfidence(
        _ indicators: [FraudIndicator],
        _ historicalPayslips: [Payslip]
    ) -> Double {

        let dataPoints = historicalPayslips.count
        let indicatorCount = indicators.count

        // Confidence increases with more data and more indicators
        let dataConfidence = min(1.0, Double(dataPoints) / 12.0)
        let indicatorConfidence = min(1.0, Double(indicatorCount) / 5.0) // Max at 5 indicators

        return (dataConfidence + indicatorConfidence) / 2.0
    }

    private func generateFraudActions(
        _ indicators: [FraudIndicator],
        _ overallRisk: FraudRiskLevel
    ) -> [String] {

        var actions: [String] = []

        switch overallRisk {
        case .critical:
            actions.append("IMMEDIATE ACTION REQUIRED: Contact issuing authority to verify payslip authenticity")
            actions.append("Do not process any payments based on this payslip")
        case .high:
            actions.append("HIGH PRIORITY: Verify payslip with multiple sources before processing")
            actions.append("Request additional documentation from issuing authority")
        case .medium:
            actions.append("REVIEW REQUIRED: Cross-reference amounts with previous payslips")
            actions.append("Verify calculation accuracy manually")
        case .low:
            actions.append("MONITOR: Minor irregularities detected - maintain standard verification procedures")
        case .none:
            actions.append("VERIFICATION COMPLETE: No fraud indicators detected")
        }

        return actions
    }

    private func determineInvestigationPriority(
        _ risk: FraudRiskLevel,
        _ indicators: [FraudIndicator]
    ) -> InvestigationPriority {

        if risk == .critical || indicators.contains(where: { $0.severity == .critical }) {
            return .immediate
        } else if risk == .high || indicators.contains(where: { $0.severity == .high }) {
            return .urgent
        } else if risk == .medium {
            return .priority
        } else {
            return .routine
        }
    }

    private func persistFalsePositiveData() async throws {
        // In a real implementation, this would save to persistent storage
        // For now, we just maintain in-memory tracking
    }

    // MARK: - Explanation Generation Methods

    private func generateBasicPayExplanation(
        _ currentPay: Double,
        _ stats: StatisticalSummary,
        _ deviation: Double,
        _ zScore: Double
    ) -> String {

        let deviationPercent = deviation * 100
        let direction = currentPay > stats.mean ? "higher" : "lower"

        return "Basic pay is \(String(format: "%.1f", deviationPercent))% \(direction) than historical average. Expected range: ₹\(String(format: "%.0f", stats.mean - stats.standardDeviation)) - ₹\(String(format: "%.0f", stats.mean + stats.standardDeviation))"
    }

    private func generateAllowanceExplanation(
        _ name: String,
        _ currentAmount: Double,
        _ stats: StatisticalSummary,
        _ deviation: Double
    ) -> String {

        let deviationPercent = deviation * 100
        let direction = currentAmount > stats.mean ? "higher" : "lower"

        return "\(name) allowance is \(String(format: "%.1f", deviationPercent))% \(direction) than historical average of ₹\(String(format: "%.0f", stats.mean))"
    }

    private func generateDeductionExplanation(
        _ name: String,
        _ currentAmount: Double,
        _ stats: StatisticalSummary,
        _ deviation: Double
    ) -> String {

        let deviationPercent = deviation * 100
        let direction = currentAmount > stats.mean ? "higher" : "lower"

        return "\(name) deduction is \(String(format: "%.1f", deviationPercent))% \(direction) than historical average of ₹\(String(format: "%.0f", stats.mean))"
    }

    private func generateNetPayExplanation(
        _ currentNetPay: Double,
        _ stats: StatisticalSummary,
        _ deviation: Double
    ) -> String {

        let deviationPercent = deviation * 100
        let direction = currentNetPay > stats.mean ? "higher" : "lower"

        return "Net pay is \(String(format: "%.1f", deviationPercent))% \(direction) than historical average. This could indicate changes in allowances, deductions, or basic pay structure."
    }
}

/// Statistical summary for anomaly detection
private struct StatisticalSummary {
    let mean: Double
    let standardDeviation: Double
    let min: Double
    let max: Double
    let count: Int
}

/// Errors that can occur during anomaly detection
public enum AnomalyDetectionError: Error {
    case insufficientHistoricalData
    case invalidPayslipData
    case calculationError
}
