import Foundation
import PDFKit

/// Protocol for document semantic analysis
protocol DocumentSemanticAnalyzerProtocol {
    /// Performs comprehensive semantic analysis of a document
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Complete semantic analysis result
    func analyzeDocument(_ document: PDFDocument) async -> SemanticAnalysisResult

    /// Analyzes text for semantic understanding
    /// - Parameter text: The extracted text to analyze
    /// - Returns: Semantic analysis result
    func analyzeText(_ text: String) -> SemanticAnalysisResult

    /// Identifies relationships between financial fields
    /// - Parameter text: The text containing financial data
    /// - Returns: Array of identified field relationships
    func identifyFieldRelationships(in text: String) -> [FieldRelationship]

    /// Assesses document quality and completeness
    /// - Parameter text: The text to assess
    /// - Returns: Quality assessment with issues and recommendations
    func assessDocumentQuality(_ text: String) -> DocumentQualityAssessment
}

/// Complete result of semantic document analysis
struct SemanticAnalysisResult {
    let documentType: PayslipFormat
    let confidence: Double
    let fieldRelationships: [FieldRelationship]
    let qualityAssessment: DocumentQualityAssessment
    let semanticFeatures: [SemanticFeature]
    let recommendations: [String]
}

/// Relationship between financial fields in a document
struct FieldRelationship {
    let sourceField: FinancialField
    let targetField: FinancialField
    let relationshipType: RelationshipType
    let confidence: Double
    let description: String

    enum RelationshipType {
        case dependency
        case calculation
        case validation
        case correlation
        case inconsistency
    }
}

/// Financial field types found in payslips
enum FinancialField: Hashable {
    case basicPay
    case allowances(total: Double)
    case deductions(total: Double)
    case grossPay
    case netPay
    case taxAmount
    case providentFund
    case professionalTax
    case otherEarnings
    case otherDeductions
    case custom(name: String, value: Double)

    var name: String {
        switch self {
        case .basicPay: return "Basic Pay"
        case .allowances: return "Allowances"
        case .deductions: return "Deductions"
        case .grossPay: return "Gross Pay"
        case .netPay: return "Net Pay"
        case .taxAmount: return "Tax Amount"
        case .providentFund: return "Provident Fund"
        case .professionalTax: return "Professional Tax"
        case .otherEarnings: return "Other Earnings"
        case .otherDeductions: return "Other Deductions"
        case .custom(let name, _): return name
        }
    }

    var expectedValue: Double? {
        switch self {
        case .allowances(let total): return total
        case .deductions(let total): return total
        case .custom(_, let value): return value
        default: return nil
        }
    }
}

/// Assessment of document quality and completeness
struct DocumentQualityAssessment {
    let overallScore: Double // 0.0 to 1.0
    let issues: [QualityIssue]
    let recommendations: [String]
    let completeness: CompletenessScore

    struct QualityIssue {
        let severity: Severity
        let type: IssueType
        let description: String
        let field: String?

        enum Severity {
            case low
            case medium
            case high
            case critical
        }

        enum IssueType {
            case missingField
            case inconsistentData
            case formattingError
            case calculationError
            case lowConfidence
        }
    }

    enum CompletenessScore {
        case incomplete
        case partial
        case mostlyComplete
        case complete
    }
}

/// AI-powered document semantic analyzer
class DocumentSemanticAnalyzer: DocumentSemanticAnalyzerProtocol {

    // MARK: - Dependencies

    private let liteRTService: LiteRTService
    private let textExtractionService: TextExtractionServiceProtocol

    // MARK: - Initialization

    init(liteRTService: LiteRTService,
         textExtractionService: TextExtractionServiceProtocol) {
        self.liteRTService = liteRTService
        self.textExtractionService = textExtractionService
    }

    // MARK: - Public Methods

    func analyzeDocument(_ document: PDFDocument) async -> SemanticAnalysisResult {
        let extractedText = await textExtractionService.extractText(from: document)
        return analyzeText(extractedText)
    }

    func analyzeText(_ text: String) -> SemanticAnalysisResult {
        // Perform comprehensive semantic analysis
        let fieldRelationships = identifyFieldRelationships(in: text)
        let qualityAssessment = assessDocumentQuality(text)
        let semanticFeatures = extractSemanticFeatures(from: text)

        // Determine document type based on analysis
        let documentType = determineDocumentType(from: fieldRelationships, features: semanticFeatures)
        let confidence = calculateOverallConfidence(fieldRelationships: fieldRelationships,
                                                  quality: qualityAssessment,
                                                  features: semanticFeatures)

        // Generate recommendations
        let recommendations = generateRecommendations(fieldRelationships: fieldRelationships,
                                                    quality: qualityAssessment)

        return SemanticAnalysisResult(
            documentType: documentType,
            confidence: confidence,
            fieldRelationships: fieldRelationships,
            qualityAssessment: qualityAssessment,
            semanticFeatures: semanticFeatures,
            recommendations: recommendations
        )
    }

    func identifyFieldRelationships(in text: String) -> [FieldRelationship] {
        var relationships: [FieldRelationship] = []

        // Extract financial values using pattern recognition
        let financialValues = extractFinancialValues(from: text)

        // Identify basic relationships
        relationships.append(contentsOf: identifyBasicRelationships(values: financialValues))
        relationships.append(contentsOf: identifyCalculationRelationships(values: financialValues))
        relationships.append(contentsOf: identifyValidationRelationships(values: financialValues))

        // Identify inconsistencies
        relationships.append(contentsOf: identifyInconsistencies(values: financialValues))

        return relationships.sorted { $0.confidence > $1.confidence }
    }

    func assessDocumentQuality(_ text: String) -> DocumentQualityAssessment {
        var issues: [DocumentQualityAssessment.QualityIssue] = []
        var recommendations: [String] = []

        // Check for required fields
        let requiredFields = ["BASIC PAY", "GROSS PAY", "NET PAY"]
        for field in requiredFields {
            if !text.contains(field) {
                issues.append(DocumentQualityAssessment.QualityIssue(
                    severity: .high,
                    type: .missingField,
                    description: "Missing required field: \(field)",
                    field: field
                ))
                recommendations.append("Add \(field) field for complete payslip analysis")
            }
        }

        // Check for calculation consistency
        let calculationIssues = checkCalculationConsistency(text)
        issues.append(contentsOf: calculationIssues.issues)
        recommendations.append(contentsOf: calculationIssues.recommendations)

        // Assess formatting quality
        let formattingAssessment = assessFormattingQuality(text)
        issues.append(contentsOf: formattingAssessment.issues)
        recommendations.append(contentsOf: formattingAssessment.recommendations)

        // Calculate completeness score
        let completeness = calculateCompletenessScore(text: text, issues: issues)

        // Calculate overall score
        let overallScore = calculateOverallQualityScore(issues: issues, completeness: completeness)

        return DocumentQualityAssessment(
            overallScore: overallScore,
            issues: issues,
            recommendations: recommendations,
            completeness: completeness
        )
    }

    // MARK: - Private Methods

    private func extractFinancialValues(from text: String) -> [FinancialField: Double] {
        var values: [FinancialField: Double] = [:]

        // Extract basic pay
        if let basicPayRange = text.range(of: "(?i)basic\\s+pay.*?(₹\\s*\\d+(?:,\\d{3})*(?:\\.\\d{2})?)", options: .regularExpression) {
            let basicPayText = String(text[basicPayRange])
            if let amount = extractAmount(from: basicPayText) {
                values[.basicPay] = amount
            }
        }

        // Extract allowances total
        if let allowancesRange = text.range(of: "(?i)(?:total\\s+)?allowances.*?(₹\\s*\\d+(?:,\\d{3})*(?:\\.\\d{2})?)", options: .regularExpression) {
            let allowancesText = String(text[allowancesRange])
            if let amount = extractAmount(from: allowancesText) {
                values[.allowances(total: amount)] = amount
            }
        }

        // Extract deductions total
        if let deductionsRange = text.range(of: "(?i)(?:total\\s+)?deductions.*?(₹\\s*\\d+(?:,\\d{3})*(?:\\.\\d{2})?)", options: .regularExpression) {
            let deductionsText = String(text[deductionsRange])
            if let amount = extractAmount(from: deductionsText) {
                values[.deductions(total: amount)] = amount
            }
        }

        // Extract gross pay
        if let grossPayRange = text.range(of: "(?i)gross\\s+pay.*?(₹\\s*\\d+(?:,\\d{3})*(?:\\.\\d{2})?)", options: .regularExpression) {
            let grossPayText = String(text[grossPayRange])
            if let amount = extractAmount(from: grossPayText) {
                values[.grossPay] = amount
            }
        }

        // Extract net pay
        if let netPayRange = text.range(of: "(?i)net\\s+pay.*?(₹\\s*\\d+(?:,\\d{3})*(?:\\.\\d{2})?)", options: .regularExpression) {
            let netPayText = String(text[netPayRange])
            if let amount = extractAmount(from: netPayText) {
                values[.netPay] = amount
            }
        }

        return values
    }

    private func extractAmount(from text: String) -> Double? {
        let pattern = "₹\\s*(\\d+(?:,\\d{3})*(?:\\.\\d{2})?)"
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))

            if let match = matches.first {
                let amountString = nsString.substring(with: match.range(at: 1))
                    .replacingOccurrences(of: ",", with: "")
                return Double(amountString)
            }
        } catch {
            print("[DocumentSemanticAnalyzer] Error parsing amount: \(error)")
        }
        return nil
    }

    private func identifyBasicRelationships(values: [FinancialField: Double]) -> [FieldRelationship] {
        var relationships: [FieldRelationship] = []

        // Gross Pay = Basic Pay + Allowances
        if let basicPay = values[.basicPay],
           let allowances = values.first(where: { if case .allowances = $0.key { return true } else { return false } })?.value,
           let grossPay = values[.grossPay] {

            let expectedGross = basicPay + allowances
            let difference = abs(expectedGross - grossPay)
            let confidence = difference < 1.0 ? 0.9 : (difference < 10.0 ? 0.7 : 0.5)

            relationships.append(FieldRelationship(
                sourceField: .basicPay,
                targetField: .grossPay,
                relationshipType: .calculation,
                confidence: confidence,
                description: "Gross Pay should equal Basic Pay + Allowances"
            ))
        }

        // Net Pay = Gross Pay - Deductions
        if let grossPay = values[.grossPay],
           let deductions = values.first(where: { if case .deductions = $0.key { return true } else { return false } })?.value,
           let netPay = values[.netPay] {

            let expectedNet = grossPay - deductions
            let difference = abs(expectedNet - netPay)
            let confidence = difference < 1.0 ? 0.9 : (difference < 10.0 ? 0.7 : 0.5)

            relationships.append(FieldRelationship(
                sourceField: .grossPay,
                targetField: .netPay,
                relationshipType: .calculation,
                confidence: confidence,
                description: "Net Pay should equal Gross Pay - Deductions"
            ))
        }

        return relationships
    }

    private func identifyCalculationRelationships(values: [FinancialField: Double]) -> [FieldRelationship] {
        var relationships: [FieldRelationship] = []

        // Identify tax calculations (typically 2-10% of gross pay)
        if let grossPay = values[.grossPay], let taxAmount = values[.taxAmount] {
            let taxRate = taxAmount / grossPay
            if taxRate > 0.02 && taxRate < 0.10 {
                relationships.append(FieldRelationship(
                    sourceField: .grossPay,
                    targetField: .taxAmount,
                    relationshipType: .calculation,
                    confidence: 0.8,
                    description: "Tax amount appears to be correctly calculated from Gross Pay"
                ))
            }
        }

        return relationships
    }

    private func identifyValidationRelationships(values: [FinancialField: Double]) -> [FieldRelationship] {
        var relationships: [FieldRelationship] = []

        // Validate that deductions don't exceed gross pay
        if let grossPay = values[.grossPay],
           let deductions = values.first(where: { if case .deductions = $0.key { return true } else { return false } })?.value {

            if deductions < grossPay * 0.8 { // Deductions should be less than 80% of gross
                relationships.append(FieldRelationship(
                    sourceField: .deductions(total: deductions),
                    targetField: .grossPay,
                    relationshipType: .validation,
                    confidence: 0.9,
                    description: "Deductions are within reasonable limits"
                ))
            }
        }

        return relationships
    }

    private func identifyInconsistencies(values: [FinancialField: Double]) -> [FieldRelationship] {
        var relationships: [FieldRelationship] = []

        // Check for negative values that shouldn't be negative
        for (field, value) in values {
            let allowedNegativeFields: [FinancialField] = [.deductions(total: 0)]
            let isAllowedNegative = allowedNegativeFields.contains(where: { allowedField in
                switch (field, allowedField) {
                case (.deductions, .deductions): return true
                default: return false
                }
            })

            if value < 0 && !isAllowedNegative {
                relationships.append(FieldRelationship(
                    sourceField: field,
                    targetField: field,
                    relationshipType: .inconsistency,
                    confidence: 0.95,
                    description: "\(field.name) should not be negative"
                ))
            }
        }

        // Check for unreasonably high values
        if let grossPay = values[.grossPay], grossPay > 100000 { // More than 10 lakhs
            relationships.append(FieldRelationship(
                sourceField: .grossPay,
                targetField: .grossPay,
                relationshipType: .inconsistency,
                confidence: 0.8,
                description: "Gross Pay amount seems unusually high"
            ))
        }

        return relationships
    }

    private func extractSemanticFeatures(from text: String) -> [SemanticFeature] {
        var features: [SemanticFeature] = []

        // Military-specific features
        if text.contains("SERVICE NO") || text.contains("ARMY NO") {
            features.append(SemanticFeature(
                type: .militaryTerm,
                value: "service_number",
                confidence: 0.95,
                position: text.range(of: "SERVICE NO")?.lowerBound.utf16Offset(in: text) ?? 0
            ))
        }

        // Financial calculation features
        if text.contains("TOTAL") && text.contains("AMOUNT") {
            features.append(SemanticFeature(
                type: .financialTerm,
                value: "calculation_section",
                confidence: 0.9,
                position: text.range(of: "TOTAL")?.lowerBound.utf16Offset(in: text) ?? 0
            ))
        }

        return features
    }

    private func determineDocumentType(from relationships: [FieldRelationship], features: [SemanticFeature]) -> PayslipFormat {
        // Count feature types
        let militaryFeatures = features.filter { $0.type == .militaryTerm }.count
        let corporateFeatures = features.filter { $0.type == .corporateTerm }.count

        if militaryFeatures > corporateFeatures {
            return .military
        } else if corporateFeatures > 0 {
            return .corporate
        } else if relationships.contains(where: { relationship in
            // Check for PCDA-specific calculation patterns
            relationship.description.contains("PCDA") || relationship.description.contains("Defence")
        }) {
            return .pcda
        } else {
            return .standard
        }
    }

    private func calculateOverallConfidence(fieldRelationships: [FieldRelationship],
                                          quality: DocumentQualityAssessment,
                                          features: [SemanticFeature]) -> Double {
        let relationshipConfidence = fieldRelationships.map { $0.confidence }.reduce(0, +) / max(1, Double(fieldRelationships.count))
        let qualityScore = quality.overallScore

        // Weighted average
        return (relationshipConfidence * 0.6) + (qualityScore * 0.4)
    }

    private func generateRecommendations(fieldRelationships: [FieldRelationship],
                                      quality: DocumentQualityAssessment) -> [String] {
        var recommendations = quality.recommendations

        // Add relationship-based recommendations
        let inconsistencies = fieldRelationships.filter { $0.relationshipType == .inconsistency }
        if !inconsistencies.isEmpty {
            recommendations.append("Review \(inconsistencies.count) data inconsistencies")
        }

        // Add calculation recommendations
        let calculations = fieldRelationships.filter { $0.relationshipType == .calculation && $0.confidence < 0.7 }
        if !calculations.isEmpty {
            recommendations.append("Verify calculation accuracy for \(calculations.count) fields")
        }

        return recommendations
    }

    private func checkCalculationConsistency(_ text: String) -> (issues: [DocumentQualityAssessment.QualityIssue], recommendations: [String]) {
        var issues: [DocumentQualityAssessment.QualityIssue] = []
        var recommendations: [String] = []

        // Extract all monetary values
        let currencyPattern = "₹\\s*\\d+(?:,\\d{3})*(?:\\.\\d{2})?"
        do {
            let regex = try NSRegularExpression(pattern: currencyPattern)
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))

            if matches.count < 3 {
                issues.append(DocumentQualityAssessment.QualityIssue(
                    severity: .medium,
                    type: .missingField,
                    description: "Document contains very few monetary values",
                    field: nil
                ))
                recommendations.append("Ensure all financial amounts are clearly visible")
            }
        } catch {
            print("[DocumentSemanticAnalyzer] Error checking calculation consistency: \(error)")
        }

        return (issues, recommendations)
    }

    private func assessFormattingQuality(_ text: String) -> (issues: [DocumentQualityAssessment.QualityIssue], recommendations: [String]) {
        var issues: [DocumentQualityAssessment.QualityIssue] = []
        var recommendations: [String] = []

        // Check for excessive uppercase (OCR noise indicator)
        let uppercaseRatio = Double(text.filter { $0.isUppercase }.count) / Double(text.count)
        if uppercaseRatio > 0.8 {
            issues.append(DocumentQualityAssessment.QualityIssue(
                severity: .medium,
                type: .formattingError,
                description: "Document appears to have OCR formatting issues",
                field: nil
            ))
            recommendations.append("Consider rescanning document for better OCR quality")
        }

        // Check for reasonable text length
        if text.count < 200 {
            issues.append(DocumentQualityAssessment.QualityIssue(
                severity: .high,
                type: .formattingError,
                description: "Document text is too short for a complete payslip",
                field: nil
            ))
            recommendations.append("Ensure full payslip content is captured")
        }

        return (issues, recommendations)
    }

    private func calculateCompletenessScore(text: String, issues: [DocumentQualityAssessment.QualityIssue]) -> DocumentQualityAssessment.CompletenessScore {
        let highSeverityIssues = issues.filter { $0.severity == .high || $0.severity == .critical }.count
        let mediumSeverityIssues = issues.filter { $0.severity == .medium }.count

        if highSeverityIssues > 0 {
            return .incomplete
        } else if mediumSeverityIssues > 2 {
            return .partial
        } else if mediumSeverityIssues > 0 {
            return .mostlyComplete
        } else {
            return .complete
        }
    }

    private func calculateOverallQualityScore(issues: [DocumentQualityAssessment.QualityIssue],
                                            completeness: DocumentQualityAssessment.CompletenessScore) -> Double {
        let baseScore = 1.0

        // Deduct points for issues
        var deduction = 0.0
        for issue in issues {
            switch issue.severity {
            case .low: deduction += 0.05
            case .medium: deduction += 0.15
            case .high: deduction += 0.25
            case .critical: deduction += 0.4
            }
        }

        // Adjust for completeness
        switch completeness {
        case .incomplete: deduction += 0.3
        case .partial: deduction += 0.15
        case .mostlyComplete: deduction += 0.05
        case .complete: deduction += 0.0
        }

        return max(0.0, min(1.0, baseScore - deduction))
    }
}
