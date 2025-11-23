//
//  LLMSettingsViewModel.swift
//  PayslipMax
//
//  ViewModel for LLM settings UI
//

import Foundation
import Combine
import OSLog

/// Protocol for LLM settings view model
@MainActor
protocol LLMSettingsViewModelProtocol: ObservableObject {
    var isLLMEnabled: Bool { get set }
    var selectedProvider: LLMProvider { get set }
    var useAsBackupOnly: Bool { get set }
    var showPrivacyInfo: Bool { get set }
    var isSaving: Bool { get }

    // Usage Stats
    var callsThisHour: Int { get }
    var callsThisYear: Int { get }
    var maxCallsPerHour: Int { get }
    var maxCallsPerYear: Int { get }
    var remainingCallsYearly: Int { get }
    var usageResetDate: Date? { get }

    func saveSettings() async
    func refreshUsageStats() async
}

/// ViewModel for managing LLM settings
@MainActor
final class LLMSettingsViewModel: LLMSettingsViewModelProtocol {

    // MARK: - Published Properties

    @Published var isLLMEnabled: Bool {
        didSet {
            if isLLMEnabled != oldValue {
                Task { await saveSettings() }
            }
        }
    }

    @Published var selectedProvider: LLMProvider {
        didSet {
            if selectedProvider != oldValue {
                Task { await saveSettings() }
            }
        }
    }

    @Published var useAsBackupOnly: Bool {
        didSet {
            if useAsBackupOnly != oldValue {
                Task { await saveSettings() }
            }
        }
    }

    @Published var showPrivacyInfo: Bool = false
    @Published var isSaving: Bool = false

    // Usage Stats
    @Published var callsThisHour: Int = 0
    @Published var callsThisYear: Int = 0
    @Published var maxCallsPerHour: Int = 5
    @Published var maxCallsPerYear: Int = 50

    var remainingCallsYearly: Int {
        max(0, maxCallsPerYear - callsThisYear)
    }

    var usageResetDate: Date? {
        Calendar.current.date(byAdding: .year, value: 1, to: Date()) // Approximate
    }

    // MARK: - Dependencies

    private let settingsService: LLMSettingsServiceProtocol
    private let rateLimiter: LLMRateLimiterProtocol?
    private let analyticsService: LLMAnalyticsService?
    private let logger = os.Logger(subsystem: "com.payslipmax.settings", category: "LLM")

    // MARK: - Initialization

    init(settingsService: LLMSettingsServiceProtocol,
         rateLimiter: LLMRateLimiterProtocol? = nil,
         analyticsService: LLMAnalyticsService? = nil) {
        self.settingsService = settingsService
        self.rateLimiter = rateLimiter
        self.analyticsService = analyticsService

        // Load initial state from service
        self.isLLMEnabled = settingsService.isLLMEnabled
        self.selectedProvider = settingsService.selectedProvider
        self.useAsBackupOnly = settingsService.useAsBackupOnly

        // Load usage stats
        Task { await refreshUsageStats() }

        logger.info("LLMSettingsViewModel initialized with centralized API keys")
    }

    // MARK: - Public Methods

    func saveSettings() async {
        isSaving = true
        defer { isSaving = false }

        // Save boolean settings (immediate)
        settingsService.isLLMEnabled = isLLMEnabled
        settingsService.selectedProvider = selectedProvider
        settingsService.useAsBackupOnly = useAsBackupOnly

        logger.info("Settings saved")
    }

    func refreshUsageStats() async {
        guard let rateLimiter = rateLimiter else { return }

        self.callsThisHour = await rateLimiter.getHourlyCallCount()
        self.callsThisYear = await rateLimiter.getYearlyCallCount()

        // Get limits from configuration if available
        // Note: We're using the protocol, so we might need to cast or assume defaults
        // For now, we'll use the defaults in the properties, but ideally we'd fetch them
        if let limiter = rateLimiter as? LLMRateLimiter {
            let config = limiter.getCurrentConfiguration()
            self.maxCallsPerHour = config.maxCallsPerHour
            self.maxCallsPerYear = config.maxCallsPerYear
        }
    }
}
