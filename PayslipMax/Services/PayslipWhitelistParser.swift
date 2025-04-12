import Foundation
import PDFKit

/// A simple parser that uses a whitelist approach to extract payslip data
class PayslipWhitelistParser {
    
    // MARK: - Whitelist Definitions
    
    /// Personal Details Whitelist
    private let personalDetails = [
        "name": ["name", "employee name", "officer name"],
        "accountNumber": ["a/c no", "account no", "account number", "ac no"],
        "panNumber": ["pan no", "pan number", "permanent account number"]
    ]
    
    /// Earnings Breakdown Whitelist
    private let earnings = [
        "basicPay": ["bpay", "basic pay", "pay", "basic", "basic salary"],
        "dearnessPay": ["da", "dearness allowance", "dearness"],
        "militaryServicePay": ["msp", "military service pay", "service pay", "mil pay", "military pay"],
        "grossPay": ["gross pay", "total earnings", "total credits", "gross", "credits"]
    ]
    
    /// Deductions Breakdown Whitelist
    private let deductions = [
        "dsop": ["dsop", "dsop fund", "defence services officers provident fund", "provident fund", "pf"],
        "agif": ["agif", "army group insurance fund", "insurance", "gis"],
        "incomeTax": ["itax", "income tax", "tax", "i.tax"],
        "totalDeductions": ["total deductions", "total debits", "deductions total", "debits"]
    ]
    
    /// Income Tax Details Whitelist
    private let incomeTaxDetails = [
        "incomeTax": ["itax", "income tax", "tax", "i.tax"]
    ]
    
    /// DSOP Details Whitelist
    private let dsopDetails = [
        "openingBalance": ["opening balance", "ob", "beginning balance", "opening"],
        "dsopContribution": ["dsop", "contribution", "subscription", "dsop contribution"],
        "closingBalance": ["closing balance", "cb", "ending balance", "closing"]
    ]
    
    /// Contact Details Whitelist
    private let contactDetails = [
        "website": ["website", "web", "site", "url"],
        "phone": ["phone", "tel", "telephone", "contact no"],
        "email": ["email", "mail", "e-mail"],
        "address": ["address", "addr", "location"]
    ]
    
    // MARK: - Parsing Logic
    
    /// Parse a PDF document and return a dictionary of key-value pairs
    func parse(pdfDocument: PDFDocument) -> [String: String] {
        var result: [String: String] = [:]
        
        // Extract text from the PDF
        let extractedText = extractText(from: pdfDocument)
        
        // Parse text and extract data we're interested in
        for (key, synonyms) in personalDetails {
            if let value = findValueWithSynonyms(in: extractedText, for: synonyms) {
                result[key] = value
            }
        }
        
        for (key, synonyms) in contactDetails {
            if let value = findValueWithSynonyms(in: extractedText, for: synonyms) {
                result[key] = value
            }
        }
        
        // Add other extractions as needed
        
        return result
    }
    
    /// Parse a PDF document into PayslipData (original method)
    func parseToPayslipData(pdfDocument: PDFDocument) -> Models.PayslipData {
        var data = Models.PayslipData(from: PayslipItemFactory.createEmpty())
        
        // Extract text from the PDF
        let extractedText = extractText(from: pdfDocument)
        
        // Extract key-value pairs using pattern matching
        let pairs = extractKeyValuePairs(from: extractedText)
        
        // Process each key-value pair
        for (key, value) in pairs {
            processKeyValuePair(key: key, value: value, data: &data)
        }
        
        // Calculate derived fields
        data.calculateDerivedFields()
        
        return data
    }
    
    /// Process a single key-value pair and update the data model
    private func processKeyValuePair(key: String, value: String, data: inout Models.PayslipData) {
        let normalizedKey = key.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check each whitelist category
        if let matchedKey = matchInWhitelist(term: normalizedKey, whitelist: personalDetails) {
            handlePersonalDetail(key: matchedKey, value: value, data: &data)
        }
        else if let matchedKey = matchInWhitelist(term: normalizedKey, whitelist: earnings) {
            if let numericValue = extractNumericValue(from: value) {
                handleEarning(key: matchedKey, value: numericValue, data: &data)
            }
        }
        else if let matchedKey = matchInWhitelist(term: normalizedKey, whitelist: deductions) {
            if let numericValue = extractNumericValue(from: value) {
                handleDeduction(key: matchedKey, value: numericValue, data: &data)
            }
        }
        else if let matchedKey = matchInWhitelist(term: normalizedKey, whitelist: dsopDetails) {
            if let numericValue = extractNumericValue(from: value) {
                handleDSOPDetail(key: matchedKey, value: numericValue, data: &data)
            }
        }
        else if let matchedKey = matchInWhitelist(term: normalizedKey, whitelist: contactDetails) {
            handleContactDetail(key: matchedKey, value: value, data: &data)
        }
        // If not in any whitelist, ignore
    }
    
    /// Check if a term matches any entry in a whitelist
    private func matchInWhitelist(term: String, whitelist: [String: [String]]) -> String? {
        for (key, aliases) in whitelist {
            if aliases.contains(where: { term.contains($0) }) {
                return key
            }
        }
        return nil
    }
    
    /// Handle personal details
    private func handlePersonalDetail(key: String, value: String, data: inout Models.PayslipData) {
        switch key {
        case "name": data.name = value
        case "accountNumber": data.accountNumber = value
        case "panNumber": data.panNumber = value
        default: break
        }
    }
    
    /// Handle earnings
    private func handleEarning(key: String, value: Double, data: inout Models.PayslipData) {
        switch key {
        case "basicPay": data.basicPay = value
        case "dearnessPay": data.dearnessPay = value
        case "militaryServicePay": data.militaryServicePay = value
        case "grossPay": data.totalCredits = value
        default: break
        }
        
        // Also add to all earnings dictionary
        data.allEarnings[key] = value
    }
    
    /// Handle deductions
    private func handleDeduction(key: String, value: Double, data: inout Models.PayslipData) {
        switch key {
        case "dsop": data.dsop = value
        case "agif": data.agif = value
        case "incomeTax": data.incomeTax = value
        case "totalDeductions": data.totalDebits = value
        default: break
        }
        
        // Also add to all deductions dictionary
        data.allDeductions[key] = value
    }
    
    /// Handle DSOP details
    private func handleDSOPDetail(key: String, value: Double, data: inout Models.PayslipData) {
        switch key {
        case "openingBalance": data.dsopOpeningBalance = value
        case "dsopContribution": data.dsop = value
        case "closingBalance": data.dsopClosingBalance = value
        default: break
        }
    }
    
    /// Handle contact details
    private func handleContactDetail(key: String, value: String, data: inout Models.PayslipData) {
        data.contactDetails[key] = value
    }
    
    // MARK: - Helper Methods
    
    /// Extract text from a PDF document
    private func extractText(from pdfDocument: PDFDocument) -> String {
        var fullText = ""
        
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let text = page.string {
                fullText += text + "\n"
            }
        }
        
        return fullText
    }
    
    /// Extract key-value pairs from text using patterns
    private func extractKeyValuePairs(from text: String) -> [(String, String)] {
        var pairs: [(String, String)] = []
        
        // Simple pattern: "Key: Value" or "Key Value"
        let pattern = "([\\w\\s\\(\\)\\-]+)(?::|\\s+)(\\d[\\d,.]+)"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let keyRange = match.range(at: 1)
                    let valueRange = match.range(at: 2)
                    
                    let key = nsString.substring(with: keyRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    pairs.append((key, value))
                }
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        // Look for specific patterns like "Name: John Doe"
        // We need to search for each whitelist term in each category
        let whitelists = [personalDetails, earnings, deductions, dsopDetails, incomeTaxDetails, contactDetails]
        
        for whitelist in whitelists {
            for (_, aliases) in whitelist {
                for alias in aliases {
                    if let pair = findSpecificPattern(alias: alias, in: text) {
                        pairs.append(pair)
                    }
                }
            }
        }
        
        return pairs
    }
    
    /// Find a specific pattern in text
    private func findSpecificPattern(alias: String, in text: String) -> (String, String)? {
        // Look for patterns like "Name: John Doe" or "DSOP Fund: 40000"
        let patternString = "\(alias)[:\\s]+([^\\n\\r]+)"
        
        do {
            let regex = try NSRegularExpression(pattern: patternString, options: [.caseInsensitive])
            let nsText = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
            
            if let match = matches.first, match.numberOfRanges >= 2 {
                let valueRange = match.range(at: 1)
                let value = nsText.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                return (alias, value)
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        return nil
    }
    
    /// Extract a numeric value from a string
    private func extractNumericValue(from string: String) -> Double? {
        // Remove commas and other non-numeric characters
        let cleanedString = string.replacingOccurrences(of: ",", with: "")
        
        // Extract the first number found
        let pattern = "\\d+(?:\\.\\d+)?"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = cleanedString as NSString
            let matches = regex.matches(in: cleanedString, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first {
                let valueString = nsString.substring(with: match.range)
                return Double(valueString)
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        // If no other pattern works, just try to convert the entire string
        return Double(cleanedString)
    }
    
    /// Find a value in text that matches any of the synonyms
    private func findValueWithSynonyms(in text: String, for synonyms: [String]) -> String? {
        for synonym in synonyms {
            if let value = findSpecificPattern(alias: synonym, in: text) {
                return value.1
            }
        }
        return nil
    }
} 