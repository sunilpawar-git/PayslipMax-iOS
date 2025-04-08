import Foundation

// This file provides centralized notification name constants

// Using enum to namespace notification constants instead of extension to avoid conflicts
enum AppNotification {
    // MARK: - Home Screen Notifications
    
    /// Notification sent when the user requests to open the document picker
    static let documentPickerRequested = Notification.Name("documentPickerRequested")
    
    /// Notification sent when the user requests to open the scanner
    static let scannerRequested = Notification.Name("scannerRequested")
    
    /// Notification sent to trigger showing the document picker
    static let showDocumentPicker = Notification.Name("showDocumentPicker")
    
    /// Notification sent to trigger showing the scanner
    static let showScanner = Notification.Name("showScanner")
    
    // MARK: - Payslip Notifications
    
    /// Notification sent when a payslip is updated or added
    static let payslipUpdated = Notification.Name("payslipUpdated")
    
    /// Notification sent when a payslip is deleted
    static let payslipDeleted = Notification.Name("payslipDeleted")
} 