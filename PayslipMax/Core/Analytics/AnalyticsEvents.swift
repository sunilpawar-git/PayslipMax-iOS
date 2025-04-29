import Foundation

/// Provides standardized analytics event names to ensure consistency
struct AnalyticsEvents {
    // MARK: - App Lifecycle Events
    
    /// App launch completed
    static let appLaunch = "app_launch"
    
    /// App entered foreground
    static let appForeground = "app_foreground"
    
    /// App entered background
    static let appBackground = "app_background"
    
    /// User signed in
    static let userSignIn = "user_sign_in"
    
    /// User signed out
    static let userSignOut = "user_sign_out"
    
    // MARK: - Navigation Events
    
    /// Screen view
    static let screenView = "screen_view"
    
    /// Tab selected
    static let tabSelected = "tab_selected"
    
    // MARK: - Payslip Events
    
    /// Payslip import started
    static let payslipImportStarted = "payslip_import_started"
    
    /// Payslip import completed
    static let payslipImportCompleted = "payslip_import_completed"
    
    /// Payslip import failed
    static let payslipImportFailed = "payslip_import_failed"
    
    /// Payslip opened
    static let payslipOpened = "payslip_opened"
    
    /// Payslip deleted
    static let payslipDeleted = "payslip_deleted"
    
    // MARK: - PDF Processing Events
    
    /// PDF processing started
    static let pdfProcessingStarted = "pdf_processing_started"
    
    /// PDF processing completed
    static let pdfProcessingCompleted = "pdf_processing_completed"
    
    /// PDF processing failed
    static let pdfProcessingFailed = "pdf_processing_failed"
    
    // MARK: - Parser Events
    
    /// Parser selection
    static let parserSelected = "parser_selected"
    
    /// Parser execution
    static let parserExecution = "parser_execution"
    
    /// Parser success
    static let parserSuccess = "parser_success"
    
    /// Parser failure
    static let parserFailure = "parser_failure"
    
    // MARK: - Feature Usage Events
    
    /// Feature flag enabled
    static let featureFlagEnabled = "feature_flag_enabled"
    
    /// Feature flag disabled
    static let featureFlagDisabled = "feature_flag_disabled"
    
    /// Feature used
    static let featureUsed = "feature_used"
    
    // MARK: - Performance Events
    
    /// Memory warning received
    static let memoryWarning = "memory_warning"
    
    /// Slow operation detected
    static let slowOperation = "slow_operation"
    
    // MARK: - User Action Events
    
    /// User feedback submitted
    static let feedbackSubmitted = "feedback_submitted"
    
    /// Settings changed
    static let settingsChanged = "settings_changed"
    
    /// Export action
    static let exportAction = "export_action"
    
    /// Share action
    static let shareAction = "share_action"
} 