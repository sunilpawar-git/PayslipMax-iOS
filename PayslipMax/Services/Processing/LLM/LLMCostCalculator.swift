//
//  LLMCostCalculator.swift
//  PayslipMax
//
//  Service for calculating LLM API costs
//

import Foundation
import OSLog

/// Service to calculate costs for LLM API usage
final class LLMCostCalculator {

    // MARK: - Properties

    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "CostCalculator")

    /// Pricing configuration (loaded from UserDefaults or defaults)
    private var pricingConfig: LLMPricingConfiguration

    // MARK: - Initialization

    /// Initialize cost calculator with optional custom pricing
    /// - Parameter pricingConfig: Custom pricing configuration (defaults to stored or default pricing)
    init(pricingConfig: LLMPricingConfiguration? = nil) {
        self.pricingConfig = pricingConfig ?? LLMPricingConfiguration.load()
    }

    // MARK: - Cost Calculation

    /// Calculate cost for a single API call
    /// - Parameters:
    ///   - provider: LLM provider
    ///   - model: Model name (optional, uses default pricing if not recognized)
    ///   - inputTokens: Number of input tokens
    ///   - outputTokens: Number of output tokens
    /// - Returns: Cost in USD
    func calculateCost(
        provider: LLMProvider,
        model: String,
        inputTokens: Int,
        outputTokens: Int
    ) -> Double {
        let pricing: ProviderPricing

        switch provider {
        case .gemini:
            pricing = pricingConfig.gemini

        case .mock:
            // Mock has no cost
            return 0.0
        }

        let inputCost = Double(inputTokens) * pricing.inputPer1M / 1_000_000
        let outputCost = Double(outputTokens) * pricing.outputPer1M / 1_000_000

        return inputCost + outputCost
    }

    /// Convert USD to INR
    /// - Parameter usd: Amount in USD
    /// - Returns: Amount in INR
    func convertToINR(usd: Double) -> Double {
        return usd * pricingConfig.usdToINR
    }

    /// Convert INR to USD
    /// - Parameter inr: Amount in INR
    /// - Returns: Amount in USD
    func convertToUSD(inr: Double) -> Double {
        return inr / pricingConfig.usdToINR
    }

    // MARK: - Configuration Management

    /// Update pricing configuration
    /// - Parameter config: New pricing configuration
    func updatePricingConfiguration(_ config: LLMPricingConfiguration) {
        self.pricingConfig = config
        config.save()
        logger.info("Updated pricing configuration")
    }

    /// Get current pricing configuration
    /// - Returns: Current pricing configuration
    func getPricingConfiguration() -> LLMPricingConfiguration {
        return pricingConfig
    }

    // MARK: - Aggregate Calculations

    /// Calculate total cost from multiple usage records
    /// - Parameters:
    ///   - records: Array of LLM usage records
    ///   - currency: Currency for result (USD or INR)
    /// - Returns: Total cost
    func calculateTotalCost(from records: [LLMUsageRecord], currency: Currency = .inr) -> Double {
        switch currency {
        case .usd:
            return records.reduce(0) { $0 + $1.costUSD }
        case .inr:
            return records.reduce(0) { $0 + $1.costINR }
        }
    }

    /// Calculate average cost per call from multiple usage records
    /// - Parameters:
    ///   - records: Array of LLM usage records
    ///   - currency: Currency for result (USD or INR)
    /// - Returns: Average cost per call
    func calculateAverageCost(from records: [LLMUsageRecord], currency: Currency = .inr) -> Double {
        guard !records.isEmpty else { return 0.0 }

        let total = calculateTotalCost(from: records, currency: currency)
        return total / Double(records.count)
    }

    /// Calculate percentile cost
    /// - Parameters:
    ///   - records: Array of LLM usage records
    ///   - percentile: Percentile to calculate (0-100)
    ///   - currency: Currency for result (USD or INR)
    /// - Returns: Cost at given percentile
    func calculatePercentile(from records: [LLMUsageRecord], percentile: Double, currency: Currency = .inr) -> Double {
        guard !records.isEmpty else { return 0.0 }
        guard percentile >= 0 && percentile <= 100 else { return 0.0 }

        let costs = records.map { currency == .usd ? $0.costUSD : $0.costINR }
        let sorted = costs.sorted()

        let index = Int(ceil(Double(sorted.count) * percentile / 100.0)) - 1
        let clampedIndex = max(0, min(sorted.count - 1, index))

        return sorted[clampedIndex]
    }
}

// MARK: - Estimation Helpers

extension LLMCostCalculator {
    /// Estimate cost for a hypothetical payslip parse
    /// - Parameter provider: LLM provider
    /// - Returns: Estimated cost in INR
    func estimatePayslipParseCost(provider: LLMProvider) -> Double {
        // Typical payslip parsing:
        // Input: ~2000 tokens (PDF text)
        // Output: ~500 tokens (JSON response)
        let estimatedInputTokens = 2000
        let estimatedOutputTokens = 500

        let costUSD = calculateCost(
            provider: provider,
            model: "", // Use default pricing
            inputTokens: estimatedInputTokens,
            outputTokens: estimatedOutputTokens
        )

        return convertToINR(usd: costUSD)
    }

    /// Calculate estimated annual cost per user
    /// - Parameters:
    ///   - callsPerYear: Expected number of LLM calls per year
    ///   - provider: LLM provider
    /// - Returns: Estimated annual cost in INR
    func estimateAnnualCostPerUser(callsPerYear: Int, provider: LLMProvider) -> Double {
        let costPerParse = estimatePayslipParseCost(provider: provider)
        return costPerParse * Double(callsPerYear)
    }

    /// Calculate profit margin given subscription price and estimated usage
    /// - Parameters:
    ///   - subscriptionPriceINR: Annual subscription price in INR
    ///   - callsPerYear: Expected number of LLM calls per year
    ///   - provider: LLM provider
    /// - Returns: Profit margin as percentage (0-100)
    func calculateProfitMargin(
        subscriptionPriceINR: Double,
        callsPerYear: Int,
        provider: LLMProvider
    ) -> Double {
        let cost = estimateAnnualCostPerUser(callsPerYear: callsPerYear, provider: provider)
        let profit = subscriptionPriceINR - cost
        let margin = (profit / subscriptionPriceINR) * 100

        return max(0, margin) // Don't show negative margins
    }
}
