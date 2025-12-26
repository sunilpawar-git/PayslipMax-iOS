//
//  VisionLLMParserHelpers.swift
//  PayslipMax
//
//  Helper methods for Vision LLM payslip parsing - extracted for modularity
//

import Foundation
import OSLog

/// Helpers for Vision LLM payslip parsing operations
enum VisionLLMParserHelpers {
    
    /// Checks if JSON is complete (balanced braces)
    /// - Parameter json: JSON string to check
    /// - Returns: True if JSON appears complete
    static func isCompleteJSON(_ json: String) -> Bool {
        let trimmed = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{"), trimmed.hasSuffix("}") else {
            return false
        }
        
        var braceCount = 0
        for char in trimmed {
            if char == "{" {
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
            }
        }
        
        return braceCount == 0
    }
    
    /// Cleans JSON response by removing markdown code blocks
    /// - Parameter content: Raw response content
    /// - Returns: Clean JSON string
    static func cleanJSONResponse(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }
        
        return cleaned
    }
    
    /// Filters out suspicious deduction keys that are likely extraction errors
    /// - Parameters:
    ///   - deductions: Raw deductions dictionary
    ///   - logger: Logger for recording filtered entries
    /// - Returns: Filtered deductions dictionary
    static func filterSuspiciousDeductions(
        _ deductions: [String: Double],
        logger: os.Logger? = nil
    ) -> [String: Double] {
        let suspiciousKeywords = [
            "total", "balance", "released", "refund", "recovery",
            "previous", "carried", "forward", "advance", "credit balance"
        ]
        
        var filtered: [String: Double] = [:]
        var removedEntries: [String] = []
        
        for (key, value) in deductions {
            let lowercaseKey = key.lowercased()
            let isSuspicious = suspiciousKeywords.contains { keyword in
                lowercaseKey.contains(keyword)
            }
            
            if isSuspicious {
                removedEntries.append("\(key): \(value)")
            } else {
                filtered[key] = value
            }
        }
        
        if !removedEntries.isEmpty {
            logger?.info("🧹 Filtered suspicious deductions: \(removedEntries.joined(separator: ", "))")
        }
        
        return filtered
    }
    
    /// Removes duplicate entries (placeholder for future enhancement)
    static func removeDuplicates(_ deductions: [String: Double]) -> [String: Double] {
        return deductions
    }
}

