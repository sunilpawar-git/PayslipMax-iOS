//
//  PayslipCacheManager.swift
//  PayslipMax
//
//  Created for performance optimization - eliminates redundant data loading
//  Implements smart caching with automatic invalidation
//

import Foundation
import Combine

/// Manages cached payslip data to eliminate redundant loading operations
/// Provides automatic cache invalidation and refresh mechanisms
@MainActor
final class PayslipCacheManager: ObservableObject {

    // MARK: - Published Properties

    /// Cached payslip items
    @Published private(set) var cachedPayslips: [PayslipItem] = []

    /// Indicates whether cache has been loaded
    @Published private(set) var isLoaded = false

    /// Last cache load timestamp
    @Published private(set) var lastLoadTime: Date?

    // MARK: - Private Properties

    /// Data handler for payslip operations
    private var dataHandler: PayslipDataHandler

    /// Cache validity duration (5 minutes)
    private let cacheValidityDuration: TimeInterval = 300

    /// Cache invalidation timer
    private var cacheInvalidationTimer: Timer?

    /// Subscribers for cleanup
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initializes a PayslipCacheManager with the specified data handler
    /// - Parameter dataHandler: The data handler to use for loading payslips
    init(dataHandler: PayslipDataHandler? = nil) {
        self.dataHandler = dataHandler ?? DIContainer.shared.makePayslipDataHandler()

        // Start auto-invalidation timer
        startCacheInvalidationTimer()

        if !ProcessInfo.isRunningInTestEnvironment {
            print("[PayslipCacheManager] Initialized with \(cacheValidityDuration)s cache validity")
        }
    }

    deinit {
        cacheInvalidationTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Loads payslips if cache is invalid or not loaded
    /// Returns cached data if still valid
    /// - Returns: Array of PayslipItems
    func loadPayslipsIfNeeded() async throws -> [PayslipItem] {
        // Check cache validity
        if isCacheValid() {
            if !ProcessInfo.isRunningInTestEnvironment {
                print("[PayslipCacheManager] Returning cached payslips (\(cachedPayslips.count) items)")
            }
            return cachedPayslips
        }

        // Load fresh data
        return try await loadPayslips()
    }

    /// Forces a fresh load, bypassing cache
    /// - Returns: Array of PayslipItems
    func loadPayslips() async throws -> [PayslipItem] {
        if !ProcessInfo.isRunningInTestEnvironment {
            print("[PayslipCacheManager] Loading fresh payslips...")
        }

        let startTime = Date()
        let payslips = try await dataHandler.loadRecentPayslips()
        let loadDuration = Date().timeIntervalSince(startTime)

        // Update cache
        cachedPayslips = payslips
        isLoaded = true
        lastLoadTime = Date()

        if !ProcessInfo.isRunningInTestEnvironment {
            print("[PayslipCacheManager] Cached \(payslips.count) payslips in \(String(format: "%.2f", loadDuration * 1000))ms")
        }

        return payslips
    }

    /// Invalidates cache, forcing next load to be fresh
    func invalidateCache() {
        if !ProcessInfo.isRunningInTestEnvironment {
            print("[PayslipCacheManager] Cache invalidated")
        }

        isLoaded = false
        lastLoadTime = nil
        cachedPayslips = []
    }

    /// Adds a payslip to cache and invalidates for fresh load
    /// - Parameter payslip: The PayslipItem to add
    func addPayslipToCache(_ payslip: PayslipItem) {
        // Invalidate cache to force fresh load
        invalidateCache()

        if !ProcessInfo.isRunningInTestEnvironment {
            print("[PayslipCacheManager] Payslip added, cache invalidated")
        }
    }

    /// Removes a payslip from cache and invalidates for fresh load
    /// - Parameter payslipId: The ID of the payslip to remove
    func removePayslipFromCache(withId payslipId: UUID) {
        // Invalidate cache to force fresh load
        invalidateCache()

        if !ProcessInfo.isRunningInTestEnvironment {
            print("[PayslipCacheManager] Payslip removed, cache invalidated")
        }
    }

    /// Updates a payslip in cache and invalidates for fresh load
    /// - Parameter payslip: The updated PayslipItem
    func updatePayslipInCache(_ payslip: PayslipItem) {
        // Invalidate cache to force fresh load
        invalidateCache()

        if !ProcessInfo.isRunningInTestEnvironment {
            print("[PayslipCacheManager] Payslip updated, cache invalidated")
        }
    }

    // MARK: - Private Methods

    /// Checks if cache is still valid
    /// - Returns: True if cache is valid and should be used
    private func isCacheValid() -> Bool {
        guard isLoaded, let lastLoad = lastLoadTime else {
            return false
        }

        let elapsed = Date().timeIntervalSince(lastLoad)
        return elapsed < cacheValidityDuration
    }

    /// Starts automatic cache invalidation timer
    private func startCacheInvalidationTimer() {
        // Invalidate cache every 5 minutes to catch external changes
        cacheInvalidationTimer = Timer.scheduledTimer(
            withTimeInterval: cacheValidityDuration,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                self.invalidateCache()
            }
        }
    }
}

