import Foundation

/// Utility class for formatters used throughout the app
class Formatters {
    
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    static let indianCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        formatter.secondaryGroupingSize = 2
        return formatter
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy" // Hardcoded for now, will use Constants later
        return formatter
    }()
    
    static func formatCurrency(_ amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
    }
    
    /// Formats currency using Indian number system with proper grouping
    static func formatIndianCurrency(_ amount: Double, showSymbol: Bool = false) -> String {
        let absoluteAmount = abs(amount)
        let prefix = showSymbol ? "₹" : ""
        
        if absoluteAmount >= 10_000_000 { // 1 Crore or more
            let crores = absoluteAmount / 10_000_000
            if crores >= 100 {
                // Use full number with Indian grouping for very large amounts
                return prefix + formatWithIndianGrouping(absoluteAmount)
            } else if crores >= 10 {
                return prefix + String(format: "%.0f", crores) + " Cr"
            } else {
                return prefix + String(format: "%.1f", crores) + " Cr"
            }
        } else if absoluteAmount >= 100_000 { // 1 Lakh or more
            let lakhs = absoluteAmount / 100_000
            if lakhs >= 100 {
                return prefix + String(format: "%.0f", lakhs) + " L"
            } else if lakhs >= 10 {
                return prefix + String(format: "%.0f", lakhs) + " L"
            } else {
                return prefix + String(format: "%.1f", lakhs) + " L"
            }
        } else if absoluteAmount >= 1_000 { // 1 Thousand or more  
            return prefix + formatWithIndianGrouping(absoluteAmount)
        } else {
            return prefix + String(format: "%.0f", absoluteAmount)
        }
    }
    
    /// Formats numbers with Indian grouping system (every 2 digits after first 3)
    private static func formatWithIndianGrouping(_ amount: Double) -> String {
        indianCurrencyFormatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
    }
    
    static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
    
    static func formatYear(_ year: Int) -> String {
        return String(year)
    }
} 