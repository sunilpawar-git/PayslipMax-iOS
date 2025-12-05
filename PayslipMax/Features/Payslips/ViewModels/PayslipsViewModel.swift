import SwiftUI
import SwiftData
import Foundation

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

    // MARK: - Services
    let repository: SendablePayslipRepository
    let cacheManager: PayslipCacheManager
    let filteringService: PayslipFilteringService
    let sortingService: PayslipSortingService
    let groupingService: PayslipGroupingService

    // MARK: - Initialization

    /// Initializes a new PayslipsViewModel with the specified services.
    ///
    /// - Parameters:
    ///   - repository: The repository to use for fetching and managing payslips.
    ///   - cacheManager: The cache manager for managing payslip caching.
    init(repository: SendablePayslipRepository? = nil, cacheManager: PayslipCacheManager? = nil) {
        self.repository = repository ?? DIContainer.shared.makeSendablePayslipRepository()
        self.cacheManager = cacheManager ?? DIContainer.shared.makePayslipCacheManager()
        self.filteringService = PayslipFilteringService()
        self.sortingService = PayslipSortingService()
        self.groupingService = PayslipGroupingService()

        // Register for notifications
        setupNotificationHandlers()
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
}

// MARK: - Model Context Protocol

/// A protocol for model contexts.
