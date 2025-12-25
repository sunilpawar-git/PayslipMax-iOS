import Foundation
import OSLog
import UIKit

/// Vision-based payslip parser using an LLM that accepts images.
final class VisionLLMPayslipParser {
    private let service: LLMVisionServiceProtocol
    private let usageTracker: LLMUsageTrackerProtocol?
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "VisionParser")

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

        let prompt = """
        You are a military payslip parser. Extract ONLY earnings and deductions from this payslip image.

        ⚠️ CRITICAL PRIVACY - DO NOT EXTRACT OR RETURN:
        ❌ Personal names (employee name, rank name, unit commander)
        ❌ Account numbers (bank A/C, SUS/Service number, Army/Navy/Air Force number)
        ❌ PAN card numbers
        ❌ Phone numbers
        ❌ Email addresses
        ❌ Physical addresses
        ❌ Signatures or signature blocks
        ❌ Unit names or posting locations
        ❌ Date of birth or age

        ✅ ONLY EXTRACT:
        • Pay codes (BPAY, DA, MSP, TA, HRA, CCA, NPS, GPF, TPTA) and amounts
        • Deduction codes (DSOP, DSOPP, AGIF, ITAX, CGHS, AFPP) and amounts
        • Totals: Gross Pay, Total Deductions, Net Remittance
        • Month and year of payslip

        Return ONLY valid JSON (no markdown, no code fences, no extra text) with this EXACT structure:
        {
          "earnings": {"BPAY": 37000, "DA": 24200, "MSP": 5200},
          "deductions": {"DSOP": 2220, "AGIF": 7500, "ITAX": 15585},
          "grossPay": 86953,
          "totalDeductions": 28305,
          "netRemittance": 58252,
          "month": "AUGUST",
          "year": 2025
        }

        CRITICAL RULES:
        1. Use ONLY these 7 top-level keys: earnings, deductions, grossPay, totalDeductions, netRemittance, month, year
        2. earnings and deductions are objects with string keys (e.g. "BPAY", "DA") and numeric values
        3. All numbers are plain integers or decimals (no ₹, no commas, no strings)
        4. month is uppercase string (e.g. "AUGUST"), year is integer (e.g. 2025)
        5. netRemittance MUST equal grossPay - totalDeductions
        6. Extract ALL visible line items from earnings/deductions tables
        7. Return ONLY the JSON object - no explanation, no markdown fences

        REMINDER: Exclude ALL personal identifiers from your response. Only return financial data and pay codes.
        """

        let request = LLMRequest(
            prompt: prompt,
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

            let cleanedContent = cleanJSONResponse(scrubResult.cleanedText)

            // Debug logging
            logger.debug("Raw response length: \(raw.count)")
            logger.debug("Cleaned response length: \(cleanedContent.count)")
            logger.debug("Cleaned response first 500 chars: \(cleanedContent.prefix(500))")

            // Validate JSON completeness before attempting to decode
            guard isCompleteJSON(cleanedContent) else {
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
                let result = mapToPayslipItem(sanitized)

                await trackUsage(request: request, response: response, error: nil, startTime: startTime)
                logger.info("Vision LLM parsing successful")
                return result
            } catch let decodingError as DecodingError {
                logSample(raw)
                logger.error("JSON Decoding Error: \(String(describing: decodingError))")
                logger.error("Cleaned JSON that failed: \(cleanedContent)")
                throw decodingError
            } catch {
                logSample(raw)
                logger.error("Unknown parsing error: \(error.localizedDescription)")
                throw error
            }
        } catch {
            logger.error("Vision LLM parsing failed: \(error.localizedDescription)")
            await trackUsage(request: request, response: response, error: error, startTime: startTime)
            throw error
        }
    }

    // MARK: - Helpers

    private func isCompleteJSON(_ json: String) -> Bool {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{"), trimmed.hasSuffix("}") else {
            return false
        }

        // Count opening and closing braces
        var braceCount = 0
        for char in trimmed {
            if char == "{" {
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
            }
        }

        return braceCount == 0
    }

    private func cleanJSONResponse(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove all markdown code fences (opening and closing)
        // Handle both ```json and ``` variants
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")

        // Trim again after fence removal
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract pure JSON by finding first { and last }
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }

        return cleaned
    }

    private func logSample(_ raw: String) {
        let sample = raw.prefix(400)
        logger.error("Vision LLM non-JSON response sample: \(sample, privacy: .public)")
    }

    private func sanitizeResponse(_ response: LLMPayslipResponse) -> LLMPayslipResponse {
        let earningsTotal = response.earnings?.values.reduce(0, +) ?? 0
        let deductionsTotal = response.deductions?.values.reduce(0, +) ?? 0

        let gross = response.grossPay ?? earningsTotal
        let deductions = response.totalDeductions ?? deductionsTotal
        let reconciledNet = gross - deductions
        let providedNet = response.netRemittance ?? reconciledNet

        return LLMPayslipResponse(
            earnings: response.earnings,
            deductions: response.deductions,
            grossPay: gross > 0 ? gross : earningsTotal,
            totalDeductions: deductions > 0 ? deductions : deductionsTotal,
            netRemittance: providedNet,
            month: response.month,
            year: response.year
        )
    }

    private func mapToPayslipItem(_ response: LLMPayslipResponse) -> PayslipItem {
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
            confidenceScore: nil,
            fieldConfidences: nil
        )
    }

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
