import Foundation
import OSLog

extension LLMPayslipParser {

    func validate(response: LLMPayslipResponse) {
        guard let gross = response.grossPay,
              let deductionsTotal = response.totalDeductions,
              let net = response.netRemittance else {
            return
        }

        let netError = reconciliationError(gross: gross, deductions: deductionsTotal, net: net)
        if net > 0 && netError > 0.05 {
            let errorStr = String(format: "%.2f%%", netError * 100)
            logger.warning("""
                LLM totals mismatch beyond tolerance \
                (gross: \(gross), deductions: \(deductionsTotal), net: \(net), \
                error: \(errorStr)) - accepting response for fallback
                """)
            return
        }

        let netErrorPercent = String(format: "%.2f%%", netError * 100)
        logger.info("LLM totals validated within tolerance (gross: \(gross), deductions: \(deductionsTotal), net: \(net), netError: \(netErrorPercent))")
    }

    func sanitizeResponse(_ response: LLMPayslipResponse) -> LLMPayslipResponse {
        let earningsTotal = response.earnings?.values.reduce(0, +) ?? 0
        let deductionsTotal = response.deductions?.values.reduce(0, +) ?? 0

        let gross = response.grossPay ?? earningsTotal
        let deductions = response.totalDeductions ?? deductionsTotal
        let reconciledNet = gross - deductions
        let providedNet = response.netRemittance ?? reconciledNet

        let error = reconciliationError(gross: gross, deductions: deductions, net: providedNet)
        if error > 0.05 {
            logger.warning("LLM totals mismatch beyond tolerance; reconciling net to gross - deductions (error: \(String(format: "%.2f%%", error * 100)))")
        }

        return LLMPayslipResponse(
            earnings: response.earnings,
            deductions: response.deductions,
            grossPay: gross > 0 ? gross : earningsTotal,
            totalDeductions: deductions > 0 ? deductions : deductionsTotal,
            netRemittance: error > 0.05 ? reconciledNet : providedNet,
            month: response.month,
            year: response.year
        )
    }

    func reconciliationError(gross: Double, deductions: Double, net: Double) -> Double {
        LLMPayslipParserHelpers.reconciliationError(gross: gross, deductions: deductions, net: net)
    }

    func mapToPayslipItem(_ response: LLMPayslipResponse, originalResponse: LLMPayslipResponse, originalText: String) -> PayslipItem {
        let earnings = response.earnings ?? [:]
        let deductions = response.deductions ?? [:]

        let calculatedCredits = earnings.values.reduce(0, +)
        let calculatedDebits = deductions.values.reduce(0, +)

        let credits = response.grossPay ?? calculatedCredits
        let debits = response.totalDeductions ?? calculatedDebits

        let dsop = deductions["DSOP"] ?? 0.0
        let tax = deductions["ITAX"] ?? deductions["TAX"] ?? 0.0

        let confidenceResult = LLMConfidenceCalculator.calculateConfidence(
            for: originalResponse,
            earnings: earnings,
            deductions: deductions
        )

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
            source: "LLM (\(service.provider.rawValue))",
            confidenceScore: confidenceResult.overall,
            fieldConfidences: confidenceResult.fieldLevel
        )
    }
}
