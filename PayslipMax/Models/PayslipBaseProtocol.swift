import Foundation

/// Protocol defining the base identity properties of a payslip item.
///
/// This protocol provides the core identity properties that are required
/// by all payslip items, allowing for better organization of concerns.
protocol PayslipBaseProtocol: Identifiable, Codable {
    // MARK: - Core Identity Properties
    
    /// The unique identifier of the payslip item.
    var id: UUID { get }
    
    /// The timestamp when the payslip was created or processed.
    var timestamp: Date { get set }
} 