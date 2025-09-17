//
//  PatternMatchingProcessor.swift
//  PayslipMax
//
//  Created for pattern matching processing of military payslips
//  Extracted from MilitaryPatternExtractor to maintain file size compliance
//

import Foundation

/// Processor for pattern matching in military payslips
/// Handles regex-based extraction of financial components
final class PatternMatchingProcessor: PatternMatchingProcessorProtocol {

    // MARK: - Public Interface

    /// Helper function to extract numerical amount using regex pattern
    /// - Parameter pattern: Regular expression pattern
    /// - Parameter text: Text to search in
    /// - Returns: Extracted amount or nil if not found
    func extractAmountWithPattern(_ pattern: String, from text: String) -> Double? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanValue = value.replacingOccurrences(of: ",", with: "")
                return Double(cleanValue)
            }
        } catch {
            print("[PatternMatchingProcessor] Error with regex pattern \(pattern): \(error.localizedDescription)")
        }
        return nil
    }
}
