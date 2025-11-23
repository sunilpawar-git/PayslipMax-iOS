//
//  LLMUsageRecord.swift
//  PayslipMax
//
//  SwiftData model for tracking LLM API usage
//

import Foundation
import SwiftData

/// SwiftData model representing a single LLM API call
@Model
final class LLMUsageRecord: Identifiable {

    // MARK: - Properties

    /// Unique identifier for this usage record
    @Attribute(.unique) var id: UUID

    /// Timestamp when the API call was made (indexed for date range queries)
    var timestamp: Date

    /// Device identifier (anonymized for privacy, indexed for user queries)
    var deviceIdentifier: String

    /// LLM provider used (gemini, openai, etc.)
    var provider: String

    /// Model name (e.g., "gemini-1.5-flash", "gpt-4o-mini")
    var model: String

    /// Number of input tokens sent to the API
    var inputTokens: Int

    /// Number of output tokens received from the API
    var outputTokens: Int

    /// Total tokens (input + output)
    var totalTokens: Int

    /// Estimated cost in USD
    var costUSD: Double

    /// Estimated cost in INR
    var costINR: Double

    /// Whether the API call was successful
    var success: Bool

    /// Latency in milliseconds
    var latencyMs: Int

    /// Error message if the call failed
    var errorMessage: String?

    /// Context: what the LLM was used for (e.g., "payslip_parsing")
    var context: String

    // MARK: - Initialization

    /// Initialize a new LLM usage record
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         deviceIdentifier: String,
         provider: String,
         model: String,
         inputTokens: Int,
         outputTokens: Int,
         costUSD: Double,
         costINR: Double,
         success: Bool,
         latencyMs: Int,
         errorMessage: String? = nil,
         context: String = "payslip_parsing") {

        self.id = id
        self.timestamp = timestamp
        self.deviceIdentifier = deviceIdentifier
        self.provider = provider
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = inputTokens + outputTokens
        self.costUSD = costUSD
        self.costINR = costINR
        self.success = success
        self.latencyMs = latencyMs
        self.errorMessage = errorMessage
        self.context = context
    }
}

// MARK: - Computed Properties

extension LLMUsageRecord {
    /// Formatted cost in INR
    var formattedCostINR: String {
        return String(format: "₹%.4f", costINR)
    }

    /// Formatted cost in USD
    var formattedCostUSD: String {
        return String(format: "$%.6f", costUSD)
    }

    /// Formatted latency
    var formattedLatency: String {
        if latencyMs < 1000 {
            return "\(latencyMs)ms"
        } else {
            let seconds = Double(latencyMs) / 1000.0
            return String(format: "%.2fs", seconds)
        }
    }

    /// Human-readable timestamp
    var formattedTimestamp: String {
        LLMUsageRecord.timestampFormatter.string(from: timestamp)
    }

    /// Cached DateFormatter for performance
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}
