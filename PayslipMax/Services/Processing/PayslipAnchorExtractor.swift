import Foundation

/// Extracts anchor values (totals) from payslip text
class PayslipAnchorExtractor {

    /// Patterns for extracting anchor values from military payslips
    private let grossPayPatterns = [
        #"(?:Gross\s*Pay|Total\s*Earnings|Total\s*Pay|Total\s*Credits?|कुल\s*आय)\s*:?\s*(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#,
        #"(?:Gross|GROSS)\s+(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#
    ]

    private let totalDeductionsPatterns = [
        #"(?:Total\s*Deductions?|Total\s*Debits?|Deductions?\s*Total|कुल\s*कटौती)\s*:?\s*(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#,
        #"(?:Total\s*Debit|TOTAL\s*DEBIT)\s+(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#
    ]

    private let netRemittancePatterns = [
        #"(?:Net\s*Remittance|Net\s*Amount|NET\s*AMOUNT|Net\s*Pay|Net\s*Salary|Net\s*Payment|निवल\s*प्रेषित\s*धन)\s*:?\s*(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#,
        #"(?:Net|NET)\s+(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#
    ]

    /// Extracts anchor values from the first page of payslip text
    func extractAnchors(from text: String) -> PayslipAnchors? {
        // Extract first page text only
        let firstPageText = extractFirstPageText(from: text)

        guard let grossPay = extractGrossPay(from: firstPageText),
              let totalDeductions = extractTotalDeductions(from: firstPageText),
              let netRemittance = extractNetRemittance(from: firstPageText) else {
            Logger.error("[PayslipAnchorExtractor] Failed to extract all anchor values")
            return nil
        }

        let anchors = PayslipAnchors(
            grossPay: grossPay,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance
        )

        Logger.info("[PayslipAnchorExtractor] Extracted anchors - Gross: ₹\(grossPay), Deductions: ₹\(totalDeductions), Net: ₹\(netRemittance)")

        return anchors
    }

    /// Extracts only the first page from multi-page payslip text
    func extractFirstPageText(from text: String) -> String {
        // Patterns that typically mark page boundaries in military payslips
        let pageBoundaryPatterns = [
            "Page\\s+2",
            "पृष्ठ\\s+2",
            "DETAILS OF ARREARS",
            "बकाया का विवरण",
            "ARREARS/DEDUCTIONS POSTED IN IRLA"
        ]

        // Find the earliest page boundary
        var earliestBoundary = text.endIndex

        for pattern in pageBoundaryPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                if range.lowerBound < earliestBoundary {
                    earliestBoundary = range.lowerBound
                }
            }
        }

        if earliestBoundary < text.endIndex {
            let firstPageText = String(text[..<earliestBoundary])
            Logger.info("[PayslipAnchorExtractor] Extracted first page: \(firstPageText.count) chars (from \(text.count) total)")
            return firstPageText
        }

        // If no boundary found, return full text (might be single-page payslip)
        Logger.warning("[PayslipAnchorExtractor] No page boundary found, using full text")
        return text
    }

    private func extractGrossPay(from text: String) -> Double? {
        return extractAmount(from: text, patterns: grossPayPatterns, label: "Gross Pay")
    }

    private func extractTotalDeductions(from text: String) -> Double? {
        return extractAmount(from: text, patterns: totalDeductionsPatterns, label: "Total Deductions")
    }

    private func extractNetRemittance(from text: String) -> Double? {
        return extractAmount(from: text, patterns: netRemittancePatterns, label: "Net Remittance")
    }

    private func extractAmount(from text: String, patterns: [String], label: String) -> Double? {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges >= 2,
               let amountRange = Range(match.range(at: 1), in: text) {
                let amountString = String(text[amountRange])
                let cleanAmount = amountString.replacingOccurrences(of: ",", with: "")
                if let amount = Double(cleanAmount) {
                    Logger.info("[PayslipAnchorExtractor] Extracted \(label): ₹\(amount)")
                    return amount
                }
            }
        }

        Logger.warning("[PayslipAnchorExtractor] Could not extract \(label)")
        return nil
    }
}
