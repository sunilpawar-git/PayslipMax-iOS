import Foundation

/// Service to extract contact information (emails, phone numbers, websites) from payslip text
class ContactInfoExtractor {
    /// Shared instance for convenience
    static let shared = ContactInfoExtractor()
    
    /// Extract contact information from the given text
    /// - Parameter text: The text to extract contact information from
    /// - Returns: A ContactInfo object containing the extracted information
    func extractContactInfo(from text: String) -> ContactInfo {
        var contactInfo = ContactInfo()
        
        // Extract emails
        contactInfo.emails = extractEmails(from: text)
        
        // Extract phone numbers
        contactInfo.phoneNumbers = extractPhoneNumbers(from: text)
        
        // Extract websites
        contactInfo.websites = extractWebsites(from: text)
        
        // Look for contact section - common in military payslips
        if let contactSection = extractContactSection(from: text) {
            // Process the contact section in more detail
            let additionalEmails = extractEmails(from: contactSection)
            let additionalPhones = extractPhoneNumbers(from: contactSection)
            let additionalWebsites = extractWebsites(from: contactSection)
            
            // Add unique items
            contactInfo.emails.append(contentsOf: additionalEmails.filter { !contactInfo.emails.contains($0) })
            contactInfo.phoneNumbers.append(contentsOf: additionalPhones.filter { !contactInfo.phoneNumbers.contains($0) })
            contactInfo.websites.append(contentsOf: additionalWebsites.filter { !contactInfo.websites.contains($0) })
        }
        
        return contactInfo
    }
    
    /// Extract the contact section from the text
    /// - Parameter text: The text to search in
    /// - Returns: The contact section text if found
    private func extractContactSection(from text: String) -> String? {
        // Common patterns to identify contact sections in payslips
        let contactSectionMarkers = [
            "CONTACT US",
            "CONTACT INFORMATION",
            "FOR FURTHER INFORMATION",
            "YOUR CONTACT POINTS",
            "CONTACT DETAILS"
        ]
        
        // Try to find a contact section using the markers
        for marker in contactSectionMarkers {
            if let range = text.range(of: marker, options: .caseInsensitive) {
                // Get text from the marker to the next section or end
                let startIndex = range.lowerBound
                let sectionText = String(text[startIndex...])
                
                // Try to find the end of the section (next heading or after a reasonable amount of text)
                let sectionEndMarkers = ["visit us", "website", "email us", "for more information", "note"]
                
                var endIndex = sectionText.endIndex
                for endMarker in sectionEndMarkers {
                    if let endRange = sectionText.range(of: endMarker, options: [.caseInsensitive, .anchored], range: sectionText.startIndex..<sectionText.endIndex) {
                        // Found a potential end marker - check if it's not too close to the beginning
                        if sectionText.distance(from: sectionText.startIndex, to: endRange.upperBound) > 300 {
                            endIndex = endRange.upperBound
                            break
                        }
                    }
                }
                
                // Limit the section length if it's too long (common in multi-page docs)
                let maxLength = 1000
                if sectionText.distance(from: sectionText.startIndex, to: endIndex) > maxLength {
                    endIndex = sectionText.index(sectionText.startIndex, offsetBy: maxLength)
                }
                
                return String(sectionText[sectionText.startIndex..<endIndex])
            }
        }
        
        return nil
    }
    
    /// Extract email addresses from text
    /// - Parameter text: The text to extract from
    /// - Returns: Array of extracted email addresses
    private func extractEmails(from text: String) -> [String] {
        // Pattern for email addresses
        let emailPattern = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#
        
        return matchPattern(emailPattern, in: text)
    }
    
    /// Extract phone numbers from text
    /// - Parameter text: The text to extract from
    /// - Returns: Array of extracted phone numbers
    private func extractPhoneNumbers(from text: String) -> [String] {
        // Multiple patterns for different phone number formats
        let phonePatterns = [
            #"\(?\d{3,5}[-\s\)]+\d{5,10}"#,         // (020-26401236) format
            #"\d{4,5}[-/]\d{5,10}"#,                // 6512/6528 format
            #"\(\d{3,5}\)\s*\d{5,10}"#,             // (020) 26401236 format
            #"(?<!\d)\d{10}(?!\d)"#                 // Plain 10-digit numbers
        ]
        
        var phoneNumbers: [String] = []
        for pattern in phonePatterns {
            phoneNumbers.append(contentsOf: matchPattern(pattern, in: text))
        }
        
        // Post-process phone numbers to fix STD code
        return phoneNumbers.map { phoneNumber in
            // Fix STD code from 202 to 020 if present
            var processedNumber = phoneNumber
            
            // Check for (202) format
            if processedNumber.contains("(202)") {
                processedNumber = processedNumber.replacingOccurrences(of: "(202)", with: "(020)")
            }
            
            // Check for (202- format
            if processedNumber.contains("(202-") {
                processedNumber = processedNumber.replacingOccurrences(of: "(202-", with: "(020-")
            }
            
            // Check for plain 202 at start
            if processedNumber.hasPrefix("202") {
                processedNumber = "020" + processedNumber.dropFirst(3)
            }
            
            return processedNumber
        }
    }
    
    /// Extract websites/URLs from text
    /// - Parameter text: The text to extract from
    /// - Returns: Array of extracted websites
    private func extractWebsites(from text: String) -> [String] {
        // Pattern for websites
        let websitePattern = #"https?://[^\s]+"#
        let domainPattern = #"www\.[^\s]+"#
        let govPattern = #"[^\s]+\.gov\.[^\s]+"#
        let govInPattern = #"[^\s]+\.gov\.in[^\s]*"#
        
        var websites = matchPattern(websitePattern, in: text)
        websites.append(contentsOf: matchPattern(domainPattern, in: text))
        websites.append(contentsOf: matchPattern(govPattern, in: text))
        websites.append(contentsOf: matchPattern(govInPattern, in: text))
        
        // Remove duplicates
        return Array(Set(websites))
    }
    
    /// Generic method to match patterns in text
    /// - Parameters:
    ///   - pattern: The regex pattern to match
    ///   - text: The text to search in
    /// - Returns: Array of matched strings
    private func matchPattern(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
} 