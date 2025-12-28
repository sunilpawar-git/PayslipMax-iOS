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
        var response: LLMResponse?

        // Check cache first
        if let cached = LLMResponseCache.shared.get(for: image) {
            logger.info("✨ Cache hit - returning cached result (confidence: \(String(format: "%.2f", cached.confidence)))")
            await reportCompletion(cached.payslipItem)
            return cached.payslipItem
        }

        // Analytics: Parsing started
        ParsingAnalytics.log(.parsingStarted)

        // Report: Preparing
        await reportProgress(.preparing)

        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            await reportError(LLMError.invalidConfiguration)
            throw LLMError.invalidConfiguration
        }

        let request = LLMRequest(
            prompt: VisionLLMPromptTemplate.extractionPrompt,
            systemPrompt: nil,
            jsonMode: true
        )

        // Report: Extracting
        await reportProgress(.extracting)

        do {
            response = try await service.send(imageData: jpegData, mimeType: "image/jpeg", request: request)
            let raw = response?.content ?? ""

            // Scrub response for accidentally leaked PII
            let scrubber = LLMResponsePIIScrubber()
            let scrubResult = scrubber.scrub(raw)

            if scrubResult.severity == .critical {
                logger.error("🚨 CRITICAL: PII detected in Vision LLM response - rejecting parse")
                let error = LLMError.piiDetectedInResponse(
                    details: scrubResult.detectedPII.map { $0.pattern.name }
                )
                await reportError(error)
                throw error
            }

            if scrubResult.severity == .warning {
                logger.warning("⚠️ WARNING: Possible PII in response - using scrubbed version")
            }

            let cleanedContent = VisionLLMParserHelpers.cleanJSONResponse(scrubResult.cleanedText)

            // Validate JSON completeness before attempting to decode
            guard VisionLLMParserHelpers.isCompleteJSON(cleanedContent) else {
                logSample(raw)
                logger.error("Vision LLM returned incomplete JSON (missing closing braces)")
                await reportError(LLMError.invalidResponse)
                throw LLMError.invalidResponse
            }

            guard let data = cleanedContent.data(using: .utf8) else {
                logSample(raw)
                logger.error("Failed to convert cleaned content to UTF8 data")
                let error = LLMError.decodingError(NSError(domain: "InvalidUTF8", code: 0, userInfo: nil))
                await reportError(error)
                throw error
            }

            do {
                let llmResponse = try JSONDecoder().decode(LLMPayslipResponse.self, from: data)
                let sanitized = sanitizeResponse(llmResponse)

                // Analytics: Extraction complete
                let extractionDuration = Date().timeIntervalSince(startTime)
                ParsingAnalytics.log(.extractionComplete(duration: extractionDuration))

                // Report: Validating
                await reportProgress(.validating)

                // Run sanity checks and calculate confidence
                let sanityCheck = validator.validate(sanitized)
                let baseConfidence = 1.0
                let initialConfidence = max(0.0, baseConfidence + sanityCheck.confidenceAdjustment)

                logger.info("Initial confidence: \(String(format: "%.2f", initialConfidence))")

                // Analytics: Validation complete
                ParsingAnalytics.log(.validationComplete(
                    issues: sanityCheck.issues.count,
                    confidence: initialConfidence
                ))

                // Verify if needed (confidence < threshold)
                let (finalResult, finalConfidence) = try await performVerificationIfNeeded(
                    image: image,
                    sanitized: sanitized,
                    initialConfidence: initialConfidence
                )

                let result = mapToPayslipItem(finalResult, confidence: finalConfidence)
                await trackUsage(request: request, response: response, error: nil, startTime: startTime)

                let totalDuration = Date().timeIntervalSince(startTime)
                logger.info("Vision LLM parsing successful (confidence: \(String(format: "%.1f%%", finalConfidence * 100)))")

                // Analytics: Parsing complete
                ParsingAnalytics.log(.parsingComplete(
                    confidence: finalConfidence,
                    duration: totalDuration,
                    source: "LLM Vision (\(service.provider.rawValue))"
                ))

                // Cache the result
                LLMResponseCache.shared.set(result: result, confidence: finalConfidence, for: image)

                // Report: Completed
                await reportCompletion(result)

                return result

            } catch let decodingError as DecodingError {
                logSample(raw)
                logger.error("JSON Decoding Error: \(String(describing: decodingError))")
                await reportError(decodingError)
                throw decodingError
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Vision LLM parsing failed: \(error.localizedDescription)")

            // Analytics: Parsing failed
            ParsingAnalytics.log(.parsingFailed(
                error: error.localizedDescription,
                duration: duration
            ))

            await trackUsage(request: request, response: response, error: error, startTime: startTime)
            await reportError(error)
            throw error
        }
    }

    // MARK: - Private Methods

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

            // Try totals reconciliation first, passing original confidence to preserve if retry fails
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
            // Report: Verifying
            await reportProgress(.verifying)

            // Analytics: Verification triggered
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
