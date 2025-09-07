import SwiftUI
import SwiftData  
import Foundation
import Combine

/// Handles formatting operations for PayslipDetailViewModel
/// Responsible for currency formatting, share text generation, and data presentation
@MainActor
class PayslipDetailFormatterService {
    
    // MARK: - Private Properties
    private let formatterService: PayslipFormatterService
    private let payslip: AnyPayslip
    
    // MARK: - Cache Properties
    private var formattedCurrencyCache: [Double: String] = [:]
    
    // MARK: - Initialization
    
    init(payslip: AnyPayslip, formatterService: PayslipFormatterService) {
        self.payslip = payslip
        self.formatterService = formatterService
    }
    
    // MARK: - Public Methods
    
    /// Formats a value as a currency string.
    ///
    /// - Parameter value: The value to format.
    /// - Returns: A formatted currency string.
    func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "₹0.00" }
        
        // Check cache first
        if let cached = formattedCurrencyCache[value] {
            return cached
        }
        
        // Format and cache the result
        let formatted = formatterService.formatCurrency(value)
        formattedCurrencyCache[value] = formatted
        return formatted
    }
    
    /// Formats a year value without group separators
    func formatYear(_ year: Int) -> String {
        return formatterService.formatYear(year)
    }
    
    /// Gets a formatted string representation of the payslip for sharing.
    ///
    /// - Parameter payslipData: The payslip data to format
    /// - Returns: A formatted string with payslip details.
    func getShareText(for payslipData: PayslipData) -> String {
        return formatterService.getShareText(for: payslipData)
    }
    
    /// Gets a formatted breakdown of earnings
    /// - Parameter payslipData: The payslip data containing earnings
    /// - Returns: Array of formatted breakdown items
    func getEarningsBreakdown(from payslipData: PayslipData) -> [BreakdownItem] {
        var items: [BreakdownItem] = []
        
        for (key, value) in payslipData.allEarnings {
            if value > 0 {
                items.append(BreakdownItem(
                    label: key,
                    value: formatCurrency(value)
                ))
            }
        }
        
        return items.sorted(by: { $0.label < $1.label })
    }
    
    /// Gets a formatted breakdown of deductions
    /// - Parameter payslipData: The payslip data containing deductions
    /// - Returns: Array of formatted breakdown items
    func getDeductionsBreakdown(from payslipData: PayslipData) -> [BreakdownItem] {
        var items: [BreakdownItem] = []
        
        for (key, value) in payslipData.allDeductions {
            if value > 0 {
                items.append(BreakdownItem(
                    label: key,
                    value: formatCurrency(value)
                ))
            }
        }
        
        // Add tax and DSOP as separate deductions
        if payslipData.incomeTax > 0 {
            items.append(BreakdownItem(
                label: "Income Tax",
                value: formatCurrency(payslipData.incomeTax)
            ))
        }
        
        if payslipData.dsop > 0 {
            items.append(BreakdownItem(
                label: "DSOP",
                value: formatCurrency(payslipData.dsop)
            ))
        }
        
        return items.sorted(by: { $0.label < $1.label })
    }
    
    /// Gets the PDF filename for this payslip
    var pdfFilename: String {
        let month = payslip.month
        let year = String(payslip.year)
        return "Payslip_\(month)_\(year).pdf"
    }
    
    /// Clears the currency formatting cache
    func clearFormattingCache() {
        formattedCurrencyCache.removeAll()
    }
    
    /// Gets formatted share items for this payslip
    /// - Parameters:
    ///   - payslipData: The payslip data to share
    ///   - pdfData: Optional PDF data to include in sharing
    /// - Returns: Array of items suitable for sharing
    func getShareItems(for payslipData: PayslipData, pdfData: Data? = nil) -> [Any] {
        Logger.info("Creating share items for payslip: \(payslip.month) \(payslip.year)", category: "PayslipSharing")
        
        // Get the share text
        let shareText = getShareText(for: payslipData)
        
        // Create share items array with text
        var shareItems: [Any] = [shareText]
        
        // Add PDF if available and valid
        if let pdfData = pdfData, !pdfData.isEmpty && pdfData.count > 100 {
            let pdfHeader = Data([0x25, 0x50, 0x44, 0x46]) // %PDF in bytes
            if pdfData.starts(with: pdfHeader) {
                Logger.info("PDF data is valid, adding PayslipShareItemProvider", category: "PayslipSharing")
                let provider = PayslipShareItemProvider(
                    pdfData: pdfData,
                    title: "\(payslip.month) \(payslip.year) Payslip"
                )
                shareItems.append(provider)
            }
        }
        
        Logger.info("Final share items count: \(shareItems.count)", category: "PayslipSharing")
        return shareItems
    }
}
