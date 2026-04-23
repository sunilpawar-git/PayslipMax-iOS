import Foundation
import os

/// Extension providing on-device LLM fallback for the HybridPayslipProcessor.
/// Sits between regex and cloud LLM in the processing cascade.
extension HybridPayslipProcessor {

    /// Attempts to parse payslip text using the on-device LLM.
    /// Returns nil if the service is unavailable or parsing fails.
    func attemptOnDeviceLLM(
        text: String,
        onDeviceService: OnDeviceLLMServiceProtocol?,
        reason: String
    ) async -> PayslipItem? {
        guard let service = onDeviceService, service.isAvailable else {
            logger.info("On-device LLM unavailable, skipping")
            return nil
        }

        logger.info("Attempting on-device LLM. Reason: \(reason)")

        guard let result = await service.parsePayslip(text: text) else {
            logger.info("On-device LLM returned nil result")
            return nil
        }

        guard result.grossPay > 0 else {
            logger.warning("On-device LLM returned zero gross pay, discarding")
            return nil
        }

        let item = PayslipItem.from(onDeviceResult: result)
        logger.info("On-device LLM succeeded: gross=\(result.grossPay)")
        return item
    }
}
