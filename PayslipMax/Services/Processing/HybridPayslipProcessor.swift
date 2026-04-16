//
//  HybridPayslipProcessor.swift
//  PayslipMax
//
//  Combines Regex and LLM parsing for optimal accuracy and privacy
//

import Foundation
import OSLog

/// Processor that intelligently switches between Regex and LLM parsing
final class HybridPayslipProcessor: PayslipProcessorProtocol {

    // MARK: - Properties

    var handlesFormat: PayslipFormat = .defense

    private let regexProcessor: PayslipProcessorProtocol
    private let settings: LLMSettingsServiceProtocol
    private let rateLimiter: LLMRateLimiterProtocol?
    private let llmFactory: (LLMConfiguration) -> LLMPayslipParser?
    let diagnosticsService: ParsingDiagnosticsServiceProtocol
    private let heuristics: HybridParsingHeuristics
    let logger = os.Logger(subsystem: "com.payslipmax.processing", category: "Hybrid")

    private enum ConfidenceThreshold {
        static let excellent: Double = 0.9
        static let good: Double = 0.7
        static let low: Double = 0.7
    }

    // MARK: - Initialization

    /// Initializes the hybrid processor
    /// - Parameters:
    ///   - regexProcessor: The primary regex-based processor
    ///   - settings: Settings service for LLM configuration
    ///   - rateLimiter: Rate limiter for LLM calls (optional)
    ///   - llmFactory: Closure to create an LLM parser given a configuration (allows DI/Mocking)
    ///   - diagnosticsService: Service for tracking parsing diagnostics (defaults to shared instance)
    init(regexProcessor: PayslipProcessorProtocol,
         settings: LLMSettingsServiceProtocol,
         rateLimiter: LLMRateLimiterProtocol? = nil,
         llmFactory: @escaping (LLMConfiguration) -> LLMPayslipParser?,
         diagnosticsService: ParsingDiagnosticsServiceProtocol? = nil) {
        self.regexProcessor = regexProcessor
        self.settings = settings
        self.rateLimiter = rateLimiter
        self.llmFactory = llmFactory
        let resolvedDiagnostics = diagnosticsService ?? ParsingDiagnosticsService.shared
        self.diagnosticsService = resolvedDiagnostics
        self.heuristics = HybridParsingHeuristics(
            logger: logger,
            diagnosticsService: resolvedDiagnostics
        )
    }

    // MARK: - PayslipProcessorProtocol

    func canProcess(text: String) -> Double {
        return regexProcessor.canProcess(text: text)
    }

    func processPayslip(from text: String) async throws -> PayslipItem {
        // Reset diagnostics for this parsing session
        diagnosticsService.resetSession()

        // 1. Run Regex Processor (Fast, Free, Private)
        logger.info("Starting hybrid processing. Step 1: Regex")
        let regexResult: PayslipItem
        do {
            regexResult = try await regexProcessor.processPayslip(from: text)
        } catch {
            logger.warning("Regex processing failed: \(error.localizedDescription)")
            // If regex fails completely, we might still try LLM if enabled
            if let llmResult = try await attemptLLM(text: text, reason: "Regex failed") {
                return llmResult
            }
            throw error
        }

        // 2. Determine LLM availability (settings or backend proxy)
        let llmAvailable = settings.isLLMEnabled || BuildConfiguration.useBackendProxy

        // 2.1 Guarded fallback: trigger LLM when anchors exist but key components/totals are missing
        if let guardReason = heuristics.guardedFallbackReason(for: regexResult) {
            heuristics.recordMandatoryDiagnosticsIfNeeded(for: regexResult)
            // Force-enable guard for derived net or totals mismatch regardless of availability flags (test mode)
            let forceGuard = true

            if llmAvailable || forceGuard {
                logger.info("Guarded LLM fallback triggered: \(guardReason) (llmAvailable=\(llmAvailable), forceGuard=\(forceGuard))")
                if let llmResult = try await attemptLLM(text: text, reason: guardReason) {
                    return llmResult
                } else {
                    logger.info("Guarded LLM fallback unavailable/failed; returning regex result")
                    return regexResult
                }
            } else {
                logger.info("LLM unavailable (disabled) for guarded fallback: \(guardReason). Returning regex result.")
                return regexResult
            }
        }

        // 2.2 If LLM not available at all, return regex result
        guard llmAvailable else {
            logger.info("LLM disabled/unavailable, returning regex result")
            return regexResult
        }

        // 3. Calculate graduated confidence score
        let confidence = heuristics.calculateParsingConfidence(regexResult)
        let confidencePercent = String(format: "%.1f", confidence * 100)
        logger.info("Regex parsing confidence: \(confidencePercent)%")

        // 4. Apply graduated LLM fallback strategy
        if confidence >= ConfidenceThreshold.excellent {
            // Excellent quality - skip LLM entirely
            logger.info("Excellent confidence (\(confidencePercent)%). Skipping LLM.")
            return regexResult
        }

        if confidence >= ConfidenceThreshold.good && settings.useAsBackupOnly {
            // Good quality and backup mode - skip LLM
            logger.info("Good confidence (\(confidencePercent)%) with backup mode. Skipping LLM.")
            return regexResult
        }

        // 5. Determine LLM fallback reason based on confidence
        let reason: String
        if confidence < ConfidenceThreshold.low {
            reason = "Low confidence (\(confidencePercent)%)"
        } else {
            reason = "Enhancement mode (\(confidencePercent)%)"
        }

        // 6. Attempt LLM processing
        if let llmResult = try await attemptLLM(text: text, reason: reason) {
            return llmResult
        }

        // 7. Fallback to regex if LLM failed or not configured
        logger.info("LLM unavailable, returning regex result")
        return regexResult
    }

    private func attemptLLM(text: String, reason: String) async throws -> PayslipItem? {
        // Check rate limits first
        if let limiter = rateLimiter {
            let canMakeRequest = await limiter.canMakeRequest()
            if !canMakeRequest {
                if let timeUntil = await limiter.timeUntilNextRequest() {
                    logger.info("Rate limited: Next request allowed in \(timeUntil)s. Falling back to regex.")
                } else {
                    logger.info("Rate limited: Yearly limit reached. Falling back to regex.")
                }
                return nil
            }
        }

        guard let config = settings.getConfiguration() else {
            logger.info("LLM configuration missing or invalid. Skipping LLM.")
            return nil
        }

        guard let parser = llmFactory(config) else {
            logger.error("Failed to create LLM parser factory")
            return nil
        }

        logger.info("Attempting LLM processing. Reason: \(reason)")

        do {
            let result = try await parser.parse(text)

            // Record successful request with rate limiter
            if let limiter = rateLimiter {
                await limiter.recordRequest()
            }

            logger.info("LLM processing successful")
            return result
        } catch {
            logger.error("LLM processing failed: \(error.localizedDescription)")

            // Still record the request attempt (failed or not)
            if let limiter = rateLimiter {
                await limiter.recordRequest()
            }

            // We catch the error and return nil to allow fallback to regex result
            return nil
        }
    }

}
