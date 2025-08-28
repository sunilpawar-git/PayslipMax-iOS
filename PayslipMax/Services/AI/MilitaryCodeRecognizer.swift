import Foundation
import Vision
import CoreML

/// AI-powered military code recognition service
public class MilitaryCodeRecognizer: MilitaryCodeRecognizerProtocol {

    // MARK: - Properties

    private let liteRTService: LiteRTServiceProtocol
    private let recognitionEngine: MilitaryCodeRecognitionEngine
    private let validationEngine: MilitaryCodeValidationEngine
    private let standardizationEngine: MilitaryCodeStandardizationEngine

    // MARK: - Initialization

    public init(liteRTService: LiteRTServiceProtocol? = nil) {
        if let service = liteRTService {
            self.liteRTService = service
        } else {
            self.liteRTService = LiteRTService()
        }
        self.recognitionEngine = MilitaryCodeRecognitionEngine()
        self.validationEngine = MilitaryCodeValidationEngine()
        self.standardizationEngine = MilitaryCodeStandardizationEngine()
    }

    // MARK: - Public Methods

    /// Recognize military codes in text elements
    public func recognizeCodes(in textElements: [LiteRTTextElement]) async throws -> MilitaryCodeRecognitionResult {
        return try await recognitionEngine.recognizeCodes(in: textElements)
    }

    /// Expand military code abbreviation
    public func expandAbbreviation(_ code: String) async throws -> MilitaryCodeExpansion? {
        return try await recognitionEngine.expandAbbreviation(code)
    }

    /// Validate military code in context
    public func validateCode(_ code: String, context: MilitaryCodeContext) async throws -> MilitaryCodeValidation {
        return try await validationEngine.validateCode(code, context: context)
    }

    /// Standardize military codes
    public func standardizeCodes(_ codes: [String]) async throws -> [MilitaryCodeStandardization] {
        return try await standardizationEngine.standardizeCodes(codes)
    }
}
