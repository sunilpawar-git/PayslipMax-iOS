//
//  LLMResponseCache.swift
//  PayslipMax
//
//  Cache for LLM parsing responses to avoid redundant API calls
//

import Foundation
import UIKit
import CryptoKit

/// Cached LLM parse result
struct CachedParseResult {
    let payslipItem: PayslipItem
    let confidence: Double
    let timestamp: Date

    /// Check if cache entry is still valid
    /// - Parameter ttl: Time-to-live in seconds (default: 1 hour)
    /// - Returns: true if cache is still valid
    func isValid(ttl: TimeInterval = 3600) -> Bool {
        return Date().timeIntervalSince(timestamp) < ttl
    }
}

/// Thread-safe cache for LLM parsing responses
final class LLMResponseCache {
    // MARK: - Singleton

    static let shared = LLMResponseCache()

    // MARK: - Properties

    private let cache = NSCache<NSString, CachedResultWrapper>()
    private let queue = DispatchQueue(label: "com.payslipmax.llm.cache", attributes: .concurrent)

    // MARK: - Configuration

    /// Maximum number of cached items (default: 20)
    var countLimit: Int {
        get { cache.countLimit }
        set { cache.countLimit = newValue }
    }

    /// Maximum total cost in bytes (default: 10MB)
    var totalCostLimit: Int {
        get { cache.totalCostLimit }
        set { cache.totalCostLimit = newValue }
    }

    // MARK: - Initialization

    private init() {
        cache.countLimit = 20
        cache.totalCostLimit = 10 * 1024 * 1024  // 10MB
    }

    // MARK: - Public API

    /// Get cached result for an image
    /// - Parameter image: The payslip image
    /// - Returns: Cached result if available and valid, nil otherwise
    func get(for image: UIImage) -> CachedParseResult? {
        guard let hash = imageHash(for: image) else { return nil }

        return queue.sync {
            guard let wrapper = cache.object(forKey: hash as NSString) else { return nil }
            let result = wrapper.result

            // Check if cache is still valid (1 hour TTL)
            guard result.isValid() else {
                cache.removeObject(forKey: hash as NSString)
                return nil
            }

            return result
        }
    }

    /// Store a parse result in cache
    /// - Parameters:
    ///   - result: The payslip item to cache
    ///   - confidence: The confidence score
    ///   - image: The source image
    func set(result: PayslipItem, confidence: Double, for image: UIImage) {
        guard let hash = imageHash(for: image) else { return }

        let cachedResult = CachedParseResult(
            payslipItem: result,
            confidence: confidence,
            timestamp: Date()
        )

        let wrapper = CachedResultWrapper(result: cachedResult)

        queue.async(flags: .barrier) {
            // Estimate cost based on earnings/deductions count
            let cost = (result.earnings.count + result.deductions.count) * 100
            self.cache.setObject(wrapper, forKey: hash as NSString, cost: cost)
        }
    }

    /// Clear all cached results
    func clearAll() {
        queue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
    }

    // MARK: - Private Methods

    /// Generate SHA256 hash for an image
    /// - Parameter image: The image to hash
    /// - Returns: Hex string hash, or nil if hashing fails
    private func imageHash(for image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Wrapper Class

/// Wrapper to make CachedParseResult compatible with NSCache
private final class CachedResultWrapper {
    let result: CachedParseResult

    init(result: CachedParseResult) {
        self.result = result
    }
}

