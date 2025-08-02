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
    private let personalInfoSectionParser: PersonalInfoSectionParserProtocol
    private let financialDataSectionParser: FinancialDataSectionParserProtocol
    private let contactInfoSectionParser: ContactInfoSectionParserProtocol
    
    // MARK: - Initialization
    
    init(militaryTerminologyService: MilitaryAbbreviationsService = MilitaryAbbreviationsService.shared,
         contactInfoExtractor: ContactInfoExtractor = ContactInfoExtractor.shared,
         documentStructureIdentifier: DocumentStructureIdentifierProtocol = DocumentStructureIdentifier(),
         documentSectionExtractor: DocumentSectionExtractorProtocol = DocumentSectionExtractor(),
         personalInfoSectionParser: PersonalInfoSectionParserProtocol = PersonalInfoSectionParser(),
         financialDataSectionParser: FinancialDataSectionParserProtocol = FinancialDataSectionParser(),
         contactInfoSectionParser: ContactInfoSectionParserProtocol = ContactInfoSectionParser()) {
        self.militaryTerminologyService = militaryTerminologyService
        self.contactInfoExtractor = contactInfoExtractor
        self.documentStructureIdentifier = documentStructureIdentifier
        self.documentSectionExtractor = documentSectionExtractor
        self.personalInfoSectionParser = personalInfoSectionParser
        self.financialDataSectionParser = financialDataSectionParser
        self.contactInfoSectionParser = contactInfoSectionParser
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
                result.personalInfo = personalInfoSectionParser.parsePersonalInfoSection(section)
            case "earnings":
                result.earnings = financialDataSectionParser.parseEarningsSection(section)
            case "deductions":
                result.deductions = financialDataSectionParser.parseDeductionsSection(section)
            case "tax":
                result.taxDetails = financialDataSectionParser.parseTaxSection(section)
            case "dsop":
                result.dsopDetails = financialDataSectionParser.parseDSOPSection(section)
            case "contact":
                result.contactDetails = contactInfoSectionParser.parseContactSection(section)
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