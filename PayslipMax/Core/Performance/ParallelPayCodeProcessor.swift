//
//  ParallelPayCodeProcessor.swift
//  PayslipMax
//
//  Created for Phase 6: Performance Optimization
//  Handles parallel processing of pay codes for optimal performance
//

import Foundation

/// Protocol for parallel pay code processing operations
protocol ParallelPayCodeProcessorProtocol {
    /// Processes guaranteed single-section codes in parallel
    /// - Parameters:
    ///   - codes: Array of guaranteed pay codes to process
    ///   - text: The payslip text to search in
    ///   - searchFunction: Function to search for individual pay codes
    /// - Returns: Dictionary of search results
    func processGuaranteedCodesInParallel(
        _ codes: [String],
        text: String,
        searchFunction: @escaping (String, String) async -> [PayCodeSearchResult]?
    ) async -> [String: PayCodeSearchResult]

    /// Processes universal dual-section codes in parallel
    /// - Parameters:
    ///   - codes: Array of universal dual-section pay codes to process
    ///   - text: The payslip text to search in
    ///   - searchFunction: Function to search for individual pay codes
    /// - Returns: Dictionary of search results with section-specific keys
    func processUniversalCodesInParallel(
        _ codes: [String],
        text: String,
        searchFunction: @escaping (String, String) async -> [PayCodeSearchResult]?
    ) async -> [String: PayCodeSearchResult]

    /// Partitions pay codes by classification for optimized processing
    /// - Parameters:
    ///   - payCodes: Array of pay codes to partition
    ///   - classificationFunction: Function to classify pay codes
    /// - Returns: Tuple with guaranteed and universal codes
    func partitionPayCodesByClassification(
        _ payCodes: [String],
        classificationFunction: (String) -> ComponentClassification
    ) -> (guaranteed: [String], universal: [String])
}

/// Parallel processor for pay code search operations
/// Optimizes performance through concurrent processing and TaskGroup management
final class ParallelPayCodeProcessor: ParallelPayCodeProcessorProtocol {

    // MARK: - Properties

    /// Maximum concurrent tasks to prevent resource exhaustion
    private let maxConcurrentTasks: Int = 20

    // MARK: - Public Methods

    /// Processes guaranteed single-section codes in parallel for optimal performance
    func processGuaranteedCodesInParallel(
        _ codes: [String],
        text: String,
        searchFunction: @escaping (String, String) async -> [PayCodeSearchResult]?
    ) async -> [String: PayCodeSearchResult] {

        return await withTaskGroup(of: (String, PayCodeSearchResult)?.self) { group in
            var results: [String: PayCodeSearchResult] = [:]
            var taskCount = 0

            // Add tasks for each guaranteed code with concurrency limit
            for payCode in codes {
                guard taskCount < maxConcurrentTasks else { break }

                group.addTask {
                    if let searchResults = await searchFunction(payCode, text),
                       let singleResult = searchResults.first {
                        return (payCode, singleResult)
                    }
                    return nil
                }

                taskCount += 1
            }

            // Collect results as they complete
            for await result in group {
                if let (code, searchResult) = result {
                    results[code] = searchResult
                    print("[ParallelPayCodeProcessor] Guaranteed: \(code) = ₹\(searchResult.value) (\(searchResult.section))")
                }
            }

            // Process remaining codes if any exceeded concurrency limit
            if codes.count > maxConcurrentTasks {
                let remainingCodes = Array(codes.dropFirst(maxConcurrentTasks))
                let remainingResults = await processGuaranteedCodesInParallel(
                    remainingCodes,
                    text: text,
                    searchFunction: searchFunction
                )
                results.merge(remainingResults) { _, new in new }
            }

            return results
        }
    }

    /// Processes universal dual-section codes in parallel with section-specific handling
    func processUniversalCodesInParallel(
        _ codes: [String],
        text: String,
        searchFunction: @escaping (String, String) async -> [PayCodeSearchResult]?
    ) async -> [String: PayCodeSearchResult] {

        return await withTaskGroup(of: (String, [PayCodeSearchResult])?.self) { group in
            var results: [String: PayCodeSearchResult] = [:]
            var taskCount = 0

            // Add tasks for each universal dual-section code with concurrency limit
            for payCode in codes {
                guard taskCount < maxConcurrentTasks else { break }

                group.addTask {
                    if let searchResults = await searchFunction(payCode, text) {
                        return (payCode, searchResults)
                    }
                    return nil
                }

                taskCount += 1
            }

            // Collect and process results as they complete
            for await result in group {
                if let (payCode, searchResults) = result {
                    let processedResults = processDualSectionResults(payCode: payCode, searchResults: searchResults)
                    results.merge(processedResults) { _, new in new }
                }
            }

            // Process remaining codes if any exceeded concurrency limit
            if codes.count > maxConcurrentTasks {
                let remainingCodes = Array(codes.dropFirst(maxConcurrentTasks))
                let remainingResults = await processUniversalCodesInParallel(
                    remainingCodes,
                    text: text,
                    searchFunction: searchFunction
                )
                results.merge(remainingResults) { _, new in new }
            }

            return results
        }
    }

    /// Partitions pay codes by their classification for optimized processing
    func partitionPayCodesByClassification(
        _ payCodes: [String],
        classificationFunction: (String) -> ComponentClassification
    ) -> (guaranteed: [String], universal: [String]) {

        var guaranteedCodes: [String] = []
        var universalCodes: [String] = []

        for payCode in payCodes {
            let classification = classificationFunction(payCode)
            switch classification {
            case .guaranteedEarnings, .guaranteedDeductions:
                guaranteedCodes.append(payCode)
            case .universalDualSection:
                universalCodes.append(payCode)
            }
        }

        print("[ParallelPayCodeProcessor] Partitioned \(payCodes.count) codes: \(guaranteedCodes.count) guaranteed, \(universalCodes.count) universal")
        return (guaranteedCodes, universalCodes)
    }

    // MARK: - Private Methods

    /// Processes dual-section search results into section-specific keys
    private func processDualSectionResults(
        payCode: String,
        searchResults: [PayCodeSearchResult]
    ) -> [String: PayCodeSearchResult] {

        var results: [String: PayCodeSearchResult] = [:]

        if searchResults.count > 1 {
            // Multiple instances found - store with section-specific keys
            var earningsCount = 0
            var deductionsCount = 0

            for searchResult in searchResults {
                let sectionKey: String
                if searchResult.section == .earnings {
                    earningsCount += 1
                    sectionKey = earningsCount == 1 ? "\(payCode)_EARNINGS" : "\(payCode)_EARNINGS_\(earningsCount)"
                } else {
                    deductionsCount += 1
                    sectionKey = deductionsCount == 1 ? "\(payCode)_DEDUCTIONS" : "\(payCode)_DEDUCTIONS_\(deductionsCount)"
                }

                results[sectionKey] = searchResult
                print("[ParallelPayCodeProcessor] Universal: \(sectionKey) = ₹\(searchResult.value)")
            }
        } else if let singleResult = searchResults.first {
            // Single instance - still use section-specific key for consistency
            let sectionKey = singleResult.section == .earnings ? "\(payCode)_EARNINGS" : "\(payCode)_DEDUCTIONS"
            results[sectionKey] = singleResult
            print("[ParallelPayCodeProcessor] Universal single: \(sectionKey) = ₹\(singleResult.value)")
        }

        return results
    }
}

// MARK: - Shared Instance

extension ParallelPayCodeProcessor {
    /// Shared parallel processor instance
    static let shared = ParallelPayCodeProcessor()
}
