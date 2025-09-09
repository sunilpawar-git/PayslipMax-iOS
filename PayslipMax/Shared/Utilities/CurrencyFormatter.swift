import Foundation

/// Utility for formatting currency values
struct CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    /// Formats a currency value
    static func format(_ value: Double) -> String {
        if let formattedValue = formatter.string(from: NSNumber(value: value)) {
            return formattedValue
        }

        return String(format: "%.0f", value)
    }
}
