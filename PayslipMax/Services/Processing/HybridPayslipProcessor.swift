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
    private let onDeviceService: OnDeviceLLMServiceProtocol?
    private let offlineModeService: OfflineModeServiceProtocol?
    let diagnosticsService: ParsingDiagnosticsServiceProtocol
    private let heuristics: HybridParsingHeuristics
    let logger = os.Logger(subsystem: "com.payslipmax.processing", category: "Hybrid")

    private enum ConfidenceThreshold {
        static let excellent: Double = 0.9
        static let good: Double = 0.7

        static let offlineExcellent: Double = 0.6
        static let offlineGood: Double = 0.4
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
         onDeviceService: OnDeviceLLMServiceProtocol? = nil,
         offlineModeService: OfflineModeServiceProtocol? = nil,
         diagnosticsService: ParsingDiagnosticsServiceProtocol? = nil) {
        self.regexProcessor = regexProcessor
        self.settings = settings
        self.rateLimiter = rateLimiter
        self.llmFactory = llmFactory
        self.onDeviceService = onDeviceService
        self.offlineModeService = offlineModeService
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
        diagnosticsService.resetSession()

        let isOffline = offlineModeService?.isOfflineModeEnabled ?? false

        // 1. Run Regex Processor (Fast, Free, Private)
        logger.info("Starting hybrid processing. Step 1: Regex (offline=\(isOffline))")
        let regexResult: PayslipItem
        do {
            regexResult = try await regexProcessor.processPayslip(from: text)
        } catch {
            logger.warning("Regex processing failed: \(error.localizedDescription)")
            if isOffline {
                if let onDevice = await attemptOnDeviceLLM(text: text, onDeviceService: onDeviceService, reason: "Regex failed") {
                    return onDevice
                }
                throw error
            }
            if let llmResult = try await attemptLLM(text: text, reason: "Regex failed") {
                return llmResult
            }
            throw error
        }

        // 2. Determine LLM availability
        let cloudLLMAvailable = !isOffline && (settings.isLLMEnabled || BuildConfiguration.useBackendProxy)

        // 2.1 Guarded fallback: key components/totals missing
        if let guardReason = heuristics.guardedFallbackReason(for: regexResult) {
            heuristics.recordMandatoryDiagnosticsIfNeeded(for: regexResult)

            if let onDevice = await attemptOnDeviceLLM(text: text, onDeviceService: onDeviceService, reason: guardReason) {
                return onDevice
            }

            if !isOffline {
                logger.info("Guarded cloud LLM fallback: \(guardReason)")
                if let llmResult = try await attemptLLM(text: text, reason: guardReason) {
                    return llmResult
                }
            }

            logger.info("Guarded fallback exhausted; returning regex result")
            return regexResult
        }

        // 3. Calculate graduated confidence score
        let confidence = heuristics.calculateParsingConfidence(regexResult)
        let confidencePercent = String(format: "%.1f", confidence * 100)
        logger.info("Regex parsing confidence: \(confidencePercent)%")

        // 4. Apply confidence thresholds -- relaxed when offline
        let excellentThreshold = isOffline ? ConfidenceThreshold.offlineExcellent : ConfidenceThreshold.excellent
        let goodThreshold = isOffline ? ConfidenceThreshold.offlineGood : ConfidenceThreshold.good

        if confidence >= excellentThreshold {
            logger.info("Confidence \(confidencePercent)% >= \(excellentThreshold). Skipping LLM.")
            return regexResult
        }

        if confidence >= goodThreshold && settings.useAsBackupOnly {
            logger.info("Confidence \(confidencePercent)% >= \(goodThreshold) (backup mode). Skipping LLM.")
            return regexResult
        }

        // 5. Determine fallback reason
        let reason = confidence < goodThreshold
            ? "Low confidence (\(confidencePercent)%)"
            : "Enhancement mode (\(confidencePercent)%)"

        // 5.5 Try on-device LLM first
        if let onDeviceResult = await attemptOnDeviceLLM(text: text, onDeviceService: onDeviceService, reason: reason) {
            logger.info("On-device LLM succeeded, skipping cloud LLM")
            return onDeviceResult
        }

        // 6. Attempt cloud LLM (blocked when offline)
        if cloudLLMAvailable, let llmResult = try await attemptLLM(text: text, reason: reason) {
            return llmResult
        }

        // 7. Fallback to regex
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
