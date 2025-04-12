import SwiftUI
import Combine

/// Protocol that defines common interface for both PayslipDetailViewModel and SimplifiedPayslipDetailViewModel
protocol PayslipViewModelProtocol: ObservableObject {
    var isLoading: Bool { get set }
    var error: AppError? { get set }
    var payslipData: Models.PayslipData { get set }
    var showShareSheet: Bool { get set }
    var showDiagnostics: Bool { get set }
    var showOriginalPDF: Bool { get set }
    var pdfFilename: String { get }
    var payslip: AnyPayslip { get }
    
    func loadAdditionalData() async
    func enrichPayslipData(with pdfData: [String: String])
    func formatCurrency(_ value: Double?) -> String
    func getShareText() -> String
    func getShareItems() -> [Any]?
    func getPDFURL() async throws -> URL?
}

// Add extension for default implementations if needed
extension PayslipViewModelProtocol {
    func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "₹0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "₹\(value)"
    }
} 