import SwiftUI
import SwiftData
import Foundation
import Combine

@MainActor
final class PayslipsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var searchText = "" {
        didSet {
            updateGroupedData()
        }
    }
    @Published var sortOrder: PayslipSortOrder = .dateDescending {
        didSet {
            updateGroupedData()
        }
    }
    @Published var payslips: [AnyPayslip] = []
    @Published var selectedPayslip: AnyPayslip?
    @Published var showShareSheet = false
    @Published var shareText = ""

    // MARK: - Processed Data
    @Published var groupedPayslips: [String: [AnyPayslip]] = [:]
    @Published var sortedSectionKeys: [String] = []

    // MARK: - X-Ray Comparison Data
    @Published var comparisonResults: [UUID: PayslipComparison] = [:]

    // MARK: - Services
    let repository: SendablePayslipRepository
    let cacheManager: PayslipCacheManager
    let filteringService: PayslipFilteringService
    let sortingService: PayslipSortingService
    let groupingService: PayslipGroupingService
    let comparisonService: PayslipComparisonServiceProtocol
    let xRaySettings: any XRaySettingsServiceProtocol

    // MARK: - Combine
    private var xRayToggleCancellable: AnyCancellable?

    // MARK: - Initialization

    /// Initializes a new PayslipsViewModel with the specified services.
    ///
    /// - Parameters:
    ///   - repository: The repository to use for fetching and managing payslips.
    ///   - cacheManager: The cache manager for managing payslip caching.
    ///   - comparisonService: The service for comparing payslips (optional, defaults to DI container)
    ///   - xRaySettings: The X-Ray settings service (optional, defaults to DI container)
    init(
        repository: SendablePayslipRepository? = nil,
        cacheManager: PayslipCacheManager? = nil,
        comparisonService: PayslipComparisonServiceProtocol? = nil,
        xRaySettings: (any XRaySettingsServiceProtocol)? = nil
    ) {
        self.repository = repository ?? DIContainer.shared.makeSendablePayslipRepository()
        self.cacheManager = cacheManager ?? DIContainer.shared.makePayslipCacheManager()
        self.filteringService = PayslipFilteringService()
        self.sortingService = PayslipSortingService()
        self.groupingService = PayslipGroupingService()

        // X-Ray services
        let featureContainer = DIContainer.shared.featureContainerPublic
        self.comparisonService = comparisonService ?? featureContainer.makePayslipComparisonService()
        self.xRaySettings = xRaySettings ?? featureContainer.makeXRaySettingsService()

        // Register for notifications
        setupNotificationHandlers()

        // Subscribe to X-Ray toggle changes
        setupXRaySubscription()
    }

    deinit {
        // Clean up notification observers
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Data Processing

    /// Updates the grouped data based on current filters and sort order
    func updateGroupedData() {
        let filtered = filterPayslips(payslips)
        let grouped = groupingService.groupByMonthYear(filtered)
        let sortedKeys = groupingService.createSortedSectionKeys(from: grouped)

        self.groupedPayslips = grouped
        self.sortedSectionKeys = sortedKeys
    }

    // MARK: - X-Ray Comparison

    /// Sets up subscription to X-Ray toggle changes
    private func setupXRaySubscription() {
        xRayToggleCancellable = xRaySettings.xRayEnabledPublisher
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.computeComparisons()
                }
            }
    }

    /// Computes payslip comparisons for X-Ray feature
    func computeComparisons() {
        guard xRaySettings.isXRayEnabled else {
            // Clear comparisons if X-Ray is disabled
            comparisonResults.removeAll()
            return
        }

        for payslip in payslips {
            // Check cache first
            if let cached = PayslipComparisonCacheManager.shared.getComparison(for: payslip.id) {
                comparisonResults[payslip.id] = cached
                continue
            }

            // Compute and cache
            let previous = comparisonService.findPreviousPayslip(for: payslip, in: payslips)
            let comparison = comparisonService.comparePayslips(current: payslip, previous: previous)
            comparisonResults[payslip.id] = comparison
            PayslipComparisonCacheManager.shared.setComparison(comparison, for: payslip.id)
        }
    }
}

// MARK: - Model Context Protocol

/// A protocol for model contexts.
