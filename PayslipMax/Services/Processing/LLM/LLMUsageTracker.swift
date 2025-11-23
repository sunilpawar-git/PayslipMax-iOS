//
//  LLMUsageTracker.swift
//  PayslipMax
//
//  Service for tracking LLM API usage
//

import Foundation
import SwiftData
import OSLog

/// Service to track LLM API usage and store in SwiftData
@MainActor
final class LLMUsageTracker: LLMUsageTrackerProtocol {

    // MARK: - Properties

    private let modelContainer: ModelContainer
    private let costCalculator: LLMCostCalculator
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "UsageTracker")

    /// Device identifier (anonymized for privacy)
    private let deviceIdentifier: String

    // MARK: - Initialization

    init(modelContainer: ModelContainer, costCalculator: LLMCostCalculator) {
        self.modelContainer = modelContainer
        self.costCalculator = costCalculator
        self.deviceIdentifier = Self.getOrCreateDeviceIdentifier()
    }

    // MARK: - LLMUsageTrackerProtocol

    func trackUsage(
        request: LLMRequest,
        response: LLMResponse?,
        provider: LLMProvider,
        model: String,
        latencyMs: Int,
        error: Error?
    ) async throws {
        let context = modelContainer.mainContext

        // Extract token counts
        let inputTokens = response?.usage?.promptTokens ?? 0
        let outputTokens = response?.usage?.completionTokens ?? 0

        // Calculate costs
        let costUSD = costCalculator.calculateCost(
            provider: provider,
            model: model,
            inputTokens: inputTokens,
            outputTokens: outputTokens
        )
        let costINR = costCalculator.convertToINR(usd: costUSD)

        // Create usage record
        let record = LLMUsageRecord(
            timestamp: Date(),
            deviceIdentifier: deviceIdentifier,
            provider: provider.rawValue,
            model: model,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            costUSD: costUSD,
            costINR: costINR,
            success: error == nil,
            latencyMs: latencyMs,
            errorMessage: error?.localizedDescription
        )

        context.insert(record)

        do {
            try context.save()
            logger.info("Tracked LLM usage: \(provider.rawValue) - \(model) - \(inputTokens + outputTokens) tokens - ₹\(costINR)")
        } catch {
            logger.error("Failed to save usage record: \(error.localizedDescription)")
            throw error
        }
    }

    func getUserUsage(from startDate: Date, to endDate: Date) async throws -> [LLMUsageRecord] {
        let context = modelContainer.mainContext

        let deviceId = deviceIdentifier
        let predicate = #Predicate<LLMUsageRecord> { record in
            record.deviceIdentifier == deviceId &&
            record.timestamp >= startDate &&
            record.timestamp <= endDate
        }

        let descriptor = FetchDescriptor<LLMUsageRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch usage records: \(error.localizedDescription)")
            throw error
        }
    }

    func getUserUsageCount(from startDate: Date, to endDate: Date) async throws -> Int {
        let records = try await getUserUsage(from: startDate, to: endDate)
        return records.count
    }

    func getLastUsageTimestamp() async throws -> Date? {
        let context = modelContainer.mainContext

        let deviceId = deviceIdentifier
        let predicate = #Predicate<LLMUsageRecord> { record in
            record.deviceIdentifier == deviceId
        }

        let descriptor = FetchDescriptor<LLMUsageRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            let records = try context.fetch(descriptor)
            return records.first?.timestamp
        } catch {
            logger.error("Failed to fetch last usage timestamp: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Device Identifier

    /// Get or create a persistent device identifier
    /// This is stored in UserDefaults for privacy (not tied to user account)
    private static func getOrCreateDeviceIdentifier() -> String {
        let key = "llm_device_identifier"

        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }

        // Create new identifier
        let identifier = UUID().uuidString
        UserDefaults.standard.set(identifier, forKey: key)
        return identifier
    }
}

// MARK: - Analytics Helper Methods

extension LLMUsageTracker {
    /// Get total cost for user within date range
    func getTotalCost(from startDate: Date, to endDate: Date, currency: Currency = .inr) async throws -> Double {
        let records = try await getUserUsage(from: startDate, to: endDate)

        switch currency {
        case .usd:
            return records.reduce(0) { $0 + $1.costUSD }
        case .inr:
            return records.reduce(0) { $0 + $1.costINR }
        }
    }

    /// Get success rate for user within date range
    func getSuccessRate(from startDate: Date, to endDate: Date) async throws -> Double {
        let records = try await getUserUsage(from: startDate, to: endDate)

        guard !records.isEmpty else { return 0.0 }

        let successCount = records.filter { $0.success }.count
        return Double(successCount) / Double(records.count)
    }

    /// Get average latency for user within date range
    func getAverageLatency(from startDate: Date, to endDate: Date) async throws -> Int {
        let records = try await getUserUsage(from: startDate, to: endDate)

        guard !records.isEmpty else { return 0 }

        let totalLatency = records.reduce(0) { $0 + $1.latencyMs }
        return totalLatency / records.count
    }

    /// Delete usage records older than the specified number of days
    /// - Parameter days: Number of days to retain (default: 365 for 1 year)
    /// - Returns: Number of records deleted
    @discardableResult
    func deleteOldRecords(olderThanDays days: Int = 365) async throws -> Int {
        let context = modelContainer.mainContext
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let predicate = #Predicate<LLMUsageRecord> { record in
            record.timestamp < cutoffDate
        }

        let descriptor = FetchDescriptor<LLMUsageRecord>(predicate: predicate)

        do {
            let oldRecords = try context.fetch(descriptor)
            let count = oldRecords.count

            for record in oldRecords {
                context.delete(record)
            }

            try context.save()
            logger.info("Deleted \(count) old usage records (older than \(days) days)")
            return count
        } catch {
            logger.error("Failed to delete old records: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Supporting Types

enum Currency {
    case usd
    case inr
}
