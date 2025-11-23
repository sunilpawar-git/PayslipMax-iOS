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
    private let logger = os.Logger(subsystem: "com.payslipmax.processing", category: "Hybrid")

    // MARK: - Initialization

    /// Initializes the hybrid processor
    /// - Parameters:
    ///   - regexProcessor: The primary regex-based processor
    ///   - settings: Settings service for LLM configuration
    ///   - rateLimiter: Rate limiter for LLM calls (optional)
    ///   - llmFactory: Closure to create an LLM parser given a configuration (allows DI/Mocking)
    init(regexProcessor: PayslipProcessorProtocol,
         settings: LLMSettingsServiceProtocol,
         rateLimiter: LLMRateLimiterProtocol? = nil,
         llmFactory: @escaping (LLMConfiguration) -> LLMPayslipParser?) {
        self.regexProcessor = regexProcessor
        self.settings = settings
        self.rateLimiter = rateLimiter
        self.llmFactory = llmFactory
    }

    // MARK: - PayslipProcessorProtocol

    func canProcess(text: String) -> Double {
        return regexProcessor.canProcess(text: text)
    }

    func processPayslip(from text: String) async throws -> PayslipItem {
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

        // 3. Check Quality
        let isQualityHigh = isHighQuality(regexResult)
        logger.info("Regex result quality: \(isQualityHigh ? "High" : "Low")")

        if settings.useAsBackupOnly && isQualityHigh {
            logger.info("Quality high and backup mode enabled. Skipping LLM.")
            return regexResult
        }

        // 4. Run LLM (Fallback or Enhancement)
        if let llmResult = try await attemptLLM(text: text, reason: isQualityHigh ? "Enhancement" : "Low Quality Regex") {
            return llmResult
        }

        // 5. Fallback to regex if LLM failed or not configured
        return regexResult
    }

    // MARK: - Constants

    /// Maximum allowed difference between calculated and reported totals for quality validation
    private let qualityCheckTolerance: Double = 5.0

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

    /// Validates the quality of a parsing result
    /// - Parameter item: The parsed item
    /// - Returns: True if the result is considered high quality
    private func isHighQuality(_ item: PayslipItem) -> Bool {
        // Criteria 1: Mandatory fields present
        // BPAY and DSOP are critical for military payslips
        let hasBPAY = item.earnings["BPAY"] != nil || item.earnings["Basic Pay"] != nil
        let hasDSOP = item.deductions["DSOP"] != nil || item.deductions["AFPP Fund"] != nil

        guard hasBPAY && hasDSOP else {
            logger.debug("Quality Check Failed: Missing BPAY or DSOP")
            return false
        }

        // Criteria 2: Totals match within tolerance
        // Allow small tolerance for rounding
        let earningsSum = item.earnings.values.reduce(0, +)
        let deductionsSum = item.deductions.values.reduce(0, +)

        // Let's assume credits = Gross, debits = Total Deductions.
        // Net = Gross - Total Deductions.
        // But PayslipItem doesn't have explicit "Net Pay" field, it uses credits/debits for transaction matching.
        // Let's check if earnings sum matches credits (Gross)

        let grossDiff = abs(earningsSum - item.credits)
        let deductionDiff = abs(deductionsSum - item.debits)

        if grossDiff > qualityCheckTolerance || deductionDiff > qualityCheckTolerance {
            logger.debug("Quality Check Failed: Totals mismatch (Gross Diff: \(grossDiff), Ded Diff: \(deductionDiff))")
            return false
        }

        return true
    }
}
