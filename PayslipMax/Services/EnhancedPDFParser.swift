import Foundation
import PDFKit
import SwiftUI

/// A structured representation of parsed payslip data
struct ParsedPayslipData {
    var personalInfo: [String: String] = [:]
    var earnings: [String: Double] = [:]
    var deductions: [String: Double] = [:]
    var taxDetails: [String: Double] = [:]
    var dsopDetails: [String: Double] = [:]
    var contactDetails: [String: String] = [:]
    var metadata: [String: String] = [:]
    var rawText: String = ""
    var documentStructure: DocumentStructure = .unknown
    var confidenceScore: Double = 0.0
    
    // Contact information for display in the UI
    var contactInfo: ContactInfo = ContactInfo()
}



/// Enhanced PDF Parser that uses a multi-stage approach
class EnhancedPDFParser {
    
    // MARK: - Properties
    
    private let militaryTerminologyService: MilitaryAbbreviationsService
    private let contactInfoExtractor: ContactInfoExtractor
    private let documentStructureIdentifier: DocumentStructureIdentifierProtocol
    private let documentSectionExtractor: DocumentSectionExtractorProtocol
    
    // MARK: - Initialization
    
    init(militaryTerminologyService: MilitaryAbbreviationsService = MilitaryAbbreviationsService.shared,
         contactInfoExtractor: ContactInfoExtractor = ContactInfoExtractor.shared,
         documentStructureIdentifier: DocumentStructureIdentifierProtocol = DocumentStructureIdentifier(),
         documentSectionExtractor: DocumentSectionExtractorProtocol = DocumentSectionExtractor()) {
        self.militaryTerminologyService = militaryTerminologyService
        self.contactInfoExtractor = contactInfoExtractor
        self.documentStructureIdentifier = documentStructureIdentifier
        self.documentSectionExtractor = documentSectionExtractor
    }
    
    // MARK: - Public Methods
    
    /// Parse a PDF document into structured payslip data
    /// - Parameter document: The PDF document to parse
    /// - Returns: Structured payslip data
    /// - Throws: An error if parsing fails
    func parseDocument(_ document: PDFDocument) throws -> ParsedPayslipData {
        // Stage 1: Extract full text and identify document structure
        let fullText = extractFullText(from: document)
        let documentStructure = documentStructureIdentifier.identifyDocumentStructure(from: fullText)
        
        // Initialize result with basic information
        var result = ParsedPayslipData()
        result.rawText = fullText
        result.documentStructure = documentStructure
        
        // Stage 2: Extract document sections
        let sections = documentSectionExtractor.extractDocumentSections(from: document, structure: documentStructure)
        
        // Stage 3: Extract contact information
        let contactInfo = contactInfoExtractor.extractContactInfo(from: fullText)
        result.contactInfo = contactInfo
        
        // Add contact info to metadata for backward compatibility
        if !contactInfo.emails.isEmpty {
            result.contactDetails["email"] = contactInfo.emails.joined(separator: ", ")
        }
        
        if !contactInfo.phoneNumbers.isEmpty {
            result.contactDetails["phone"] = contactInfo.phoneNumbers.joined(separator: ", ")
        }
        
        if !contactInfo.websites.isEmpty {
            result.contactDetails["website"] = contactInfo.websites.joined(separator: ", ")
        }
        
        // Stage 4: Parse each section with specialized parsers
        for section in sections {
            switch section.name.lowercased() {
            case "personal":
                result.personalInfo = parsePersonalInfoSection(section)
            case "earnings":
                result.earnings = parseEarningsSection(section)
            case "deductions":
                result.deductions = parseDeductionsSection(section)
            case "tax":
                result.taxDetails = parseTaxSection(section)
            case "dsop":
                result.dsopDetails = parseDSOPSection(section)
            case "contact":
                result.contactDetails = parseContactSection(section)
            default:
                // Handle unknown sections
                break
            }
        }
        
        // Stage 5: Extract metadata (common across all formats)
        result.metadata = extractMetadata(from: fullText)
        
        // Stage 6: Calculate confidence score
        result.confidenceScore = calculateConfidenceScore(result)
        
        return result
    }
    
    /// Legacy method for backward compatibility
    func parsePayslip(from document: PDFDocument) -> ParsedPayslipData {
        do {
            return try parseDocument(document)
        } catch {
            print("Error parsing payslip: \(error)")
            return ParsedPayslipData()
        }
    }
    
    // MARK: - Private Methods - Stage 1
    
    /// Extract full text from a PDF document
    /// - Parameter document: The PDF document
    /// - Returns: The extracted text
    private func extractFullText(from document: PDFDocument) -> String {
        var fullText = ""
        
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            if let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        return fullText
    }
    
    
    // MARK: - Private Methods - Stage 2
    
    
    // MARK: - Private Methods - Stage 3
    
    /// Parse the personal information section
    private func parsePersonalInfoSection(_ section: DocumentSection) -> [String: String] {
        var result: [String: String] = [:]
        
        // Common personal info fields
        let patterns = [
            "name": "(?:Name|Employee Name|Officer Name)[^:]*:[^\\n]*([A-Za-z\\s.]+)",
            "rank": "(?:Rank|Grade|Level)[^:]*:[^\\n]*([A-Za-z0-9\\s.]+)",
            "serviceNumber": "(?:Service No|ID|Number)[^:]*:[^\\n]*([A-Za-z0-9\\s.]+)",
            "accountNumber": "(?:A/C No|Account Number|Bank A/C)[^:]*:[^\\n]*([A-Za-z0-9\\s./]+)",
            "panNumber": "(?:PAN|PAN No|PAN Number)[^:]*:[^\\n]*([A-Za-z0-9\\s]+)"
        ]
        
        // Extract each field using regex
        for (field, pattern) in patterns {
            if let match = section.text.range(of: pattern, options: .regularExpression) {
                let matchText = String(section.text[match])
                
                // Extract the captured group (the actual value)
                if let valueRange = matchText.range(of: ":[^\\n]*([A-Za-z0-9\\s./]+)", options: .regularExpression),
                   let captureRange = matchText[valueRange].range(of: "([A-Za-z0-9\\s./]+)", options: .regularExpression) {
                    let value = String(matchText[valueRange][captureRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    result[field] = value
                }
            }
        }
        
        return result
    }
    
    /// Parse the earnings section
    private func parseEarningsSection(_ section: DocumentSection) -> [String: Double] {
        var result: [String: Double] = [:]
        
        // Look for patterns like "Item Name...........1234.56" or "Item Name: 1234.56"
        let pattern = "([A-Za-z\\s&\\-]+)[.:\\s]+(\\d+(?:[.,]\\d+)?)"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = section.text as NSString
        let matches = regex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let itemNameRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                
                let itemName = nsString.substring(with: itemNameRange)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let valueString = nsString.substring(with: valueRange)
                    .replacingOccurrences(of: ",", with: "")
                
                if let value = Double(valueString), value > 0 {
                    // Normalize the item name using military terminology service
                    let normalizedName = militaryTerminologyService.normalizePayComponent(itemName)
                    result[normalizedName] = value
                }
            }
        }
        
        return result
    }
    
    /// Parse the deductions section
    private func parseDeductionsSection(_ section: DocumentSection) -> [String: Double] {
        // Similar to earnings section but for deductions
        var result: [String: Double] = [:]
        
        // Look for patterns like "Item Name...........1234.56" or "Item Name: 1234.56"
        let pattern = "([A-Za-z\\s&\\-]+)[.:\\s]+(\\d+(?:[.,]\\d+)?)"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = section.text as NSString
        let matches = regex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let itemNameRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                
                let itemName = nsString.substring(with: itemNameRange)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let valueString = nsString.substring(with: valueRange)
                    .replacingOccurrences(of: ",", with: "")
                
                if let value = Double(valueString), value > 0 {
                    // Normalize the item name using military terminology service
                    let normalizedName = militaryTerminologyService.normalizePayComponent(itemName)
                    result[normalizedName] = value
                }
            }
        }
        
        return result
    }
    
    /// Parse the tax section
    private func parseTaxSection(_ section: DocumentSection) -> [String: Double] {
        var result: [String: Double] = [:]
        
        // Common tax info fields
        let patterns = [
            "incomeTax": "(?:Income Tax Deducted|Tax Deducted)[^:]*:[^\\n]*([0-9,.]+)",
            "edCess": "(?:Ed. Cess|Education Cess)[^:]*:[^\\n]*([0-9,.]+)",
            "totalTaxPayable": "(?:Total Tax|Tax Payable)[^:]*:[^\\n]*([0-9,.]+)",
            "grossSalary": "(?:Gross Salary|Gross Income)[^:]*:[^\\n]*([0-9,.]+)",
            "standardDeduction": "(?:Standard Deduction)[^:]*:[^\\n]*([0-9,.]+)",
            "netTaxableIncome": "(?:Net Taxable Income|Taxable Income)[^:]*:[^\\n]*([0-9,.]+)"
        ]
        
        // Extract each field using regex
        for (field, pattern) in patterns {
            if let match = section.text.range(of: pattern, options: .regularExpression) {
                let matchText = String(section.text[match])
                
                // Extract the captured group (the actual value)
                if let valueRange = matchText.range(of: ":[^\\n]*([0-9,.\\-]+)", options: .regularExpression),
                   let captureRange = matchText[valueRange].range(of: "([0-9,.\\-]+)", options: .regularExpression) {
                    let valueString = String(matchText[valueRange][captureRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ",", with: "")
                    
                    if let value = Double(valueString) {
                        result[field] = value
                    }
                }
            }
        }
        
        return result
    }
    
    /// Parse the DSOP section
    private func parseDSOPSection(_ section: DocumentSection) -> [String: Double] {
        var result: [String: Double] = [:]
        
        // Common DSOP info fields
        let patterns = [
            "openingBalance": "(?:Opening Balance)[^:]*:[^\\n]*([0-9,.]+)",
            "subscription": "(?:Subscription|Monthly Contribution)[^:]*:[^\\n]*([0-9,.]+)",
            "miscAdjustment": "(?:Misc Adj|Adjustment)[^:]*:[^\\n]*([0-9,.]+)",
            "withdrawal": "(?:Withdrawal)[^:]*:[^\\n]*([0-9,.]+)",
            "refund": "(?:Refund)[^:]*:[^\\n]*([0-9,.]+)",
            "closingBalance": "(?:Closing Balance)[^:]*:[^\\n]*([0-9,.]+)"
        ]
        
        // Extract each field using regex
        for (field, pattern) in patterns {
            if let match = section.text.range(of: pattern, options: .regularExpression) {
                let matchText = String(section.text[match])
                
                // Extract the captured group (the actual value)
                if let valueRange = matchText.range(of: ":[^\\n]*([0-9,.]+)", options: .regularExpression),
                   let captureRange = matchText[valueRange].range(of: "([0-9,.]+)", options: .regularExpression) {
                    let valueString = String(matchText[valueRange][captureRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ",", with: "")
                    
                    if let value = Double(valueString) {
                        result[field] = value
                    }
                }
            }
        }
        
        return result
    }
    
    /// Parse the contact section
    private func parseContactSection(_ section: DocumentSection) -> [String: String] {
        var result: [String: String] = [:]
        
        // Extract specific contact roles with phone numbers - more flexible pattern
        let contactRolePattern = "(SAO\\s*\\(?LW\\)?|AAO\\s*\\(?LW\\)?|SAO\\s*\\(?TW\\)?|AAO\\s*\\(?TW\\)?|PRO\\s*CIVIL|PRO\\s*ARMY|HELP\\s*DESK)[^0-9]*([0-9][0-9\\-\\s]+)"
        let contactRoleRegex = try? NSRegularExpression(pattern: contactRolePattern, options: [.caseInsensitive])
        let nsString = section.text as NSString
        let contactRoleMatches = contactRoleRegex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in contactRoleMatches {
            if match.numberOfRanges >= 3 {
                let roleRange = match.range(at: 1)
                let phoneRange = match.range(at: 2)
                
                let role = nsString.substring(with: roleRange)
                let phone = nsString.substring(with: phoneRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Map the role to the appropriate key
                let key: String
                let roleUpper = role.uppercased().replacingOccurrences(of: " ", with: "")
                switch roleUpper {
                case "SAO(LW)", "SAOLW": key = "SAOLW"
                case "AAO(LW)", "AAOLW": key = "AAOLW"
                case "SAO(TW)", "SAOTW": key = "SAOTW"
                case "AAO(TW)", "AAOTW": key = "AAOTW"
                case "PROCIVIL": key = "ProCivil"
                case "PROARMY": key = "ProArmy"
                case "HELPDESK": key = "HelpDesk"
                default: key = roleUpper.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: .regularExpression)
                }
                
                result[key] = "\(role): \(phone)"
            }
        }
        
        // Extract general phone numbers with labels
        let labeledPhonePattern = "([A-Za-z\\s]+)\\s*[:-]\\s*([0-9][0-9\\-\\s]+)"
        let labeledPhoneRegex = try? NSRegularExpression(pattern: labeledPhonePattern, options: [])
        let labeledPhoneMatches = labeledPhoneRegex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in labeledPhoneMatches {
            if match.numberOfRanges >= 3 {
                let labelRange = match.range(at: 1)
                let phoneRange = match.range(at: 2)
                
                let label = nsString.substring(with: labelRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let phone = nsString.substring(with: phoneRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip if already added as a specific role
                if !result.values.contains(where: { $0.contains(phone) }) {
                    let key = label.replacingOccurrences(of: " ", with: "")
                    result[key] = "\(label): \(phone)"
                }
            }
        }
        
        // Extract standalone phone numbers
        let phonePattern = "\\(?([0-9][0-9\\-\\s]{7,})\\)?"
        let phoneRegex = try? NSRegularExpression(pattern: phonePattern, options: [])
        let phoneMatches = phoneRegex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for (index, match) in phoneMatches.enumerated() {
            if match.numberOfRanges >= 2 {
                let phoneRange = match.range(at: 1)
                let phone = nsString.substring(with: phoneRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Only add if not already added as part of a specific role or labeled phone
                if !result.values.contains(where: { $0.contains(phone) }) {
                    result["phone\(index + 1)"] = phone
                }
            }
        }
        
        // Extract email addresses
        let emailPattern = "([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})"
        let emailRegex = try? NSRegularExpression(pattern: emailPattern, options: [])
        let emailMatches = emailRegex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for (index, match) in emailMatches.enumerated() {
            if match.numberOfRanges >= 2 {
                let emailRange = match.range(at: 1)
                let email = nsString.substring(with: emailRange)
                
                // Categorize emails if possible
                if email.contains("tada") {
                    result["emailTADA"] = email
                } else if email.contains("ledger") {
                    result["emailLedger"] = email
                } else if email.contains("rankpay") {
                    result["emailRankPay"] = email
                } else if email.contains("general") {
                    result["emailGeneral"] = email
                } else {
                    result["email\(index + 1)"] = email
                }
            }
        }
        
        // Extract website with more flexible pattern
        let websitePatterns = [
            "(?:website|web)[^:]*:[^\\n]*([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})",
            "(?:https?://)?(?:www\\.)?([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})"
        ]
        
        for pattern in websitePatterns {
            if let match = section.text.range(of: pattern, options: .regularExpression) {
                let matchText = String(section.text[match])
                
                // Extract the domain
                if let domainRange = matchText.range(of: "([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})", options: .regularExpression) {
                    let domain = String(matchText[domainRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    result["website"] = domain
                    break
                }
            }
        }
        
        return result
    }
    
    // MARK: - Private Methods - Stage 4
    
    /// Extract metadata from the document text
    private func extractMetadata(from text: String) -> [String: String] {
        var metadata: [String: String] = [:]
        
        // Extract date information
        let datePattern = "(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})"
        let dateRegex = try? NSRegularExpression(pattern: datePattern, options: [])
        let nsString = text as NSString
        let dateMatches = dateRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        if dateMatches.count >= 1 {
            let dateRange = dateMatches[0].range(at: 1)
            metadata["documentDate"] = nsString.substring(with: dateRange)
        }
        
        // Extract month and year
        let monthYearPattern = "(January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{4})"
        if let match = text.range(of: monthYearPattern, options: .regularExpression) {
            let matchText = String(text[match])
            let components = matchText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            if components.count >= 2 {
                metadata["month"] = components[0]
                metadata["year"] = components[1]
            }
        }
        
        // Extract statement period
        let periodPattern = "(?:Statement Period|Pay Period|Period)[^:]*:[^\\n]*([0-9/\\-]+)\\s*(?:to|-)\\s*([0-9/\\-]+)"
        if let match = text.range(of: periodPattern, options: .regularExpression) {
            let matchText = String(text[match])
            
            // Extract start date
            if let startRange = matchText.range(of: ":[^\\n]*([0-9/\\-]+)", options: .regularExpression),
               let startCaptureRange = matchText[startRange].range(of: "([0-9/\\-]+)", options: .regularExpression) {
                metadata["periodStart"] = String(matchText[startRange][startCaptureRange])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Extract end date
            if let endRange = matchText.range(of: "(?:to|-)\\s*([0-9/\\-]+)", options: .regularExpression),
               let endCaptureRange = matchText[endRange].range(of: "([0-9/\\-]+)", options: .regularExpression) {
                metadata["periodEnd"] = String(matchText[endRange][endCaptureRange])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return metadata
    }
    
    // MARK: - Private Methods - Stage 5
    
    /// Calculate confidence score for the extracted data
    private func calculateConfidenceScore(_ data: ParsedPayslipData) -> Double {
        var sectionScores: [Double] = []
        
        // Personal info score
        let personalInfoScore = calculateSectionConfidence(data.personalInfo, expectedKeys: ["name", "rank", "serviceNumber"])
        sectionScores.append(personalInfoScore)
        
        // Earnings score
        let earningsScore = data.earnings.isEmpty ? 0.0 : 0.8
        sectionScores.append(earningsScore)
        
        // Deductions score
        let deductionsScore = data.deductions.isEmpty ? 0.0 : 0.8
        sectionScores.append(deductionsScore)
        
        // Tax details score
        let taxScore = calculateSectionConfidence(data.taxDetails, expectedKeys: ["incomeTax", "totalTaxPayable"])
        sectionScores.append(taxScore)
        
        // DSOP details score
        let dsopScore = calculateSectionConfidence(data.dsopDetails, expectedKeys: ["openingBalance", "closingBalance"])
        sectionScores.append(dsopScore)
        
        // Metadata score
        let metadataScore = calculateSectionConfidence(data.metadata, expectedKeys: ["month", "year"])
        sectionScores.append(metadataScore)
        
        // Overall confidence is the average of section scores
        return sectionScores.reduce(0.0, +) / Double(sectionScores.count)
    }
    
    /// Calculate confidence score for a section based on expected keys
    private func calculateSectionConfidence<T>(_ section: [String: T], expectedKeys: [String]) -> Double {
        if expectedKeys.isEmpty { return 0.0 }
        
        let presentKeys = expectedKeys.filter { section.keys.contains($0) }
        return Double(presentKeys.count) / Double(expectedKeys.count)
    }
}

// MARK: - Extensions

extension EnhancedPDFParser {
    /// Convert ParsedPayslipData to PayslipItem
    func convertToPayslipItem(_ parsedData: ParsedPayslipData) -> PayslipItem {
        // Extract basic information
        let month = parsedData.metadata["month"] ?? "Unknown"
        let year = Int(parsedData.metadata["year"] ?? "0") ?? 0
        
        // Calculate financial totals
        let credits = parsedData.earnings.values.reduce(0, +)
        let debits = parsedData.deductions.values.reduce(0, +)
        
        // Extract DSOP and tax values
        let dsop = parsedData.dsopDetails["subscription"] ?? 0
        let tax = parsedData.taxDetails["incomeTax"] ?? 0
        
        // Extract personal information
        let name = parsedData.personalInfo["name"] ?? "Unknown"
        let accountNumber = parsedData.personalInfo["accountNumber"] ?? ""
        let panNumber = parsedData.personalInfo["panNumber"] ?? ""
        
        // Create PayslipItem
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: nil
        )
        
        // Add earnings and deductions
        payslipItem.earnings = parsedData.earnings
        payslipItem.deductions = parsedData.deductions
        
        return payslipItem
    }
} 