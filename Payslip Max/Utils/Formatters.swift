import Foundation

struct Formatters {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹" // Hardcoded for now, will use Constants later
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy" // Hardcoded for now, will use Constants later
        return formatter
    }()
    
    static func formatCurrency(_ amount: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? "₹\(amount)"
    }
    
    static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
} 