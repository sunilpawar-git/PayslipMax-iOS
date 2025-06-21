import SwiftUI
import SwiftData
import Foundation
import Combine
import PDFKit

#if canImport(Vision)
import Vision
#endif

// Adding an extension to Models.PayslipData to make it Equatable
extension Models.PayslipData: Equatable {
    public static func == (lhs: Models.PayslipData, rhs: Models.PayslipData) -> Bool {
        // Compare essential properties to determine equality
        return lhs.name == rhs.name &&
               lhs.totalCredits == rhs.totalCredits &&
               lhs.totalDebits == rhs.totalDebits &&
               lhs.dsop == rhs.dsop &&
               lhs.incomeTax == rhs.incomeTax &&
               lhs.netRemittance == rhs.netRemittance &&
               lhs.allEarnings == rhs.allEarnings &&
               lhs.allDeductions == rhs.allDeductions
    }
}

@MainActor
class PayslipDetailViewModel: ObservableObject, @preconcurrency PayslipViewModelProtocol {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var payslipData: Models.PayslipData
    @Published var showShareSheet = false
    @Published var showDiagnostics = false
    @Published var showOriginalPDF = false
    @Published var showPrintDialog = false
    @Published var unknownComponents: [String: (Double, String)] = [:]
    @Published var pdfData: Data?
    @Published var contactInfo: ContactInfo = ContactInfo()
    
    // MARK: - Private Properties
    private(set) var payslip: AnyPayslip
    private let securityService: SecurityServiceProtocol
    private let dataService: DataServiceProtocol
    
    // MARK: - Services
    private let pdfService: PayslipPDFService
    private let formatterService: PayslipFormatterService
    private let shareService: PayslipShareService
    
    // MARK: - Public Properties
    var pdfFilename: String
    private let parser: PayslipWhitelistParser
    
    // Unique ID for view identification and caching
    var uniqueViewId: String {
        "\(payslip.id)-\(payslip.month)-\(payslip.year)"
    }
    
    // Cache for expensive operations
    private var formattedCurrencyCache: [Double: String] = [:]
    private var shareItemsCache: [Any]?
    private var pdfUrlCache: URL?
    private var loadedAdditionalData = false
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipDetailViewModel with the specified payslip and services.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to display details for.
    ///   - securityService: The security service to use for sensitive data operations.
    ///   - dataService: The data service to use for saving data.
    init(payslip: AnyPayslip, 
         securityService: SecurityServiceProtocol? = nil, 
         dataService: DataServiceProtocol? = nil,
         pdfService: PayslipPDFService? = nil,
         formatterService: PayslipFormatterService? = nil,
         shareService: PayslipShareService? = nil) {
        
        self.payslip = payslip
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        self.pdfService = pdfService ?? PayslipPDFService.shared
        self.formatterService = formatterService ?? PayslipFormatterService.shared
        self.shareService = shareService ?? PayslipShareService.shared
        self.parser = PayslipWhitelistParser()
        
        // Set the PDF filename
        let month = payslip.month
        let year = String(payslip.year)
        self.pdfFilename = "Payslip_\(month)_\(year).pdf"
        
        // Set the initial payslip data
        self.payslipData = Models.PayslipData(from: payslip)
    }
    
    // MARK: - Public Methods
    
    /// Loads additional data from the PDF if available.
    func loadAdditionalData() async {
        // Skip if we've already loaded additional data
        if loadedAdditionalData { return }
        
        isLoading = true
        defer { 
            isLoading = false 
            loadedAdditionalData = true
        }
        
        if let payslipItem = payslip as? PayslipItem, let pdfData = payslipItem.pdfData {
            // Set the pdfData property
            self.pdfData = pdfData
            
            // Use a cached PDFDocument if possible
            let pdfCacheKey = "pdf-\(payslip.id)"
            if let pdfDocument = PDFDocumentCache.shared.getDocument(for: pdfCacheKey) {
                // Use cached document
                let parsedData = parser.parse(pdfDocument: pdfDocument)
                enrichPayslipData(with: parsedData)
                
                // Extract contact information from document text
                extractContactInfo(from: pdfDocument)
            } else if let pdfDocument = PDFDocument(data: pdfData) {
                // Cache the PDF document for future use
                PDFDocumentCache.shared.cacheDocument(pdfDocument, for: pdfCacheKey)
                
                // Parse additional data from the PDF
                let parsedData = parser.parse(pdfDocument: pdfDocument)
                
                // Update the payslipData with additional info from parsing
                enrichPayslipData(with: parsedData)
                
                // Extract contact information from document text
                extractContactInfo(from: pdfDocument)
            }
            
            // Check if contact info is already stored in metadata
            extractContactInfoFromMetadata(payslipItem.metadata)
        }
    }
    
    /// Enriches the payslip data with additional information from parsing
    func enrichPayslipData(with pdfData: [String: String]) {
        // Create temporary data model from the parsed PDF data for merging
        var tempData = Models.PayslipData(from: PayslipItemFactory.createEmpty())
        
        // Add data from PDF parsing
        for (key, value) in pdfData {
            // TODO: Add special handling for certain keys if needed
            
            // Example mapping logic:
            switch key.lowercased() {
            case "rank":
                tempData.rank = value
            case "name":
                tempData.name = value
            case "posting":
                tempData.postedTo = value
            // Add more mappings as needed
            default:
                break
            }
        }
        
        // Merge this data with our payslipData, but preserve core financial data
        mergeParsedData(tempData)
    }
    
    /// Extract contact information directly from PDF text
    private func extractContactInfo(from pdfDocument: PDFDocument) {
        // Extract full text from PDF document
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                fullText += page.string ?? ""
                fullText += "\n\n"
            }
        }
        
        // Use the ContactInfoExtractor to get contact information
        let extractedContactInfo = ContactInfoExtractor.shared.extractContactInfo(from: fullText)
        
        // Merge with any existing contact info
        if !extractedContactInfo.isEmpty {
            // Add any new emails that aren't already in our contact info
            for email in extractedContactInfo.emails {
                if !contactInfo.emails.contains(email) {
                    contactInfo.emails.append(email)
                }
            }
            
            // Add any new phone numbers that aren't already in our contact info
            for phone in extractedContactInfo.phoneNumbers {
                if !contactInfo.phoneNumbers.contains(phone) {
                    contactInfo.phoneNumbers.append(phone)
                }
            }
            
            // Add any new websites that aren't already in our contact info
            for website in extractedContactInfo.websites {
                if !contactInfo.websites.contains(website) {
                    contactInfo.websites.append(website)
                }
            }
        }
    }
    
    /// Extract contact information from payslip metadata
    private func extractContactInfoFromMetadata(_ metadata: [String: String]) {
        // Extract emails
        if let emailsString = metadata["contactEmails"], !emailsString.isEmpty {
            let emails = emailsString.split(separator: "|").map(String.init)
            for email in emails {
                if !contactInfo.emails.contains(email) {
                    contactInfo.emails.append(email)
                }
            }
        }
        
        // Extract phone numbers
        if let phonesString = metadata["contactPhones"], !phonesString.isEmpty {
            let phones = phonesString.split(separator: "|").map(String.init)
            for phone in phones {
                if !contactInfo.phoneNumbers.contains(phone) {
                    contactInfo.phoneNumbers.append(phone)
                }
            }
        }
        
        // Extract websites
        if let websitesString = metadata["contactWebsites"], !websitesString.isEmpty {
            let websites = websitesString.split(separator: "|").map(String.init)
            for website in websites {
                if !contactInfo.websites.contains(website) {
                    contactInfo.websites.append(website)
                }
            }
        }
    }
    
    // Helper to merge parsed data while preserving core financial values
    private func mergeParsedData(_ parsedData: Models.PayslipData) {
        // Personal details (can be overridden by PDF data if available)
        if !parsedData.name.isEmpty { payslipData.name = parsedData.name }
        if !parsedData.rank.isEmpty { payslipData.rank = parsedData.rank }
        if !parsedData.postedTo.isEmpty { payslipData.postedTo = parsedData.postedTo }
        
        // Don't override the core financial data from the original payslip
    }
    
    /// Formats a value as a currency string.
    ///
    /// - Parameter value: The value to format.
    /// - Returns: A formatted currency string.
    func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "₹0.00" }
        
        // Check cache first
        if let cached = formattedCurrencyCache[value] {
            return cached
        }
        
        // Format and cache the result
        let formatted = formatterService.formatCurrency(value)
        formattedCurrencyCache[value] = formatted
        return formatted
    }
    
    /// Formats a year value without group separators
    func formatYear(_ year: Int) -> String {
        return formatterService.formatYear(year)
    }
    
    /// Gets a formatted string representation of the payslip for sharing.
    ///
    /// - Returns: A formatted string with payslip details.
    func getShareText() -> String {
        return formatterService.getShareText(for: payslipData)
    }
    
    /// Get the URL for the original PDF, creating or repairing it if needed
    func getPDFURL() async throws -> URL? {
        // Return cached URL if available
        if let pdfUrlCache = pdfUrlCache {
            return pdfUrlCache
        }
        
        // Get URL and cache it
        let url = try await pdfService.getPDFURL(for: payslip)
        pdfUrlCache = url
        return url
    }
    
    /// Get items to share for this payslip
    func getShareItems() -> [Any]? {
        // Return cached items if available
        if let shareItemsCache = shareItemsCache {
            Logger.info("Using cached share items", category: "PayslipSharing")
            return shareItemsCache
        }
        
        Logger.info("Creating new share items for payslip: \(payslip.month) \(payslip.year)", category: "PayslipSharing")
        
        // Get the share text
        let shareText = getShareText()
        
        // Create share items array with text
        var shareItems: [Any] = [shareText]
        
        // Debug: Check payslip type and PDF data availability
        Logger.info("Payslip type: \(type(of: payslip))", category: "PayslipSharing")
        
        // Try to cast and access PDF data
        if let payslipItemConcrete = payslip as? PayslipItem {
            Logger.info("Successfully cast to PayslipItem", category: "PayslipSharing")
            
            // Enhanced PDF data validation
            if let pdfData = payslipItemConcrete.pdfData {
                Logger.info("Found PDF data with size: \(pdfData.count) bytes", category: "PayslipSharing")
                
                // Validate PDF data is not empty and is valid
                if !pdfData.isEmpty && pdfData.count > 100 { // Basic size check
                    // More flexible PDF validation - check for PDF header anywhere in first 1024 bytes
                    let pdfHeader = Data([0x25, 0x50, 0x44, 0x46]) // %PDF in bytes
                    let searchRange = min(1024, pdfData.count)
                    let searchData = pdfData.prefix(searchRange)
                    
                    if searchData.range(of: pdfHeader) != nil {
                        Logger.info("PDF data is valid, adding PayslipShareItemProvider", category: "PayslipSharing")
                        let provider = PayslipShareItemProvider(
                            pdfData: pdfData,
                            title: "\(payslip.month) \(payslip.year) Payslip"
                        )
                        shareItems.append(provider)
                    } else {
                        Logger.warning("PDF data found but doesn't have valid PDF header", category: "PayslipSharing")
                        Logger.info("First 50 bytes: \(pdfData.prefix(50).map { String(format: "%02x", $0) }.joined(separator: " "))", category: "PayslipSharing")
                        
                        // Try to create a PDF document to validate the data
                        if PDFDocument(data: pdfData) != nil {
                            Logger.info("PDF data is valid according to PDFDocument, adding PayslipShareItemProvider", category: "PayslipSharing")
                            let provider = PayslipShareItemProvider(
                                pdfData: pdfData,
                                title: "\(payslip.month) \(payslip.year) Payslip"
                            )
                            shareItems.append(provider)
                        } else {
                            Logger.error("PDF data is corrupted - PDFDocument cannot parse it", category: "PayslipSharing")
                        }
                    }
                } else {
                    Logger.warning("PDF data found but is too small (\(pdfData.count) bytes) - likely invalid", category: "PayslipSharing")
                }
            } else {
                Logger.warning("No PDF data available in payslip item", category: "PayslipSharing")
                Logger.info("Payslip ID: \(payslipItemConcrete.id), Source: \(payslipItemConcrete.source)", category: "PayslipSharing")
            }
        } else {
            Logger.warning("Could not cast payslip to PayslipItem type", category: "PayslipSharing")
        }
        
        Logger.info("Final share items count: \(shareItems.count)", category: "PayslipSharing")
        
        // Cache the items for future use
        shareItemsCache = shareItems
        
        return shareItems
    }
    
    /// Clears the share items cache to force re-evaluation of PDF data availability
    /// This is useful after PDF data has been updated or when debugging sharing issues
    func clearShareCache() {
        shareItemsCache = nil
        Logger.info("Share items cache cleared for payslip: \(payslip.month) \(payslip.year)", category: "PayslipSharing")
    }
    
    /// Forces a fresh evaluation of share items by clearing cache and regenerating
    func refreshShareItems() -> [Any]? {
        clearShareCache()
        return getShareItems()
    }
    
    /// Updates the payslip with corrected data.
    ///
    /// - Parameter correctedData: The corrected payslip data.
    func updatePayslipData(_ correctedData: Models.PayslipData) {
        Task {
            do {
                guard let payslipItem = payslip as? PayslipItem else {
                    error = AppError.message("Cannot update payslip: Invalid payslip type")
                    return
                }
                
                // Update the payslip item with the corrected data
                payslipItem.name = correctedData.name
                payslipItem.accountNumber = correctedData.accountNumber
                payslipItem.panNumber = correctedData.panNumber
                payslipItem.credits = correctedData.totalCredits
                payslipItem.debits = correctedData.totalDebits
                payslipItem.dsop = correctedData.dsop
                payslipItem.tax = correctedData.incomeTax
                
                // Update earnings/deductions
                payslipItem.earnings = correctedData.allEarnings
                payslipItem.deductions = correctedData.allDeductions
                
                // Initialize the data service if needed
                if !dataService.isInitialized {
                    try await dataService.initialize()
                }
                
                // Save changes
                try await dataService.save(payslipItem)
                
                // Update our local data
                self.payslipData = correctedData
                
                // Clear caches
                formattedCurrencyCache.removeAll()
                shareItemsCache = nil
                
                // Post notification about update
                NotificationCenter.default.post(name: AppNotification.payslipUpdated, object: nil)
            } catch {
                self.error = AppError.message("Failed to update payslip: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Component Categorization
    
    /// Called when a user categorizes an unknown component
    func userCategorizedComponent(code: String, asCategory: String) {
        if let (amount, _) = unknownComponents[code] {
            // Update the category in the unknown components dictionary
            unknownComponents[code] = (amount, asCategory)
            
            // Also update the appropriate earnings or deductions collection
            if asCategory == "earnings" {
                var updatedEarnings = payslipData.allEarnings
                updatedEarnings[code] = amount
                payslipData.allEarnings = updatedEarnings
            } else if asCategory == "deductions" {
                var updatedDeductions = payslipData.allDeductions
                updatedDeductions[code] = amount
                payslipData.allDeductions = updatedDeductions
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
    }
    
    // MARK: - Computed Properties
    
    /// Gets a formatted breakdown of earnings
    var earningsBreakdown: [BreakdownItem] {
        var items: [BreakdownItem] = []
        
        for (key, value) in payslipData.allEarnings {
            if value > 0 {
                items.append(BreakdownItem(
                    label: key,
                    value: formatCurrency(value)
                ))
            }
        }
        
        return items.sorted(by: { $0.label < $1.label })
    }
    
    /// Gets a formatted breakdown of deductions
    var deductionsBreakdown: [BreakdownItem] {
        var items: [BreakdownItem] = []
        
        for (key, value) in payslipData.allDeductions {
            if value > 0 {
                items.append(BreakdownItem(
                    label: key,
                    value: formatCurrency(value)
                ))
            }
        }
        
        // Add tax and DSOP as separate deductions
        if payslipData.incomeTax > 0 {
            items.append(BreakdownItem(
                label: "Income Tax",
                value: formatCurrency(payslipData.incomeTax)
            ))
        }
        
        if payslipData.dsop > 0 {
            items.append(BreakdownItem(
                label: "DSOP",
                value: formatCurrency(payslipData.dsop)
            ))
        }
        
        return items.sorted(by: { $0.label < $1.label })
    }
    
    /// Prints the payslip PDF using the system print dialog
    /// - Parameter presentingVC: The view controller from which to present the print dialog
    func printPDF(from presentingVC: UIViewController) {
        // Use cached data if available
        if let pdfData = self.pdfData {
            let jobName = "Payslip - \(payslip.month) \(payslip.year)"
            PrintService.shared.printPDF(pdfData: pdfData, jobName: jobName, from: presentingVC) {
                self.showPrintDialog = false
            }
            return
        }
        
        // If no cached data, try to get data from URL
        Task {
            do {
                let url = try await getPDFURL()
                if let url = url {
                    let jobName = "Payslip - \(payslip.month) \(payslip.year)"
                    PrintService.shared.printPDF(url: url, jobName: jobName, from: presentingVC) {
                        self.showPrintDialog = false
                    }
                } else {
                    self.error = AppError.message("No PDF data available for printing")
                }
            } catch {
                self.error = AppError.from(error)
            }
        }
    }
}

// MARK: - PDF Document Cache for improved performance

class PDFDocumentCache {
    static let shared = PDFDocumentCache()
    
    private var cache: [String: PDFDocument] = [:]
    private let cacheLimit = 20
    private var lruKeys: [String] = []
    
    private init() {}
    
    func cacheDocument(_ document: PDFDocument, for key: String) {
        // Remove least recently used if at capacity
        if cache.count >= cacheLimit && !lruKeys.isEmpty {
            if let lruKey = lruKeys.first {
                cache.removeValue(forKey: lruKey)
                lruKeys.removeFirst()
            }
        }
        
        // Add to cache
        cache[key] = document
        
        // Update LRU order
        if let index = lruKeys.firstIndex(of: key) {
            lruKeys.remove(at: index)
        }
        lruKeys.append(key)
    }
    
    func getDocument(for key: String) -> PDFDocument? {
        guard let document = cache[key] else { return nil }
        
        // Update LRU order
        if let index = lruKeys.firstIndex(of: key) {
            lruKeys.remove(at: index)
        }
        lruKeys.append(key)
        
        return document
    }
    
    func clearCache() {
        cache.removeAll()
        lruKeys.removeAll()
    }
} 