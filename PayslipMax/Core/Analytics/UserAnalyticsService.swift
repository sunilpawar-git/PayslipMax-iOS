import Foundation

/// Service for tracking user actions and behavior across the application
class UserAnalyticsService {
    /// Shared instance for singleton access
    static let shared = UserAnalyticsService()
    
    /// Analytics manager instance
    private let analyticsManager = AnalyticsManager.shared
    
    /// Category for logging
    private let logCategory = "UserAnalyticsService"
    
    /// Private initializer to enforce singleton pattern
    private init() {
        Logger.info("Initialized User Analytics Service", category: logCategory)
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
} 