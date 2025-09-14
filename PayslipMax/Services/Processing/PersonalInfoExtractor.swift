//
//  PersonalInfoExtractor.swift
//  PayslipMax
//
//  Extracted from MilitaryDateExtractor for architectural compliance
//  Handles personal information extraction from payslips
//

import Foundation

/// Protocol for personal information extraction following SOLID principles
protocol PersonalInfoExtractorProtocol {
    func extractPersonalInfo(from text: String) -> (name: String?, accountNumber: String?, panNumber: String?)
}

/// Service responsible for extracting personal information from payslips
/// Implements single responsibility principle for personal data extraction
class PersonalInfoExtractor: PersonalInfoExtractorProtocol {

    /// Extracts personal information (name, account number, PAN) from payslip text
    func extractPersonalInfo(from text: String) -> (name: String?, accountNumber: String?, panNumber: String?) {
        let name = extractName(from: text)
        let accountNumber = extractAccountNumber(from: text)
        let panNumber = extractPANNumber(from: text)

        return (name, accountNumber, panNumber)
    }

    /// Extracts employee name from payslip text
    private func extractName(from text: String) -> String? {
        let namePatterns = [
            "Name\\s*:?\\s*([A-Z][A-Z\\s]+)",
            "नाम\\s*:?\\s*([A-Z][A-Z\\s]+)",
            "Employee\\s*Name\\s*:?\\s*([A-Z][A-Z\\s]+)",
            "(?:Mr\\.|Mrs\\.|Ms\\.)?\\s*([A-Z][A-Z\\s]{10,})",
            "PAYEE\\s*:?\\s*([A-Z][A-Z\\s]+)"
        ]

        for pattern in namePatterns {
            if let extractedValue = extractValueWithPattern(pattern, from: text) {
                let cleanedName = extractedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

                // Validate name (should be 3+ words, all caps, reasonable length)
                let nameComponents = cleanedName.components(separatedBy: " ").filter { !$0.isEmpty }
                if nameComponents.count >= 2 && cleanedName.count >= 10 && cleanedName.count <= 50 {
                    return cleanedName
                }
            }
        }

        return nil
    }

    /// Extracts CDA account number from payslip text
    private func extractAccountNumber(from text: String) -> String? {
        let accountPatterns = [
            "CDA\\s+A/C\\s+No\\.?\\s*:?\\s*([0-9/]+[A-Z]?)",
            "Account\\s+No\\.?\\s*:?\\s*([0-9/]+[A-Z]?)",
            "A/C\\s+No\\.?\\s*:?\\s*([0-9/]+[A-Z]?)",
            "खाता\\s+संख्या\\s*:?\\s*([0-9/]+[A-Z]?)"
        ]

        for pattern in accountPatterns {
            if let extractedValue = extractValueWithPattern(pattern, from: text) {
                let cleanedAccount = extractedValue.trimmingCharacters(in: .whitespacesAndNewlines)

                // Validate account number format (should contain numbers and potentially slashes)
                if cleanedAccount.count >= 5 && cleanedAccount.count <= 20 {
                    return cleanedAccount
                }
            }
        }

        return nil
    }

    /// Extracts PAN number from payslip text
    private func extractPANNumber(from text: String) -> String? {
        let panPatterns = [
            "PAN\\s+No\\.?\\s*:?\\s*([A-Z0-9*]+)",
            "PAN\\s*:?\\s*([A-Z0-9*]+)",
            "पैन\\s+संख्या\\s*:?\\s*([A-Z0-9*]+)"
        ]

        for pattern in panPatterns {
            if let extractedValue = extractValueWithPattern(pattern, from: text) {
                let cleanedPAN = extractedValue.trimmingCharacters(in: .whitespacesAndNewlines)

                // Validate PAN format (10 characters, mix of letters and numbers, may have asterisks for privacy)
                if cleanedPAN.count == 10 && cleanedPAN.range(of: "^[A-Z0-9*]+$", options: .regularExpression) != nil {
                    return cleanedPAN
                }
            }
        }

        return nil
    }

    /// Helper function to extract value using regex pattern
    private func extractValueWithPattern(_ pattern: String, from text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: text.utf16.count)

            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if match.numberOfRanges > 1 {
                    let captureRange = match.range(at: 1)
                    if let swiftRange = Range(captureRange, in: text) {
                        return String(text[swiftRange])
                    }
                }
            }
        } catch {
            print("[PersonalInfoExtractor] Error in regex pattern '\(pattern)': \(error)")
        }

        return nil
    }
}
