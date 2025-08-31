import Foundation
import PDFKit

/// Protocol for AI-powered format detection service
protocol SmartFormatDetectorProtocol {
    /// Detects payslip format using AI analysis
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Detected format with confidence score
    func detectFormat(from document: PDFDocument) async -> (PayslipFormat, Double)

    /// Analyzes document structure and content for format hints
    /// - Parameter text: Extracted text from the document
    /// - Returns: Format detection result with confidence
    func analyzeDocumentStructure(text: String) -> FormatDetectionResult

    /// Extracts semantic features for format classification
    /// - Parameter text: The text to analyze
    /// - Returns: Array of semantic features
    func extractSemanticFeatures(from text: String) -> [SemanticFeature]
}

/// Result of format detection analysis
struct FormatDetectionResult {
    let format: PayslipFormat
    let confidence: Double
    let features: [SemanticFeature]
    let reasoning: String
}

/// Semantic features extracted for format detection
struct SemanticFeature {
    let type: FeatureType
    let value: String
    let confidence: Double
    let position: Int // Character position in text

    enum FeatureType {
        case header
        case institution
        case financialTerm
        case personalInfo
        case militaryTerm
        case corporateTerm
        case layoutIndicator
    }
}

/// AI-powered format detector that replaces basic pattern matching
class SmartFormatDetector: SmartFormatDetectorProtocol {

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

    func detectFormat(from document: PDFDocument) async -> (PayslipFormat, Double) {
        // Extract text from document
        let extractedText = await textExtractionService.extractText(from: document)

        // Use AI-powered analysis
        let result = await analyzeWithAI(text: extractedText)

        return (result.format, result.confidence)
    }

    func analyzeDocumentStructure(text: String) -> FormatDetectionResult {
        let features = extractSemanticFeatures(from: text)
        let result = classifyFormat(from: features, text: text)

        return FormatDetectionResult(
            format: result.format,
            confidence: result.confidence,
            features: features,
            reasoning: result.reasoning
        )
    }

    func extractSemanticFeatures(from text: String) -> [SemanticFeature] {
        var features: [SemanticFeature] = []

        // Extract header features (first 500 characters)
        let headerText = String(text.prefix(500))
        features.append(contentsOf: extractHeaderFeatures(from: headerText))

        // Extract institutional identifiers
        features.append(contentsOf: extractInstitutionalFeatures(from: text))

        // Extract financial terminology
        features.append(contentsOf: extractFinancialFeatures(from: text))

        // Extract military-specific terms
        features.append(contentsOf: extractMilitaryFeatures(from: text))

        // Extract corporate-specific terms
        features.append(contentsOf: extractCorporateFeatures(from: text))

        // Extract layout and structural indicators
        features.append(contentsOf: extractLayoutFeatures(from: text))

        return features.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Private Methods

    private func analyzeWithAI(text: String) async -> (format: PayslipFormat, confidence: Double) {
        // Use LiteRT service for AI-powered classification
        do {
            // Use the service through the protocol - compiler will resolve the correct implementation
            let classification = try await liteRTService.classifyDocument(text: text)
            return classification
        } catch {
            print("[SmartFormatDetector] LiteRT classification failed: \(error)")
            // Fallback to rule-based classification
            let result = analyzeDocumentStructure(text: text)
            return (result.format, result.confidence)
        }
    }

    private func classifyFormat(from features: [SemanticFeature], text: String) -> (format: PayslipFormat, confidence: Double, reasoning: String) {
        var scores: [PayslipFormat: Double] = [
            .military: 0.0,
            .pcda: 0.0,
            .corporate: 0.0,
            .psu: 0.0,
            .standard: 0.0,
            .unknown: 0.0
        ]

        var reasoningComponents: [String] = []

        // Score based on semantic features
        for feature in features {
            switch feature.type {
            case .militaryTerm:
                scores[.military] = (scores[.military] ?? 0) + feature.confidence
                scores[.pcda] = (scores[.pcda] ?? 0) + (feature.confidence * 0.7)
                reasoningComponents.append("Military term: \(feature.value)")

            case .institution where feature.value.contains("PCDA"):
                scores[.pcda] = (scores[.pcda] ?? 0) + feature.confidence
                scores[.military] = (scores[.military] ?? 0) + (feature.confidence * 0.8)
                reasoningComponents.append("PCDA institution detected")

            case .corporateTerm:
                scores[.corporate] = (scores[.corporate] ?? 0) + feature.confidence
                reasoningComponents.append("Corporate term: \(feature.value)")

            case .financialTerm:
                scores[.standard] = (scores[.standard] ?? 0) + (feature.confidence * 0.5)
                reasoningComponents.append("Financial term: \(feature.value)")

            case .layoutIndicator where feature.value.contains("table"):
                scores[.pcda] = (scores[.pcda] ?? 0) + (feature.confidence * 0.6)
                reasoningComponents.append("Tabular layout detected")

            default:
                scores[.standard] = (scores[.standard] ?? 0) + (feature.confidence * 0.3)
            }
        }

        // Apply contextual rules
        if text.contains("DEFENCE") && text.contains("ACCOUNT") {
            scores[.pcda] = (scores[.pcda] ?? 0) + 2.0
            reasoningComponents.append("Defence account context")
        }

        if text.contains("SALARY") && text.contains("EMPLOYEE") {
            scores[.corporate] = (scores[.corporate] ?? 0) + 1.5
            reasoningComponents.append("Employee salary context")
        }

        // Find the format with highest score
        let bestFormat = scores.max { $0.value < $1.value }?.key ?? .unknown
        let confidence = min(scores[bestFormat] ?? 0.0, 1.0)

        let reasoning = reasoningComponents.prefix(3).joined(separator: ", ")

        return (bestFormat, confidence, reasoning)
    }

    private func extractHeaderFeatures(from text: String) -> [SemanticFeature] {
        var features: [SemanticFeature] = []

        // Look for institution names in header
        let institutions = [
            "PCDA", "DEFENCE", "ARMY", "NAVY", "AIR FORCE",
            "CORPORATE", "COMPANY", "BANK", "FINANCIAL"
        ]

        for institution in institutions {
            if let range = text.range(of: institution, options: .caseInsensitive) {
                let position = text.distance(from: text.startIndex, to: range.lowerBound)
                features.append(SemanticFeature(
                    type: .institution,
                    value: institution,
                    confidence: 0.9,
                    position: position
                ))
            }
        }

        return features
    }

    private func extractInstitutionalFeatures(from text: String) -> [SemanticFeature] {
        var features: [SemanticFeature] = []

        // PCDA specific patterns
        let pcdaPatterns = [
            "PRINCIPAL CONTROLLER", "DEFENCE ACCOUNTS", "STATEMENT OF ACCOUNT",
            "PAYMENT ORDER", "CREDIT NOTE", "DEBIT NOTE"
        ]

        for pattern in pcdaPatterns {
            if let range = text.range(of: pattern, options: .caseInsensitive) {
                let position = text.distance(from: text.startIndex, to: range.lowerBound)
                features.append(SemanticFeature(
                    type: .institution,
                    value: pattern,
                    confidence: 0.95,
                    position: position
                ))
            }
        }

        return features
    }

    private func extractFinancialFeatures(from text: String) -> [SemanticFeature] {
        var features: [SemanticFeature] = []

        let financialTerms = [
            "SALARY", "PAYSLIP", "EARNINGS", "DEDUCTIONS", "NET PAY",
            "GROSS PAY", "BASIC PAY", "ALLOWANCE", "DEDUCTION",
            "TAX", "PF", "ESI", "GRATUITY"
        ]

        for term in financialTerms {
            var searchRange = text.startIndex..<text.endIndex
            while let range = text.range(of: term, options: .caseInsensitive, range: searchRange) {
                let position = text.distance(from: text.startIndex, to: range.lowerBound)
                features.append(SemanticFeature(
                    type: .financialTerm,
                    value: term,
                    confidence: 0.7,
                    position: position
                ))
                searchRange = range.upperBound..<text.endIndex
            }
        }

        return features
    }

    private func extractMilitaryFeatures(from text: String) -> [SemanticFeature] {
        var features: [SemanticFeature] = []

        let militaryTerms = [
            "SERVICE NO", "ARMY NO", "NAVY NO", "AIR FORCE NO",
            "MILITARY", "DEFENCE", "DSOP", "AGIF", "MSP",
            "MINISTRY OF DEFENCE", "COMMAND", "UNIT", "RANK"
        ]

        for term in militaryTerms {
            var searchRange = text.startIndex..<text.endIndex
            while let range = text.range(of: term, options: .caseInsensitive, range: searchRange) {
                let position = text.distance(from: text.startIndex, to: range.lowerBound)
                features.append(SemanticFeature(
                    type: .militaryTerm,
                    value: term,
                    confidence: 0.85,
                    position: position
                ))
                searchRange = range.upperBound..<text.endIndex
            }
        }

        return features
    }

    private func extractCorporateFeatures(from text: String) -> [SemanticFeature] {
        var features: [SemanticFeature] = []

        let corporateTerms = [
            "EMPLOYEE", "EMPLOYER", "COMPANY", "DEPARTMENT",
            "DESIGNATION", "SALARY SLIP", "PAY SLIP", "CTC",
            "ANNUAL PACKAGE", "MONTHLY SALARY"
        ]

        for term in corporateTerms {
            var searchRange = text.startIndex..<text.endIndex
            while let range = text.range(of: term, options: .caseInsensitive, range: searchRange) {
                let position = text.distance(from: text.startIndex, to: range.lowerBound)
                features.append(SemanticFeature(
                    type: .corporateTerm,
                    value: term,
                    confidence: 0.8,
                    position: position
                ))
                searchRange = range.upperBound..<text.endIndex
            }
        }

        return features
    }

    private func extractLayoutFeatures(from text: String) -> [SemanticFeature] {
        var features: [SemanticFeature] = []

        // Detect tabular structures
        let tableIndicators = ["DESCRIPTION", "AMOUNT", "RATE", "TOTAL"]
        var tableScore = 0

        for indicator in tableIndicators {
            if text.contains(indicator) {
                tableScore += 1
            }
        }

        if tableScore >= 2 {
            features.append(SemanticFeature(
                type: .layoutIndicator,
                value: "table",
                confidence: Double(tableScore) / Double(tableIndicators.count),
                position: 0
            ))
        }

        // Detect column-like structures
        let lines = text.split(separator: "\n")
        var alignedLines = 0

        for line in lines {
            // Simple heuristic: lines with multiple numbers or aligned content
            let numberCount = line.split(separator: " ").filter { $0.contains(where: { $0.isNumber }) }.count
            if numberCount >= 2 && line.count > 20 {
                alignedLines += 1
            }
        }

        if alignedLines >= 3 {
            features.append(SemanticFeature(
                type: .layoutIndicator,
                value: "columns",
                confidence: Double(alignedLines) / Double(lines.count),
                position: 0
            ))
        }

        return features
    }
}

// MARK: - LiteRT Service Integration

// SmartFormatDetector now uses the protocol method directly from LiteRTServiceProtocol
