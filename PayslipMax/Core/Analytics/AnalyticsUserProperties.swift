import Foundation

/// Provides standardized user property names to ensure consistency
struct AnalyticsUserProperties {
    // MARK: - User Identification
    
    /// User ID (anonymized)
    static let userID = "user_id"
    
    /// Account creation date
    static let accountCreatedDate = "account_created_date"
    
    // MARK: - App Information
    
    /// App version
    static let appVersion = "app_version"
    
    /// Device type
    static let deviceType = "device_type"
    
    /// Operating system version
    static let osVersion = "os_version"
    
    // MARK: - User Preferences
    
    /// Theme preference (light/dark/system)
    static let themePreference = "theme_preference"
    
    /// Biometric authentication enabled
    static let biometricAuthEnabled = "biometric_auth_enabled"
    
    /// Export format preference
    static let exportFormatPreference = "export_format_preference"
    
    // MARK: - Usage Metrics
    
    /// Number of payslips imported
    static let payslipCount = "payslip_count"
    
    /// Latest payslip date
    static let latestPayslipDate = "latest_payslip_date"
    
    /// Parser success rate
    static let parserSuccessRate = "parser_success_rate"
    
    /// Days since last use
    static let daysSinceLastUse = "days_since_last_use"
    
    // MARK: - Feature Adoption
    
    /// Features used
    static let featuresUsed = "features_used"
    
    /// Feature flags enabled
    static let featureFlagsEnabled = "feature_flags_enabled"
    
    // MARK: - Payslip Types
    
    /// Has military payslips
    static let hasMilitaryPayslips = "has_military_payslips"
    
    /// Has PCDA payslips
    static let hasPCDAPayslips = "has_pcda_payslips"
} 