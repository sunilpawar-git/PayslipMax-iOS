//
//  LLMPayslipParserFactory.swift
//  PayslipMax
//
//  Factory for creating LLM parsers based on configuration
//

import Foundation
import OSLog

/// Factory for creating LLM parsers
final class LLMPayslipParserFactory {

    private static let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "Factory")

    /// Creates an LLM parser for the given configuration
    /// - Parameters:
    ///   - config: The LLM configuration
    ///   - usageTracker: Optional usage tracker for monitoring (optional)
    /// - Returns: An instantiated LLMPayslipParser, or nil if creation fails
    static func createParser(for config: LLMConfiguration, usageTracker: LLMUsageTrackerProtocol? = nil) -> LLMPayslipParser? {

        // 1. Create the LLM Service
        let service: LLMServiceProtocol

        switch config.provider {
        case .openai:
            service = OpenAILLMService(configuration: config)
        case .gemini:
            service = GeminiLLMService(configuration: config)
        case .mock:
            // If we have a mock service in the main target, use it.
            // Otherwise, log error and return nil.
            // Since MockLLMService is in tests, we'll return nil for now or handle if needed.
            logger.error("Mock provider not supported in production factory")
            return nil
        case .anthropic:
            logger.error("Anthropic provider not implemented yet")
            return nil
        }

        // 2. Create the Anonymizer (LEGACY - for backward compatibility)
        let anonymizer: PayslipAnonymizer
        do {
            anonymizer = try PayslipAnonymizer()
        } catch {
            logger.error("Failed to create anonymizer: \(error.localizedDescription)")
            return nil
        }

        // 3. Create and return the parser with usage tracker
        return LLMPayslipParser(service: service, anonymizer: anonymizer, usageTracker: usageTracker)
    }

    /// Creates an LLM parser with selective redaction (recommended)
    /// - Parameters:
    ///   - config: The LLM configuration
    ///   - usageTracker: Optional usage tracker for monitoring
    /// - Returns: An instantiated LLMPayslipParser with selective redaction, or nil if creation fails
    static func createParserWithSelectiveRedaction(for config: LLMConfiguration, usageTracker: LLMUsageTrackerProtocol? = nil) -> LLMPayslipParser? {

        // 1. Create the LLM Service
        let service: LLMServiceProtocol

        switch config.provider {
        case .openai:
            service = OpenAILLMService(configuration: config)
        case .gemini:
            service = GeminiLLMService(configuration: config)
        case .mock:
            logger.error("Mock provider not supported in production factory")
            return nil
        case .anthropic:
            logger.error("Anthropic provider not implemented yet")
            return nil
        }

        // 2. Create the Selective Redactor
        let selectiveRedactor: SelectiveRedactor
        do {
            selectiveRedactor = try SelectiveRedactor()
        } catch {
            logger.error("Failed to create selective redactor: \(error.localizedDescription)")
            return nil
        }

        // 3. Create and return the parser with selective redaction
        logger.info("Creating LLM parser with selective redaction (Phase 4-Lite)")
        return LLMPayslipParser(service: service, selectiveRedactor: selectiveRedactor, usageTracker: usageTracker)
    }
}
