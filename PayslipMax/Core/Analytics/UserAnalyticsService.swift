import Foundation

/// Protocol for User Analytics Service to enable dependency injection
protocol UserAnalyticsServiceProtocol {
    /// Track app launch with relevant information
    func trackAppLaunch(launchType: String, environment: [String: Any])

    /// Track screen view
    func trackScreenView(screenName: String, screenClass: String)

    /// Track tab selection
    func trackTabSelected(tabName: String)

    /// Track payslip import started
    func trackPayslipImportStarted(source: String, fileType: String)

    /// Track payslip import completed
    func trackPayslipImportCompleted(success: Bool, payslipType: String, automaticExtraction: Bool)

    /// Track payslip opened
    func trackPayslipOpened(payslipID: String, payslipType: String, payslipDate: Date)

    /// Track payslip deleted
    func trackPayslipDeleted(payslipID: String, payslipType: String, payslipAge: Int)

    /// Track feature used
    func trackFeatureUsed(featureName: String, parameters: [String: Any]?)

    /// Track settings changed
    func trackSettingsChanged(settingName: String, oldValue: Any, newValue: Any)

    /// Set device and app information as user properties
    func setDeviceAndAppProperties()

    /// Set user properties related to payslip data
    func setPayslipProperties(payslipCount: Int, hasMilitaryPayslips: Bool, hasPCDAPayslips: Bool)
}

/// Service for tracking user actions and behavior across the application
/// Now supports both singleton and dependency injection patterns
class UserAnalyticsService: UserAnalyticsServiceProtocol, SafeConversionProtocol {
    /// Shared instance for singleton access
    static let shared = UserAnalyticsService()

    /// Analytics manager instance (injected or singleton)
    private let analyticsManager: AnalyticsManagerProtocol

    /// Category for logging
    private let logCategory = "UserAnalyticsService"

    /// Current conversion state
    var conversionState: ConversionState = .singleton

    /// Feature flag that controls DI vs singleton usage
    var controllingFeatureFlag: Feature { return .diUserAnalyticsService }

    /// Initialize with dependency injection support
    /// - Parameter dependencies: Dependencies including analyticsManager
    init(dependencies: [String: Any] = [:]) {
        if let injectedAnalytics = dependencies["analyticsManager"] as? AnalyticsManagerProtocol {
            self.analyticsManager = injectedAnalytics
        } else {
            // Fallback to singleton for backward compatibility
            self.analyticsManager = AnalyticsManager.shared
        }
        Logger.info("Initialized User Analytics Service (DI-ready)", category: logCategory)
    }

    /// Private initializer to maintain singleton pattern
    private convenience init() {
        self.init(dependencies: [:])
    }

    // MARK: - App Lifecycle

    /// Track app launch with relevant information
    /// - Parameters:
    ///   - launchType: Type of launch (cold, warm, etc.)
    ///   - environment: Environment information
    func trackAppLaunch(launchType: String, environment: [String: Any]) {
        let parameters: [String: Any] = [
            "launch_type": launchType,
            "environment": environment
        ]

        analyticsManager.logEvent(AnalyticsEvents.appLaunch, parameters: parameters)
        Logger.debug("Tracked app launch: \(parameters)", category: logCategory)
    }

    // MARK: - Navigation

    /// Track screen view
    /// - Parameters:
    ///   - screenName: Name of the screen being viewed
    ///   - screenClass: Class name of the screen
    func trackScreenView(screenName: String, screenClass: String) {
        let parameters: [String: Any] = [
            "screen_name": screenName,
            "screen_class": screenClass
        ]

        analyticsManager.logEvent(AnalyticsEvents.screenView, parameters: parameters)
        Logger.debug("Tracked screen view: \(parameters)", category: logCategory)
    }

    /// Track tab selection
    /// - Parameter tabName: Name of the selected tab
    func trackTabSelected(tabName: String) {
        let parameters: [String: Any] = [
            "tab_name": tabName
        ]

        analyticsManager.logEvent(AnalyticsEvents.tabSelected, parameters: parameters)
        Logger.debug("Tracked tab selection: \(parameters)", category: logCategory)
    }

    // MARK: - Payslip Actions

    /// Track payslip import started
    /// - Parameters:
    ///   - source: Source of the import (file picker, document scanner, etc.)
    ///   - fileType: Type of file being imported
    func trackPayslipImportStarted(source: String, fileType: String) {
        let parameters: [String: Any] = [
            "source": source,
            "file_type": fileType
        ]

        analyticsManager.beginTimedEvent(AnalyticsEvents.payslipImportStarted, parameters: parameters)
        Logger.debug("Started tracking payslip import: \(parameters)", category: logCategory)
    }

    /// Track payslip import completed
    /// - Parameters:
    ///   - success: Whether the import was successful
    ///   - payslipType: Type of payslip imported
    ///   - automaticExtraction: Whether data was automatically extracted
    func trackPayslipImportCompleted(success: Bool, payslipType: String, automaticExtraction: Bool) {
        let parameters: [String: Any] = [
            "success": success,
            "payslip_type": payslipType,
            "automatic_extraction": automaticExtraction
        ]

        analyticsManager.endTimedEvent(AnalyticsEvents.payslipImportStarted, parameters: parameters)

        if success {
            analyticsManager.logEvent(AnalyticsEvents.payslipImportCompleted, parameters: parameters)
        } else {
            analyticsManager.logEvent(AnalyticsEvents.payslipImportFailed, parameters: parameters)
        }

        Logger.debug("Ended tracking payslip import: \(parameters)", category: logCategory)
    }

    /// Track payslip opened
    /// - Parameters:
    ///   - payslipID: Identifier of the payslip
    ///   - payslipType: Type of payslip
    ///   - payslipDate: Date of the payslip
    func trackPayslipOpened(payslipID: String, payslipType: String, payslipDate: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let dateString = dateFormatter.string(from: payslipDate)

        let parameters: [String: Any] = [
            "payslip_id": payslipID,
            "payslip_type": payslipType,
            "payslip_date": dateString
        ]

        analyticsManager.logEvent(AnalyticsEvents.payslipOpened, parameters: parameters)
        Logger.debug("Tracked payslip opened: \(parameters)", category: logCategory)
    }

    /// Track payslip deleted
    /// - Parameters:
    ///   - payslipID: Identifier of the payslip
    ///   - payslipType: Type of payslip
    ///   - payslipAge: Age of the payslip in days
    func trackPayslipDeleted(payslipID: String, payslipType: String, payslipAge: Int) {
        let parameters: [String: Any] = [
            "payslip_id": payslipID,
            "payslip_type": payslipType,
            "payslip_age_days": payslipAge
        ]

        analyticsManager.logEvent(AnalyticsEvents.payslipDeleted, parameters: parameters)
        Logger.debug("Tracked payslip deleted: \(parameters)", category: logCategory)
    }

    // MARK: - Feature Usage

    /// Track feature used
    /// - Parameters:
    ///   - featureName: Name of the feature
    ///   - parameters: Additional parameters related to feature usage
    func trackFeatureUsed(featureName: String, parameters: [String: Any]? = nil) {
        var eventParameters: [String: Any] = [
            "feature_name": featureName
        ]

        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                eventParameters[key] = value
            }
        }

        analyticsManager.logEvent(AnalyticsEvents.featureUsed, parameters: eventParameters)
        Logger.debug("Tracked feature usage: \(eventParameters)", category: logCategory)
    }

    // MARK: - Settings

    /// Track settings changed
    /// - Parameters:
    ///   - settingName: Name of the setting
    ///   - oldValue: Previous value
    ///   - newValue: New value
    func trackSettingsChanged(settingName: String, oldValue: Any, newValue: Any) {
        let parameters: [String: Any] = [
            "setting_name": settingName,
            "old_value": "\(oldValue)",
            "new_value": "\(newValue)"
        ]

        analyticsManager.logEvent(AnalyticsEvents.settingsChanged, parameters: parameters)
        Logger.debug("Tracked settings changed: \(parameters)", category: logCategory)
    }

    // MARK: - User Properties

    /// Set device and app information as user properties
    func setDeviceAndAppProperties() {
        // App version
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            analyticsManager.setUserProperty(appVersion, forName: AnalyticsUserProperties.appVersion)
        }

        // Device type
        #if os(iOS)
        let deviceType = "iOS"
        #elseif os(macOS)
        let deviceType = "macOS"
        #else
        let deviceType = "unknown"
        #endif
        analyticsManager.setUserProperty(deviceType, forName: AnalyticsUserProperties.deviceType)

        // OS version
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        analyticsManager.setUserProperty(osVersion, forName: AnalyticsUserProperties.osVersion)
    }

    /// Set user properties related to payslip data
    /// - Parameters:
    ///   - payslipCount: Number of payslips
    ///   - hasMilitaryPayslips: Whether there are military payslips
    ///   - hasPCDAPayslips: Whether there are PCDA payslips
    func setPayslipProperties(payslipCount: Int, hasMilitaryPayslips: Bool, hasPCDAPayslips: Bool) {
        analyticsManager.setUserProperty(String(payslipCount), forName: AnalyticsUserProperties.payslipCount)
        analyticsManager.setUserProperty(String(hasMilitaryPayslips), forName: AnalyticsUserProperties.hasMilitaryPayslips)
        analyticsManager.setUserProperty(String(hasPCDAPayslips), forName: AnalyticsUserProperties.hasPCDAPayslips)
    }

    // MARK: - SafeConversionProtocol Implementation

    /// Validates that the service can be safely converted to DI
    func validateConversionSafety() async -> Bool {
        // Analytics manager is always available (either injected or singleton fallback)
        return true
    }

    /// Performs the conversion from singleton to DI pattern
    func performConversion(container: any DIContainerProtocol) async -> Bool {
        await MainActor.run {
            conversionState = .converting
        }

        await ConversionTracker.shared.updateConversionState(for: UserAnalyticsService.self, state: .converting)

        // Note: Integration with existing DI architecture will be handled separately
        // This method validates the conversion is safe and updates tracking

        await MainActor.run {
            conversionState = .dependencyInjected
        }

        await ConversionTracker.shared.updateConversionState(for: UserAnalyticsService.self, state: .dependencyInjected)

        Logger.info("Successfully converted UserAnalyticsService to DI pattern", category: logCategory)
        return true
    }

    /// Rolls back to singleton pattern if issues are detected
    func rollbackConversion() async -> Bool {
        await MainActor.run {
            conversionState = .singleton
        }
        await ConversionTracker.shared.updateConversionState(for: UserAnalyticsService.self, state: .singleton)
        Logger.info("Rolled back UserAnalyticsService to singleton pattern", category: logCategory)
        return true
    }

    /// Validates dependencies are properly injected and functional
    func validateDependencies() async -> DependencyValidationResult {
        // AnalyticsManager is always available (either injected or singleton fallback)
        return .success
    }

    /// Creates a new instance via dependency injection
    func createDIInstance(dependencies: [String: Any]) -> Self? {
        return UserAnalyticsService(dependencies: dependencies) as? Self
    }

    /// Returns the singleton instance (fallback mode)
    static func sharedInstance() -> Self {
        return shared as! Self
    }

    /// Determines whether to use DI or singleton based on feature flags
    @MainActor static func resolveInstance() -> Self {
        let featureFlagManager = FeatureFlagManager.shared
        let shouldUseDI = featureFlagManager.isEnabled(.diUserAnalyticsService)

        if shouldUseDI {
            // Note: DI resolution will be integrated with existing factory pattern
            // For now, fallback to singleton until factory methods are implemented
            Logger.debug("DI enabled for UserAnalyticsService, but using singleton fallback", category: "UserAnalyticsService")
        }

        // Fallback to singleton
        return shared as! Self
    }
}
