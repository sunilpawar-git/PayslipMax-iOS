import Foundation

/// Protocol for PCDA (Principal Controller of Defence Accounts) payslip handling.
/// Enables dependency injection and testing of military PDF unlock logic.
protocol PCDAPayslipHandlerProtocol {
    /// Attempts to unlock a PCDA PDF using various military-specific password strategies.
    /// - Parameters:
    ///   - data: The password-protected PDF data.
    ///   - basePassword: The base password provided by the user.
    /// - Returns: A tuple of (unlocked data, successful password) — both nil on failure.
    func unlockPDF(data: Data, basePassword: String) async -> (Data?, String?)
}
