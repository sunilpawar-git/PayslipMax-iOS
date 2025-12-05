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
    private let diagnosticsService: ParsingDiagnosticsServiceProtocol
    private let logger = os.Logger(subsystem: "com.payslipmax.processing", category: "Hybrid")

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
        self.diagnosticsService = diagnosticsService ?? ParsingDiagnosticsService.shared
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

        // 2. Check if LLM is enabled
        guard settings.isLLMEnabled else {
            logger.info("LLM disabled, returning regex result")
            return regexResult
        }

        // 3. Calculate graduated confidence score
        let confidence = calculateParsingConfidence(regexResult)
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

    // MARK: - Constants

    /// Percentage-based tolerance for totals matching (1% = 0.01)
    /// Changed from fixed 5.0 rupees to percentage-based for better accuracy across salary ranges
    private let qualityCheckTolerancePercent: Double = 0.01

    /// Absolute minimum tolerance in rupees for low-value edge cases
    /// Ensures we don't trigger LLM for trivial differences on low salaries
    private let qualityCheckMinimumTolerance: Double = 50.0

    // MARK: - Confidence Thresholds

    /// Confidence thresholds for LLM fallback decisions
    enum ConfidenceThreshold {
        /// Excellent parsing - skip LLM entirely
        static let excellent: Double = 0.9
        /// Good parsing - consider LLM only if readily available
        static let good: Double = 0.7
        /// Low confidence - always attempt LLM fallback
        static let low: Double = 0.7
    }

    // MARK: - Private Methods

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

    /// Calculates graduated confidence score for parsing result
    /// - Parameter item: The parsed payslip item
    /// - Returns: Confidence score from 0.0 (low) to 1.0 (excellent)
    private func calculateParsingConfidence(_ item: PayslipItem) -> Double {
        var confidence = 1.0

        // === Factor 1: Mandatory Components (up to -0.4) ===
        let hasBPAY = item.earnings["BPAY"] != nil || item.earnings["Basic Pay"] != nil
        let hasDSOP = item.deductions["DSOP"] != nil || item.deductions["AFPP Fund"] != nil

        if !hasBPAY {
            logger.debug("Confidence penalty: Missing BPAY (-0.2)")
            diagnosticsService.recordMandatoryComponentMissing("BPAY")
            confidence -= 0.2
        }

        if !hasDSOP {
            logger.debug("Confidence penalty: Missing DSOP (-0.2)")
            diagnosticsService.recordMandatoryComponentMissing("DSOP")
            confidence -= 0.2
        }

        // === Factor 2: Totals Match (up to -0.3) ===
        let earningsSum = item.earnings.values.reduce(0, +)
        let deductionsSum = item.deductions.values.reduce(0, +)

        let grossDiff = abs(earningsSum - item.credits)
        let deductionDiff = abs(deductionsSum - item.debits)

        // Calculate error percentages
        let grossErrorPercent = item.credits > 0 ? (grossDiff / item.credits) : 0
        let deductionErrorPercent = item.debits > 0 ? (deductionDiff / item.debits) : 0
        let maxErrorPercent = max(grossErrorPercent, deductionErrorPercent)

        // Apply graduated penalty based on error magnitude
        if maxErrorPercent > 0.05 {
            // >5% error: significant penalty
            confidence -= 0.3
            logger.debug("Confidence penalty: Totals >5% off (-0.3)")
        } else if maxErrorPercent > 0.01 {
            // 1-5% error: moderate penalty (scaled)
            let penalty = maxErrorPercent * 6  // 1% = -0.06, 5% = -0.30
            confidence -= penalty
            logger.debug("Confidence penalty: Totals \(String(format: "%.1f", maxErrorPercent * 100))% off (-\(String(format: "%.2f", penalty)))")

            // Record near-miss for diagnostics
            diagnosticsService.recordNearMissTotals(
                earningsExpected: item.credits,
                earningsActual: earningsSum,
                deductionsExpected: item.debits,
                deductionsActual: deductionsSum
            )
        }

        // === Factor 3: Component Count (up to -0.2) ===
        let totalComponents = item.earnings.count + item.deductions.count

        if totalComponents < 3 {
            // Very few components extracted
            confidence -= 0.2
            logger.debug("Confidence penalty: Only \(totalComponents) components (-0.2)")
        } else if totalComponents < 6 {
            // Few components
            confidence -= 0.1
            logger.debug("Confidence penalty: Only \(totalComponents) components (-0.1)")
        }

        // === Factor 4: Key Component Presence (up to -0.1) ===
        // Check for DA (Dearness Allowance) which is standard
        let hasDA = item.earnings["DA"] != nil || item.earnings["Dearness Allowance"] != nil
        if !hasDA && item.credits > 50000 {
            // Missing DA on high-value payslip is suspicious
            confidence -= 0.05
            logger.debug("Confidence penalty: Missing DA on high-value payslip (-0.05)")
        }

        // Check for any tax deduction on high earners
        let hasTax = item.deductions["ITAX"] != nil || item.deductions["Income Tax"] != nil || item.deductions["IT"] != nil
        if !hasTax && item.credits > 100000 {
            // High earner should have income tax
            confidence -= 0.05
            logger.debug("Confidence penalty: Missing ITAX on high-value payslip (-0.05)")
        }

        // Ensure confidence stays within bounds
        confidence = max(0.0, min(1.0, confidence))

        // Log final confidence
        logger.debug("Final parsing confidence: \(String(format: "%.2f", confidence))")

        return confidence
    }
}
