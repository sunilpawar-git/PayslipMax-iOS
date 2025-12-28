import Foundation
import OSLog
import UIKit

/// Vision-based payslip parser using an LLM that accepts images.
final class VisionLLMPayslipParser {
    private let service: LLMVisionServiceProtocol
    private let usageTracker: LLMUsageTrackerProtocol?
    private let validator = PayslipSanityCheckValidator()
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "VisionParser")
    private lazy var verificationService = VisionLLMVerificationService(service: service)

    /// Optional delegate for receiving real-time progress updates
    weak var progressDelegate: (any ParsingProgressDelegate)?

    init(service: LLMVisionServiceProtocol, usageTracker: LLMUsageTrackerProtocol? = nil) {
        self.service = service
        self.usageTracker = usageTracker
    }

    func parse(image: UIImage) async throws -> PayslipItem {
        let startTime = Date()

        // Check cache first
        if let cached = LLMResponseCache.shared.get(for: image) {
            logger.info("✨ Cache hit - returning cached result (confidence: \(String(format: "%.2f", cached.confidence)))")
            await reportCompletion(cached.payslipItem)
            return cached.payslipItem
        }

        ParsingAnalytics.log(.parsingStarted)
        await reportProgress(.preparing)

        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            await reportError(LLMError.invalidConfiguration)
            throw LLMError.invalidConfiguration
        }

        let request = LLMRequest(prompt: VisionLLMPromptTemplate.extractionPrompt, systemPrompt: nil, jsonMode: true)
        await reportProgress(.extracting)

        do {
            let result = try await processVisionRequest(
                jpegData: jpegData,
                request: request,
                image: image,
                startTime: startTime
            )
            return result
        } catch {
            await handleParsingError(error: error, request: request, startTime: startTime)
            throw error
        }
    }

    // MARK: - Private Parsing Methods

    private func processVisionRequest(
        jpegData: Data,
        request: LLMRequest,
        image: UIImage,
        startTime: Date
    ) async throws -> PayslipItem {
        let response = try await service.send(imageData: jpegData, mimeType: "image/jpeg", request: request)
        let cleanedContent = try validateAndCleanResponse(response.content)
        let data = try convertToData(cleanedContent, raw: response.content)

        let llmResponse = try JSONDecoder().decode(LLMPayslipResponse.self, from: data)
        let sanitized = sanitizeResponse(llmResponse)

        let extractionDuration = Date().timeIntervalSince(startTime)
        ParsingAnalytics.log(.extractionComplete(duration: extractionDuration))

        await reportProgress(.validating)

        let (finalResult, finalConfidence) = try await validateAndVerify(image: image, sanitized: sanitized)
        let result = mapToPayslipItem(finalResult, confidence: finalConfidence)

        await trackUsage(request: request, response: response, error: nil, startTime: startTime)
        cacheAndLogResult(result: result, confidence: finalConfidence, image: image, startTime: startTime)
        await reportCompletion(result)

        return result
    }

    private func validateAndCleanResponse(_ raw: String) throws -> String {
        let scrubber = LLMResponsePIIScrubber()
        let scrubResult = scrubber.scrub(raw)

        if scrubResult.severity == .critical {
            logger.error("🚨 CRITICAL: PII detected in Vision LLM response - rejecting parse")
            throw LLMError.piiDetectedInResponse(details: scrubResult.detectedPII.map { $0.pattern.name })
        }

        if scrubResult.severity == .warning {
            logger.warning("⚠️ WARNING: Possible PII in response - using scrubbed version")
        }

        let cleanedContent = VisionLLMParserHelpers.cleanJSONResponse(scrubResult.cleanedText)

        guard VisionLLMParserHelpers.isCompleteJSON(cleanedContent) else {
            logSample(raw)
            logger.error("Vision LLM returned incomplete JSON (missing closing braces)")
            throw LLMError.invalidResponse
        }

        return cleanedContent
    }

    private func convertToData(_ cleanedContent: String, raw: String) throws -> Data {
        guard let data = cleanedContent.data(using: .utf8) else {
            logSample(raw)
            logger.error("Failed to convert cleaned content to UTF8 data")
            throw LLMError.decodingError(NSError(domain: "InvalidUTF8", code: 0, userInfo: nil))
        }
        return data
    }

    private func validateAndVerify(
        image: UIImage,
        sanitized: LLMPayslipResponse
    ) async throws -> (LLMPayslipResponse, Double) {
        let sanityCheck = validator.validate(sanitized)
        let baseConfidence = 1.0
        let initialConfidence = max(0.0, baseConfidence + sanityCheck.confidenceAdjustment)

        logger.info("Initial confidence: \(String(format: "%.2f", initialConfidence))")

        ParsingAnalytics.log(.validationComplete(issues: sanityCheck.issues.count, confidence: initialConfidence))

        return try await performVerificationIfNeeded(image: image, sanitized: sanitized, initialConfidence: initialConfidence)
    }

    private func cacheAndLogResult(result: PayslipItem, confidence: Double, image: UIImage, startTime: Date) {
        let totalDuration = Date().timeIntervalSince(startTime)
        logger.info("Vision LLM parsing successful (confidence: \(String(format: "%.1f%%", confidence * 100)))")

        ParsingAnalytics.log(.parsingComplete(
            confidence: confidence,
            duration: totalDuration,
            source: "LLM Vision (\(service.provider.rawValue))"
        ))

        LLMResponseCache.shared.set(result: result, confidence: confidence, for: image)
    }

    private func handleParsingError(error: Error, request: LLMRequest, startTime: Date) async {
        let duration = Date().timeIntervalSince(startTime)
        logger.error("Vision LLM parsing failed: \(error.localizedDescription)")

        ParsingAnalytics.log(.parsingFailed(error: error.localizedDescription, duration: duration))

        await trackUsage(request: request, response: nil, error: error, startTime: startTime)
        await reportError(error)
    }

    // MARK: - Verification Methods

    private func performVerificationIfNeeded(
        image: UIImage,
        sanitized: LLMPayslipResponse,
        initialConfidence: Double
    ) async throws -> (LLMPayslipResponse, Double) {
        // First check if totals reconciliation retry is needed
        let reconciliation = TotalsReconciliationService.checkReconciliation(sanitized)
        if reconciliation.needsRetry {
            logger.info("📊 Totals need reconciliation, triggering focused retry...")
            await reportProgress(.verifying)

            if let retryResult = try? await verificationService.retryForTotalsReconciliation(
                image: image,
                firstPassResult: sanitized,
                reconciliation: reconciliation,
                originalConfidence: initialConfidence,
                sanitizer: sanitizeResponse
            ) {
                logger.info("✓ Totals reconciliation complete. Confidence: \(String(format: "%.2f", retryResult.confidence))")
                return (retryResult.response, retryResult.confidence)
            }
        }

        // Standard verification if confidence is low
        let shouldVerify = initialConfidence < ValidationThresholds.verificationTriggerThreshold

        if shouldVerify {
            await reportProgress(.verifying)
            ParsingAnalytics.log(.verificationTriggered(initialConfidence: initialConfidence))

            logger.info("🔍 Confidence < \(ValidationThresholds.verificationTriggerThreshold), triggering verification pass...")
            if let verified = try? await verificationService.verify(
                image: image,
                firstPassResult: sanitized,
                originalConfidence: initialConfidence,
                sanitizer: sanitizeResponse
            ) {
                logger.info("✓ Verification complete. Final confidence: \(String(format: "%.2f", verified.confidence))")
                return (verified.response, verified.confidence)
            } else {
                logger.warning("⚠️ Verification pass failed, using first pass result")
            }
        } else {
            logger.info("✓ High confidence (\(String(format: "%.2f", initialConfidence))), skipping verification")
        }

        return (sanitized, initialConfidence)
    }

    // MARK: - Helper Methods

    private func logSample(_ raw: String) {
        let sample = raw.prefix(400)
        logger.error("Vision LLM non-JSON response sample: \(sample, privacy: .public)")
    }

    private func sanitizeResponse(_ response: LLMPayslipResponse) -> LLMPayslipResponse {
        return VisionLLMParserHelpers.sanitizeResponse(response, logger: logger)
    }

    private func mapToPayslipItem(_ response: LLMPayslipResponse, confidence: Double) -> PayslipItem {
        let earnings = response.earnings ?? [:]
        let deductions = response.deductions ?? [:]

        let credits = response.grossPay ?? earnings.values.reduce(0, +)
        let debits = response.totalDeductions ?? deductions.values.reduce(0, +)

        let dsop = deductions["DSOP"] ?? 0.0
        let tax = deductions["ITAX"] ?? deductions["TAX"] ?? 0.0

        return PayslipItem(
            id: UUID(),
            month: response.month ?? "",
            year: response.year ?? Calendar.current.component(.year, from: Date()),
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            earnings: earnings,
            deductions: deductions,
            source: "LLM Vision (\(service.provider.rawValue))",
            confidenceScore: confidence,
            fieldConfidences: nil
        )
    }

    // MARK: - Usage Tracking

    private func trackUsage(request: LLMRequest, response: LLMResponse?, error: Error?, startTime: Date) async {
        guard let tracker = usageTracker else { return }
        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
        do {
            try await tracker.trackUsage(
                request: request,
                response: response,
                provider: service.provider,
                model: "vision",
                latencyMs: latencyMs,
                error: error
            )
        } catch {
            logger.error("Failed to track vision usage: \(error.localizedDescription)")
        }
    }
}
