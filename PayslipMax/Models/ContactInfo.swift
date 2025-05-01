import Foundation

/// Model representing contact information extracted from payslips
struct ContactInfo: Codable, Hashable {
    /// Email addresses found in the payslip
    var emails: [String] = []
    
    /// Phone numbers found in the payslip
    var phoneNumbers: [String] = []
    
    /// Websites/URLs found in the payslip
    var websites: [String] = []
    
    /// Whether the contact info model contains any data
    var isEmpty: Bool {
        emails.isEmpty && phoneNumbers.isEmpty && websites.isEmpty
    }
}

// We'll use a protocol to add contactInfo capability instead of an extension

/// Protocol for models that support contact information
protocol ContactInfoProvider {
    /// Contact information extracted from the model
    var contactInfo: ContactInfo { get set }
} 