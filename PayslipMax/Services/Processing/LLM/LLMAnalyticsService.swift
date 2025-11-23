//
//  LLMAnalyticsService.swift
//  PayslipMax
//
//  Service for analyzing LLM usage and generating reports
//

import Foundation
import SwiftData
import OSLog

/// Service for LLM usage analytics and reporting
@MainActor
final class LLMAnalyticsService {

    // MARK: - Properties

    private let modelContainer: ModelContainer
    private let costCalculator: LLMCostCalculator
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "Analytics")

    // MARK: - Initialization

    init(modelContainer: ModelContainer, costCalculator: LLMCostCalculator) {
        self.modelContainer = modelContainer
        self.costCalculator = costCalculator
    }

    // MARK: - Analytics Queries

    /// Get all usage records within a date range
    func getAllUsage(from startDate: Date, to endDate: Date) async throws -> [LLMUsageRecord] {
        let context = modelContainer.mainContext

        let predicate = #Predicate<LLMUsageRecord> { record in
            record.timestamp >= startDate &&
            record.timestamp <= endDate
        }

        let descriptor = FetchDescriptor<LLMUsageRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    /// Get count of unique users who used LLM
    func getUniqueUserCount(from startDate: Date, to endDate: Date) async throws -> Int {
        let records = try await getAllUsage(from: startDate, to: endDate)
        let uniqueDevices = Set(records.map { $0.deviceIdentifier })
        return uniqueDevices.count
    }

    /// Get average calls per user
    func getAverageCallsPerUser(from startDate: Date, to endDate: Date) async throws -> Double {
        let records = try await getAllUsage(from: startDate, to: endDate)
        guard !records.isEmpty else { return 0 }

        let uniqueDevices = Set(records.map { $0.deviceIdentifier })
        guard !uniqueDevices.isEmpty else { return 0 }

        return Double(records.count) / Double(uniqueDevices.count)
    }

    /// Get success rate (percentage of successful API calls)
    func getSuccessRate(from startDate: Date, to endDate: Date) async throws -> Double {
        let records = try await getAllUsage(from: startDate, to: endDate)
        guard !records.isEmpty else { return 0 }

        let successCount = records.filter { $0.success }.count
        return (Double(successCount) / Double(records.count)) * 100
    }

    /// Get usage statistics summary
    func getUsageStatistics(from startDate: Date, to endDate: Date) async throws -> UsageStatistics {
        let records = try await getAllUsage(from: startDate, to: endDate)

        let totalCalls = records.count
        let uniqueUsers = Set(records.map { $0.deviceIdentifier }).count
        let successfulCalls = records.filter { $0.success }.count
        let failedCalls = totalCalls - successfulCalls

        let totalCostINR = costCalculator.calculateTotalCost(from: records, currency: .inr)
        let totalCostUSD = costCalculator.calculateTotalCost(from: records, currency: .usd)
        let averageCostINR = costCalculator.calculateAverageCost(from: records, currency: .inr)

        let totalTokens = records.reduce(0) { $0 + $1.totalTokens }
        let averageTokens = totalCalls > 0 ? totalTokens / totalCalls : 0

        let totalLatencyMs = records.reduce(0) { $0 + $1.latencyMs }
        let averageLatencyMs = totalCalls > 0 ? totalLatencyMs / totalCalls : 0

        return UsageStatistics(
            dateRange: DateInterval(start: startDate, end: endDate),
            totalCalls: totalCalls,
            uniqueUsers: uniqueUsers,
            successfulCalls: successfulCalls,
            failedCalls: failedCalls,
            successRate: totalCalls > 0 ? Double(successfulCalls) / Double(totalCalls) * 100 : 0,
            totalCostINR: totalCostINR,
            totalCostUSD: totalCostUSD,
            averageCostPerCallINR: averageCostINR,
            totalTokens: totalTokens,
            averageTokensPerCall: averageTokens,
            averageLatencyMs: averageLatencyMs
        )
    }

    /// Get cost breakdown by provider
    func getCostBreakdownByProvider(from startDate: Date, to endDate: Date) async throws -> [String: Double] {
        let records = try await getAllUsage(from: startDate, to: endDate)

        var breakdown: [String: Double] = [:]

        for record in records {
            breakdown[record.provider, default: 0] += record.costINR
        }

        return breakdown
    }

    /// Get percentile costs
    func getPercentileCosts(from startDate: Date, to endDate: Date, currency: Currency = .inr) async throws -> PercentileCosts {
        let records = try await getAllUsage(from: startDate, to: endDate)

        let p50 = costCalculator.calculatePercentile(from: records, percentile: 50, currency: currency)
        let p90 = costCalculator.calculatePercentile(from: records, percentile: 90, currency: currency)
        let p99 = costCalculator.calculatePercentile(from: records, percentile: 99, currency: currency)

        return PercentileCosts(p50: p50, p90: p90, p99: p99, currency: currency)
    }

    /// Identify high-usage users (outliers)
    func getHighUsageUsers(from startDate: Date, to endDate: Date, threshold: Int = 10) async throws -> [UserUsageSummary] {
        let records = try await getAllUsage(from: startDate, to: endDate)

        // Group by device identifier
        var userRecords: [String: [LLMUsageRecord]] = [:]
        for record in records {
            userRecords[record.deviceIdentifier, default: []].append(record)
        }

        // Filter users with usage above threshold
        let highUsageUsers = userRecords
            .filter { $0.value.count >= threshold }
            .map { (deviceId, records) in
                let totalCost = costCalculator.calculateTotalCost(from: records, currency: .inr)
                return UserUsageSummary(
                    deviceIdentifier: deviceId,
                    callCount: records.count,
                    totalCostINR: totalCost,
                    successRate: Double(records.filter { $0.success }.count) / Double(records.count) * 100
                )
            }
            .sorted { $0.callCount > $1.callCount }

        return highUsageUsers
    }

    // MARK: - Export

    /// Export usage data to CSV
    func exportToCSV(from startDate: Date, to endDate: Date) async throws -> String {
        let records = try await getAllUsage(from: startDate, to: endDate)

        var csv = "Timestamp,Device ID,Provider,Model,Input Tokens,Output Tokens,Total Tokens,Cost USD,Cost INR,Success,Latency (ms),Error\n"

        for record in records {
            let row = [
                record.formattedTimestamp,
                record.deviceIdentifier,
                record.provider,
                record.model,
                "\(record.inputTokens)",
                "\(record.outputTokens)",
                "\(record.totalTokens)",
                String(format: "%.6f", record.costUSD),
                String(format: "%.4f", record.costINR),
                record.success ? "Yes" : "No",
                "\(record.latencyMs)",
                record.errorMessage ?? ""
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }

    /// Export usage data to JSON
    func exportToJSON(from startDate: Date, to endDate: Date) async throws -> Data {
        let records = try await getAllUsage(from: startDate, to: endDate)

        let exportRecords = records.map { record in
            ExportRecord(
                id: record.id.uuidString,
                timestamp: record.timestamp,
                deviceIdentifier: record.deviceIdentifier,
                provider: record.provider,
                model: record.model,
                inputTokens: record.inputTokens,
                outputTokens: record.outputTokens,
                totalTokens: record.totalTokens,
                costUSD: record.costUSD,
                costINR: record.costINR,
                success: record.success,
                latencyMs: record.latencyMs,
                errorMessage: record.errorMessage
            )
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(exportRecords)
    }
}

// MARK: - Supporting Types

/// Summary statistics for LLM usage
struct UsageStatistics {
    let dateRange: DateInterval
    let totalCalls: Int
    let uniqueUsers: Int
    let successfulCalls: Int
    let failedCalls: Int
    let successRate: Double // Percentage
    let totalCostINR: Double
    let totalCostUSD: Double
    let averageCostPerCallINR: Double
    let totalTokens: Int
    let averageTokensPerCall: Int
    let averageLatencyMs: Int
}

/// Percentile cost breakdown
struct PercentileCosts {
    let p50: Double
    let p90: Double
    let p99: Double
    let currency: Currency
}

/// User usage summary
struct UserUsageSummary {
    let deviceIdentifier: String
    let callCount: Int
    let totalCostINR: Double
    let successRate: Double
}

/// Export record structure
private struct ExportRecord: Codable {
    let id: String
    let timestamp: Date
    let deviceIdentifier: String
    let provider: String
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
    let costUSD: Double
    let costINR: Double
    let success: Bool
    let latencyMs: Int
    let errorMessage: String?
}
