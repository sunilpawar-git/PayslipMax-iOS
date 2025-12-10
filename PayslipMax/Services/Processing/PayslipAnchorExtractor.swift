import Foundation

/// Extracts anchor values (totals) from payslip text
class PayslipAnchorExtractor {

    /// Patterns for extracting anchor values from military payslips
    private let grossPayPatterns = [
        #"(?is)(?:Gross\s*Pay|Total\s*Earnings|Total\s*Pay|Total\s*Credits?|TOTAL\s*CREDITS?|कुल\s*आय)\s*:?\s*(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#,
        #"(?is)(?:Gross|GROSS)\s+(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#
    ]

    private let totalDeductionsPatterns = [
        #"(?:Total\s*Deductions?|Total\s*Debits?|TOTAL\s*DEBITS?|Deductions?\s*Total|कुल\s*कटौती)\s*:?\s*(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#,
        #"(?:Total\s*Debit|TOTAL\s*DEBIT)\s+(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#
    ]

    private let netRemittancePatterns = [
        #"(?:Net\s*Remittance|Net\s*Amount|NET\s*AMOUNT|Net\s*Pay|Net\s*Salary|Net\s*Payment|निवल\s*प्रेषित\s*धन)\s*:?\s*(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#,
        #"(?:Net|NET)\s+(?:Rs\.?|₹)?\s*([0-9,]+(?:\.\d{1,2})?)"#,
        // JCO/OR slips often label net as amount credited to bank (tolerate line breaks)
        #"(?is)AMOUNT\\s+CREDITED\\s+TO\\s+BANK\\s*:?[\\s₹Rs\\.]*([0-9,]+(?:\\.\\d{1,2})?)"#,
        #"(?is)AMOUNT\\s+CREDITED\\s+TO\\s*A/C\\s*:?[\\s₹Rs\\.]*([0-9,]+(?:\\.\\d{1,2})?)"#
    ]

    /// Extracts anchor values from the preferred anchor text (top band of first page) unless disabled
    func extractAnchors(from text: String, usePreferredTopSection: Bool = true) -> PayslipAnchors? {
        let anchorText = usePreferredTopSection ? extractPreferredAnchorText(from: text) : extractFirstPageText(from: text)

        guard let grossPay = extractGrossPay(from: anchorText),
              let totalDeductions = extractTotalDeductions(from: anchorText) else {
            Logger.error("[PayslipAnchorExtractor] Failed to extract all anchor values")
            Logger.info("[PayslipAnchorExtractor] Anchor text sample: \(anchorText.prefix(400))")
            return nil
        }

        // Prefer explicit net remittance; otherwise derive it to keep OCR/scanned slips flowing
        let netRemittance = extractNetRemittance(from: anchorText)
        let netValue: Double
        let netSource: String
        let anchors: PayslipAnchors

        if let net = netRemittance {
            netValue = net
            netSource = "provided"
            anchors = PayslipAnchors(
                grossPay: grossPay,
                totalDeductions: totalDeductions,
                netRemittance: net,
                isNetDerived: false
            )
        } else {
            let derivedNet = grossPay - totalDeductions
            Logger.warning("[PayslipAnchorExtractor] Net remittance missing; deriving net as Gross - Deductions (₹\(derivedNet))")
            netValue = derivedNet
            netSource = "derived"
            anchors = PayslipAnchors(
                grossPay: grossPay,
                totalDeductions: totalDeductions,
                netRemittance: derivedNet,
                isNetDerived: true
            )
        }

        Logger.info("[PayslipAnchorExtractor] Extracted anchors - Gross: ₹\(grossPay), Deductions: ₹\(totalDeductions), Net: ₹\(netValue) (\(netSource))")

        return anchors
    }

    /// Prefers the top section of the first page (header + accounts-at-a-glance) when available; falls back to first page text.
    func extractPreferredAnchorText(from text: String) -> String {
        let firstPageText = extractFirstPageText(from: text)
        let topSection = extractTopSectionText(from: firstPageText)

        if topSection.count >= 200 {
            Logger.info("[PayslipAnchorExtractor] Using top section text for anchors (\(topSection.count) chars)")
            return topSection
        }

        return firstPageText
    }

    /// Extracts the top section of the first page, stopping after the net/amount-credited line when present.
    /// Keeps noise (advances/funds) out of anchor and component parsing.
    func extractTopSectionText(from text: String) -> String {
        let markerPatterns = [
            "(?is)AMOUNT\\s+ACCREDITED\\s+TO\\s+BANK",
            "(?is)AMOUNT\\s+CREDITED\\s+TO\\s+BANK",
            "(?is)AMOUNT\\s+CR[EA]DITED\\s+TO\\s+BANK",
            "(?is)AMOUNT\\s+TO\\s+BANK"
        ]

        var cutoff: String.Index?
        for pattern in markerPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                cutoff = range.upperBound
                break
            }
        }

        if let cutoff = cutoff, cutoff <= text.endIndex {
            let sliced = String(text[..<cutoff])
            return sliced
        }

        return text
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
                // Remove commas and spaces to tolerate OCR-separated digits (e.g., "8 6 9 5 3")
                let cleanAmount = amountString
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: " ", with: "")
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
