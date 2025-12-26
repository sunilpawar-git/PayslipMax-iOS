//
//  VisionLLMVerificationService.swift
//  PayslipMax
//
//  Verification pass logic for Vision LLM parsing - extracted for modularity
//

import Foundation
import UIKit
import OSLog

/// Result of verification pass
struct VisionVerificationResult {
    let response: LLMPayslipResponse
    let confidence: Double
}

/// Service for performing verification passes on LLM parsing results
final class VisionLLMVerificationService {
    private let service: LLMVisionServiceProtocol
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "VisionVerification")

    init(service: LLMVisionServiceProtocol) {
        self.service = service
    }

    /// Performs a second LLM pass to verify the first pass results
    func verify(
        image: UIImage,
        firstPassResult: LLMPayslipResponse,
        originalConfidence: Double,
        sanitizer: (LLMPayslipResponse) -> LLMPayslipResponse
    ) async throws -> VisionVerificationResult {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            throw LLMError.invalidConfiguration
        }

        let verificationPrompt = createVerificationPrompt(firstPassResult: firstPassResult)

        let request = LLMRequest(
            prompt: verificationPrompt,
            systemPrompt: nil,
            jsonMode: true
        )

        let response = try await service.send(imageData: jpegData, mimeType: "image/jpeg", request: request)
        let raw = response.content

        let cleanedContent = VisionLLMParserHelpers.cleanJSONResponse(raw)
        guard let data = cleanedContent.data(using: .utf8) else {
            throw LLMError.decodingError(NSError(domain: "InvalidUTF8", code: 0, userInfo: nil))
        }

        let verifiedResponse = try JSONDecoder().decode(LLMPayslipResponse.self, from: data)
        let sanitized = sanitizer(verifiedResponse)

        let agreement = calculateAgreement(first: firstPassResult, second: sanitized)
        logger.info("Verification agreement: \(String(format: "%.1f%%", agreement * 100))")

        let finalConfidence = calculateFinalConfidence(
            originalConfidence: originalConfidence,
            agreement: agreement
        )

        // Analytics: Verification complete
        ParsingAnalytics.log(.verificationComplete(
            agreement: agreement,
            finalConfidence: finalConfidence
        ))

        if agreement >= ValidationThresholds.moderateAgreementThreshold {
            logger.info("✓ High agreement (\(String(format: "%.0f%%", agreement * 100))), using verified result")
            return VisionVerificationResult(response: sanitized, confidence: finalConfidence)
        } else if agreement >= ValidationThresholds.lowAgreementThreshold {
            logger.info("⚠️ Moderate agreement (\(String(format: "%.0f%%", agreement * 100))), using second pass with reduced confidence")
            return VisionVerificationResult(response: sanitized, confidence: finalConfidence * ValidationThresholds.moderateAgreementDisplayMultiplier)
        } else {
            logger.warning("❌ Low agreement (\(String(format: "%.0f%%", agreement * 100))), reverting to first pass")
            return VisionVerificationResult(response: firstPassResult, confidence: originalConfidence * ValidationThresholds.lowAgreementMultiplier)
        }
    }

    // MARK: - Private Methods

    private func createVerificationPrompt(firstPassResult: LLMPayslipResponse) -> String {
        let earnings = firstPassResult.earnings?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "none"
        let deductions = firstPassResult.deductions?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "none"

        return """
        VERIFICATION TASK: Cross-check the following extracted values against the payslip image.

        Previously extracted values (VERIFY THESE):
        Earnings: \(earnings)
        Deductions: \(deductions)
        Gross Pay: \(firstPassResult.grossPay ?? 0)
        Total Deductions: \(firstPassResult.totalDeductions ?? 0)
        Net Remittance: \(firstPassResult.netRemittance ?? 0)
        Month: \(firstPassResult.month ?? "unknown")
        Year: \(firstPassResult.year ?? 0)

        Your task: Re-extract ALL values from the image independently. Do NOT simply copy the values above.
        Look at the image carefully and extract earnings, deductions, and totals as you see them.

        Return the same JSON format:
        {
          "earnings": {"BPAY": <amount>, "DA": <amount>, ...},
          "deductions": {"DSOP": <amount>, "ITAX": <amount>, ...},
          "grossPay": <amount>,
          "totalDeductions": <amount>,
          "netRemittance": <amount>,
          "month": "MONTH_NAME",
          "year": <year>
        }

        CRITICAL: Extract what you see in the image, not what was previously extracted.
        """
    }

    private func calculateAgreement(first: LLMPayslipResponse, second: LLMPayslipResponse) -> Double {
        var agreements: [Double] = []

        if let gross1 = first.grossPay, let gross2 = second.grossPay, gross1 > 0 {
            let error = abs(gross1 - gross2) / gross1
            agreements.append(1.0 - error)
        }

        if let ded1 = first.totalDeductions, let ded2 = second.totalDeductions, ded1 > 0 {
            let error = abs(ded1 - ded2) / ded1
            agreements.append(1.0 - error)
        }

        if let net1 = first.netRemittance, let net2 = second.netRemittance, net1 > 0 {
            let error = abs(net1 - net2) / net1
            agreements.append(1.0 - error)
        }

        let earnings1 = first.earnings ?? [:]
        let earnings2 = second.earnings ?? [:]
        let earningsAgreement = compareLineItems(first: earnings1, second: earnings2)
        agreements.append(earningsAgreement)

        let deductions1 = first.deductions ?? [:]
        let deductions2 = second.deductions ?? [:]
        let deductionsAgreement = compareLineItems(first: deductions1, second: deductions2)
        agreements.append(deductionsAgreement)

        return min(1.0, agreements.reduce(0, +) / Double(max(agreements.count, 1)))
    }

    private func compareLineItems(first: [String: Double], second: [String: Double]) -> Double {
        let allKeys = Set(first.keys).union(Set(second.keys))
        guard !allKeys.isEmpty else { return 1.0 }

        var matches = 0
        let total = allKeys.count

        for key in allKeys {
            if let val1 = first[key], let val2 = second[key] {
                let error = abs(val1 - val2) / max(val1, val2)
                if error < ValidationThresholds.lineItemComparisonTolerance {
                    matches += 1
                }
            }
        }

        return Double(matches) / Double(total)
    }

    private func calculateFinalConfidence(originalConfidence: Double, agreement: Double) -> Double {
        if agreement >= ValidationThresholds.highAgreementThreshold {
            return min(1.0, originalConfidence + ValidationThresholds.highAgreementConfidenceBoost)
        } else if agreement >= ValidationThresholds.moderateAgreementThreshold {
            return originalConfidence
        } else if agreement >= ValidationThresholds.lowAgreementThreshold {
            return originalConfidence * ValidationThresholds.moderateAgreementMultiplier
        } else {
            return originalConfidence * ValidationThresholds.lowAgreementMultiplier
        }
    }
}

