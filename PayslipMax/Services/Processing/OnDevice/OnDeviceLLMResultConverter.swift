import Foundation

/// Converts OnDeviceLLMResult into a PayslipItem for the processing pipeline
enum OnDeviceLLMResultConverter {

    /// Parses a month name string (e.g. "JANUARY", "Jan") to its 1-based number
    static func parseMonth(_ monthString: String?) -> Int? {
        guard let raw = monthString?.trimmingCharacters(in: .whitespaces).uppercased(),
              !raw.isEmpty else { return nil }

        let monthMap: [String: Int] = [
            "JANUARY": 1, "JAN": 1,
            "FEBRUARY": 2, "FEB": 2,
            "MARCH": 3, "MAR": 3,
            "APRIL": 4, "APR": 4,
            "MAY": 5,
            "JUNE": 6, "JUN": 6,
            "JULY": 7, "JUL": 7,
            "AUGUST": 8, "AUG": 8,
            "SEPTEMBER": 9, "SEP": 9,
            "OCTOBER": 10, "OCT": 10,
            "NOVEMBER": 11, "NOV": 11,
            "DECEMBER": 12, "DEC": 12
        ]

        return monthMap[raw]
    }

    private static let monthSymbols = DateFormatter().monthSymbols ?? []

    /// Converts a month number (1-12) to a display name
    static func monthDisplayName(for number: Int) -> String {
        guard number >= 1, number <= 12, number <= monthSymbols.count else { return "Unknown" }
        return monthSymbols[number - 1]
    }
}

extension PayslipItem {
    /// Creates a PayslipItem from an on-device LLM extraction result.
    /// Does NOT populate PII fields (name, account, PAN) -- security by design.
    static func from(onDeviceResult result: OnDeviceLLMResult) -> PayslipItem {
        let monthNum = OnDeviceLLMResultConverter.parseMonth(result.month)
        let monthDisplay = monthNum.map { OnDeviceLLMResultConverter.monthDisplayName(for: $0) } ?? "Unknown"

        let item = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: monthDisplay,
            year: result.year ?? Calendar.current.component(.year, from: Date()),
            credits: result.grossPay,
            debits: result.totalDeductions,
            dsop: result.deductions["DSOP"] ?? 0,
            tax: result.deductions["ITAX"] ?? 0,
            name: "",
            accountNumber: "",
            panNumber: "",
            pdfData: nil
        )

        item.earnings = result.earnings
        item.deductions = result.deductions

        return item
    }
}
