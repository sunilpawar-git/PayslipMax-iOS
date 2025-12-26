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

    init(service: LLMVisionServiceProtocol, usageTracker: LLMUsageTrackerProtocol? = nil) {
        self.service = service
        self.usageTracker = usageTracker
    }

    func parse(image: UIImage) async throws -> PayslipItem {
        let startTime = Date()
        var response: LLMResponse?

        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            throw LLMError.invalidConfiguration
        }

        let request = LLMRequest(
            prompt: VisionLLMPromptTemplate.extractionPrompt,
            systemPrompt: nil,
            jsonMode: true
        )

        do {
            response = try await service.send(imageData: jpegData, mimeType: "image/jpeg", request: request)
            let raw = response?.content ?? ""

            // Scrub response for accidentally leaked PII
            let scrubber = LLMResponsePIIScrubber()
            let scrubResult = scrubber.scrub(raw)

            if scrubResult.severity == .critical {
                logger.error("🚨 CRITICAL: PII detected in Vision LLM response - rejecting parse")
                throw LLMError.piiDetectedInResponse(
                    details: scrubResult.detectedPII.map { $0.pattern.name }
                )
            }

            if scrubResult.severity == .warning {
                logger.warning("⚠️ WARNING: Possible PII in response - using scrubbed version")
            }

            let cleanedContent = VisionLLMParserHelpers.cleanJSONResponse(scrubResult.cleanedText)

            // Validate JSON completeness before attempting to decode
            guard VisionLLMParserHelpers.isCompleteJSON(cleanedContent) else {
                logSample(raw)
                logger.error("Vision LLM returned incomplete JSON (missing closing braces)")
                throw LLMError.invalidResponse
            }

            guard let data = cleanedContent.data(using: .utf8) else {
                logSample(raw)
                logger.error("Failed to convert cleaned content to UTF8 data")
                throw LLMError.decodingError(NSError(domain: "InvalidUTF8", code: 0, userInfo: nil))
            }

            do {
                let llmResponse = try JSONDecoder().decode(LLMPayslipResponse.self, from: data)
                let sanitized = sanitizeResponse(llmResponse)

                // Run sanity checks and calculate confidence
                let sanityCheck = validator.validate(sanitized)
                let baseConfidence = 1.0
                let initialConfidence = max(0.0, baseConfidence + sanityCheck.confidenceAdjustment)

                logger.info("Initial confidence: \(String(format: "%.2f", initialConfidence))")

                // Verify if needed (confidence < 0.9)
                let (finalResult, finalConfidence) = try await performVerificationIfNeeded(
                    image: image,
                    sanitized: sanitized,
                    initialConfidence: initialConfidence
                )

                let result = mapToPayslipItem(finalResult, confidence: finalConfidence)
                await trackUsage(request: request, response: response, error: nil, startTime: startTime)
                logger.info("Vision LLM parsing successful (confidence: \(String(format: "%.1f%%", finalConfidence * 100)))")
                return result

            } catch let decodingError as DecodingError {
                logSample(raw)
                logger.error("JSON Decoding Error: \(String(describing: decodingError))")
                throw decodingError
            }
        } catch {
            logger.error("Vision LLM parsing failed: \(error.localizedDescription)")
            await trackUsage(request: request, response: response, error: error, startTime: startTime)
            throw error
        }
    }

    // MARK: - Private Methods

    private func performVerificationIfNeeded(
        image: UIImage,
        sanitized: LLMPayslipResponse,
        initialConfidence: Double
    ) async throws -> (LLMPayslipResponse, Double) {
        let shouldVerify = initialConfidence < 0.9

        if shouldVerify {
            logger.info("🔍 Confidence < 0.9, triggering verification pass...")
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
        let filteredDeductions = VisionLLMParserHelpers.filterSuspiciousDeductions(
            response.deductions ?? [:],
            logger: logger
        )
        let deduplicatedDeductions = VisionLLMParserHelpers.removeDuplicates(filteredDeductions)

        let earningsTotal = response.earnings?.values.reduce(0, +) ?? 0
        let deductionsTotal = deduplicatedDeductions.values.reduce(0, +)

        let gross = response.grossPay ?? earningsTotal
        let deductions = response.totalDeductions ?? deductionsTotal
        let reconciledNet = gross - deductions
        let providedNet = response.netRemittance ?? reconciledNet

        // Sanity check: deductions should be less than earnings
        if deductionsTotal > earningsTotal && earningsTotal > 0 {
            logger.warning("⚠️ Deductions exceed earnings - using filtered deductions")
            let recalculatedNet = gross - deductionsTotal
            return LLMPayslipResponse(
                earnings: response.earnings,
                deductions: deduplicatedDeductions,
                grossPay: gross > 0 ? gross : earningsTotal,
                totalDeductions: deductionsTotal,
                netRemittance: recalculatedNet,
                month: response.month,
                year: response.year
            )
        }

        return LLMPayslipResponse(
            earnings: response.earnings,
            deductions: deduplicatedDeductions,
            grossPay: gross > 0 ? gross : earningsTotal,
            totalDeductions: deductions > 0 ? deductions : deductionsTotal,
            netRemittance: providedNet,
            month: response.month,
            year: response.year
        )
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
