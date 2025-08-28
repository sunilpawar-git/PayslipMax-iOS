import Foundation
import PDFKit

/// Protocol for AI-powered parser selection
protocol AIPayslipParserSelectorProtocol {
    /// Selects the optimal parser using AI analysis
    /// - Parameter document: The PDF document to analyze
    /// - Returns: The best parser with confidence score and reasoning
    func selectOptimalParser(for document: PDFDocument) async -> ParserSelectionResult

    /// Selects parser based on extracted text analysis
    /// - Parameter text: The extracted text from the document
    /// - Returns: The best parser with confidence and analysis
    func selectParser(for text: String) -> ParserSelectionResult

    /// Evaluates all available parsers for a given text
    /// - Parameter text: The text to evaluate parsers against
    /// - Returns: Array of parser evaluations with scores
    func evaluateParsers(for text: String) -> [ParserEvaluation]

    /// Learns from user corrections to improve future selections
    /// - Parameters:
    ///   - text: The document text
    ///   - selectedParser: The parser chosen by the user
    ///   - success: Whether the parsing was successful
    func learn(from text: String, selectedParser: PayslipParser, success: Bool)
}

/// Result of parser selection analysis
struct ParserSelectionResult {
    let parser: PayslipParser?
    let confidence: Double
    let reasoning: String
    let alternativeParsers: [PayslipParser]
    let analysis: AIParserSelectionDocumentAnalysis
}

/// Evaluation result for a specific parser
struct ParserEvaluation {
    let parser: PayslipParser
    let score: Double
    let strengths: [String]
    let weaknesses: [String]
    let estimatedAccuracy: Double
}

/// Analysis of document characteristics for AI parser selection
struct AIParserSelectionDocumentAnalysis {
    let format: PayslipFormat
    let complexity: DocumentComplexity
    let quality: DocumentQuality
    let features: [String]

    enum DocumentComplexity {
        case simple
        case moderate
        case complex
    }

    enum DocumentQuality {
        case poor
        case fair
        case good
        case excellent
    }
}

/// AI-powered parser selector that replaces basic pattern matching
class AIPayslipParserSelector: AIPayslipParserSelectorProtocol {

    // MARK: - Dependencies

    private let smartFormatDetector: SmartFormatDetectorProtocol
    private let liteRTService: LiteRTService
    private let parserRegistry: PayslipParserRegistry
    private let textExtractionService: TextExtractionServiceProtocol

    // MARK: - Learning Data

    private var learningDatabase: [String: ParserLearningData] = [:]

    // MARK: - Initialization

    init(smartFormatDetector: SmartFormatDetectorProtocol,
         liteRTService: LiteRTService,
         parserRegistry: PayslipParserRegistry,
         textExtractionService: TextExtractionServiceProtocol) {
        self.smartFormatDetector = smartFormatDetector
        self.liteRTService = liteRTService
        self.parserRegistry = parserRegistry
        self.textExtractionService = textExtractionService
    }

    // MARK: - Public Methods

    func selectOptimalParser(for document: PDFDocument) async -> ParserSelectionResult {
        let extractedText = await textExtractionService.extractText(from: document)
        return selectOptimalParser(for: extractedText)
    }

    func selectParser(for text: String) -> ParserSelectionResult {
        return selectOptimalParser(for: text)
    }

    func evaluateParsers(for text: String) -> [ParserEvaluation] {
        let analysis = analyzeDocument(text: text)
        var evaluations: [ParserEvaluation] = []

        for parser in parserRegistry.parsers {
            let evaluation = evaluateParser(parser, for: text, analysis: analysis)
            evaluations.append(evaluation)
        }

        return evaluations.sorted { $0.score > $1.score }
    }

    func learn(from text: String, selectedParser: PayslipParser, success: Bool) {
        let key = generateLearningKey(for: text)

        var learningData = learningDatabase[key] ?? ParserLearningData(
            parserName: selectedParser.name,
            successCount: 0,
            failureCount: 0,
            averageConfidence: 0.0
        )

        if success {
            learningData.successCount += 1
        } else {
            learningData.failureCount += 1
        }

        learningDatabase[key] = learningData

        print("[AIPayslipParserSelector] Learned from user selection: \(selectedParser.name), success: \(success)")
    }

    // MARK: - Private Methods

    private func selectOptimalParser(for text: String) -> ParserSelectionResult {
        // Analyze the document
        let analysis = analyzeDocument(text: text)

        // Get parser evaluations
        let evaluations = evaluateParsers(for: text)

        // Select the best parser
        guard let bestEvaluation = evaluations.first else {
            return ParserSelectionResult(
                parser: nil,
                confidence: 0.0,
                reasoning: "No parsers available",
                alternativeParsers: [],
                analysis: analysis
            )
        }

        // Get alternative parsers (top 3)
        let alternativeParsers = evaluations.prefix(3).map { $0.parser }

        // Generate reasoning
        let reasoning = generateReasoning(for: bestEvaluation, analysis: analysis)

        return ParserSelectionResult(
            parser: bestEvaluation.parser,
            confidence: bestEvaluation.score,
            reasoning: reasoning,
            alternativeParsers: Array(alternativeParsers),
            analysis: analysis
        )
    }

    private func analyzeDocument(text: String) -> AIParserSelectionDocumentAnalysis {
        // Use smart format detector to get format
        let formatResult = smartFormatDetector.analyzeDocumentStructure(text: text)
        let format = formatResult.format

        // Assess complexity
        let complexity = assessComplexity(text: text)

        // Assess quality
        let quality = assessQuality(text: text)

        // Extract key features
        let features = extractDocumentFeatures(text: text)

        return AIParserSelectionDocumentAnalysis(
            format: format,
            complexity: complexity,
            quality: quality,
            features: features
        )
    }

    private func assessComplexity(text: String) -> AIParserSelectionDocumentAnalysis.DocumentComplexity {
        let wordCount = text.split(separator: " ").count
        let numberCount = text.filter { $0.isNumber }.count

        // Simple heuristic for complexity
        if wordCount < 200 || numberCount < 10 {
            return .simple
        } else if wordCount < 500 || numberCount < 30 {
            return .moderate
        } else {
            return .complex
        }
    }

    private func assessQuality(text: String) -> AIParserSelectionDocumentAnalysis.DocumentQuality {
        var score = 0

        // Check for clear structure
        if text.contains("TOTAL") && text.contains("AMOUNT") {
            score += 2
        }

        // Check for readable content
        let uppercaseRatio = Double(text.filter { $0.isUppercase }.count) / Double(text.count)
        if uppercaseRatio < 0.8 { // Not mostly uppercase (likely OCR noise)
            score += 1
        }

        // Check for reasonable length
        if text.count > 100 && text.count < 10000 {
            score += 1
        }

        // Check for numbers (financial documents should have numbers)
        let numberCount = text.filter { $0.isNumber }.count
        if numberCount > 5 {
            score += 1
        }

        switch score {
        case 0...2: return .poor
        case 3: return .fair
        case 4: return .good
        default: return .excellent
        }
    }

    private func extractDocumentFeatures(text: String) -> [String] {
        var features: [String] = []

        // Check for table-like structure
        if text.contains("DESCRIPTION") && text.contains("AMOUNT") {
            features.append("tabular_structure")
        }

        // Check for military indicators
        if text.contains("SERVICE NO") || text.contains("MINISTRY OF DEFENCE") {
            features.append("military_format")
        }

        // Check for corporate indicators
        if text.contains("EMPLOYEE") && text.contains("DEPARTMENT") {
            features.append("corporate_format")
        }

        // Check for financial terms
        let financialTerms = ["SALARY", "DEDUCTION", "ALLOWANCE", "TAX"]
        let financialCount = financialTerms.filter { text.contains($0) }.count
        if financialCount >= 2 {
            features.append("financial_document")
        }

        return features
    }

    private func evaluateParser(_ parser: PayslipParser, for text: String, analysis: AIParserSelectionDocumentAnalysis) -> ParserEvaluation {
        var score = 0.0
        var strengths: [String] = []
        var weaknesses: [String] = []

        // Base score from parser type matching
        switch (parser, analysis.format) {
        case (is MilitaryPayslipParser, .military), (is MilitaryPayslipParser, .pcda):
            score += 0.8
            strengths.append("Specialized for military/PCDA formats")

        case (is CorporatePayslipParser, .corporate):
            score += 0.8
            strengths.append("Specialized for corporate formats")

        case (_, .standard):
            score += 0.6
            strengths.append("General-purpose parser")

        default:
            score += 0.4
            weaknesses.append("Not format-specific")
        }

        // Adjust score based on document complexity
        switch analysis.complexity {
        case .simple:
            if parser is MilitaryPayslipParser {
                score += 0.1
                strengths.append("Handles simple military documents well")
            }
        case .moderate:
            score += 0.1
            strengths.append("Suitable for moderate complexity")
        case .complex:
            if parser is MilitaryPayslipParser {
                score += 0.2
                strengths.append("Excellent for complex military documents")
            }
        }

        // Adjust score based on document quality
        switch analysis.quality {
        case .poor:
            score -= 0.2
            weaknesses.append("May struggle with poor quality documents")
        case .fair:
            score -= 0.1
        case .good, .excellent:
            score += 0.1
            strengths.append("Performs well with clear documents")
        }

        // Check learning database for this parser
        let key = generateLearningKey(for: text)
        if let learningData = learningDatabase[key],
           learningData.parserName == parser.name {

            let successRate = Double(learningData.successCount) /
                            Double(learningData.successCount + learningData.failureCount)

            score = score * 0.7 + successRate * 0.3 // Blend with learning data
            strengths.append("Previously successful for similar documents")
        }

        // Calculate estimated accuracy
        let estimatedAccuracy = min(score, 1.0)

        return ParserEvaluation(
            parser: parser,
            score: score,
            strengths: strengths,
            weaknesses: weaknesses,
            estimatedAccuracy: estimatedAccuracy
        )
    }

    private func generateReasoning(for evaluation: ParserEvaluation, analysis: AIParserSelectionDocumentAnalysis) -> String {
        var reasoningParts: [String] = []

        reasoningParts.append("Selected \(evaluation.parser.name)")

        if !evaluation.strengths.isEmpty {
            reasoningParts.append("Strengths: \(evaluation.strengths.joined(separator: ", "))")
        }

        reasoningParts.append("Document format: \(analysis.format.rawValue)")
        reasoningParts.append("Complexity: \(analysis.complexity)")
        reasoningParts.append("Quality: \(analysis.quality)")

        if !analysis.features.isEmpty {
            reasoningParts.append("Features: \(analysis.features.joined(separator: ", "))")
        }

        return reasoningParts.joined(separator: ". ")
    }

    private func generateLearningKey(for text: String) -> String {
        // Create a simplified key based on document characteristics
        let words = text.split(separator: " ").prefix(10).joined(separator: " ")
        let hasMilitaryTerms = text.contains("MILITARY") || text.contains("DEFENCE")
        let hasCorporateTerms = text.contains("EMPLOYEE") || text.contains("COMPANY")

        var key = words
        if hasMilitaryTerms { key += "_military" }
        if hasCorporateTerms { key += "_corporate" }

        return key.lowercased()
    }
}

// MARK: - Learning Data Structure

private struct ParserLearningData {
    let parserName: String
    var successCount: Int
    var failureCount: Int
    var averageConfidence: Double
}

// MARK: - Extension to PayslipFormat for rawValue

extension PayslipFormat {
    var rawValue: String {
        switch self {
        case .military: return "military"
        case .pcda: return "pcda"
        case .corporate: return "corporate"
        case .psu: return "psu"
        case .standard: return "standard"
        case .unknown: return "unknown"
        }
    }
}
