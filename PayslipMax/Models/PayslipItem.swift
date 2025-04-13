import Foundation
import SwiftData
import PDFKit

// Adapter to make EncryptionService compatible with SensitiveDataEncryptionService
class EncryptionServiceAdapter: EncryptionServiceProtocolInternal {
    private let encryptionService: EncryptionServiceProtocolInternal
    
    init(encryptionService: EncryptionServiceProtocolInternal) {
        self.encryptionService = encryptionService
    }
    
    func encrypt(_ data: Data) throws -> Data {
        return try encryptionService.encrypt(data)
    }
    
    func decrypt(_ data: Data) throws -> Data {
        return try encryptionService.decrypt(data)
    }
}

// Define the protocol here to avoid import issues
typealias EncryptionServiceProtocolInternal = EncryptionServiceProtocol

@Model
final class PayslipItem: Identifiable, Codable, PayslipProtocol, DocumentManagementProtocol {
    // MARK: - PayslipBaseProtocol Properties
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    
    // MARK: - PayslipDataProtocol Properties
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var earnings: [String: Double]
    var deductions: [String: Double]
    
    // MARK: - PayslipEncryptionProtocol Properties
    var name: String
    var accountNumber: String
    var panNumber: String
    var isNameEncrypted: Bool
    var isAccountNumberEncrypted: Bool
    var isPanNumberEncrypted: Bool
    
    // Additional encryption-related properties
    var sensitiveData: Data?
    var encryptionVersion: Int
    
    // MARK: - PayslipMetadataProtocol Properties
    var pdfData: Data?
    var pdfURL: URL?
    var isSample: Bool
    var source: String
    var status: String
    var notes: String?
    
    // Additional metadata properties
    var pages: [Int: Data]? // Store page data instead of PDFPage objects
    var numberOfPages: Int
    var metadata: [String: String]
    
    // MARK: - DocumentManagementProtocol Properties
    var documentData: Data? {
        get { return pdfData }
        set { pdfData = newValue }
    }
    
    var documentURL: URL? {
        get { return pdfURL }
        set { pdfURL = newValue }
    }
    
    var documentType: String = "PDF"
    
    var documentDate: Date? = nil
    
    // MARK: - Initialization
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         month: String,
         year: Int,
         credits: Double,
         debits: Double,
         dsop: Double,
         tax: Double,
         earnings: [String: Double] = [:],
         deductions: [String: Double] = [:],
         name: String = "",
         accountNumber: String = "",
         panNumber: String = "",
         isNameEncrypted: Bool = false,
         isAccountNumberEncrypted: Bool = false,
         isPanNumberEncrypted: Bool = false,
         sensitiveData: Data? = nil,
         encryptionVersion: Int = 1,
         pdfData: Data? = nil,
         pdfURL: URL? = nil,
         isSample: Bool = false,
         source: String = "Manual",
         status: String = "Active",
         notes: String? = nil,
         pages: [Int: Data]? = nil,
         numberOfPages: Int = 0,
         metadata: [String: String] = [:],
         documentType: String = "PDF",
         documentDate: Date? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits
        self.dsop = dsop
        self.tax = tax
        self.earnings = earnings
        self.deductions = deductions
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.isNameEncrypted = isNameEncrypted
        self.isAccountNumberEncrypted = isAccountNumberEncrypted
        self.isPanNumberEncrypted = isPanNumberEncrypted
        self.sensitiveData = sensitiveData
        self.encryptionVersion = encryptionVersion
        self.pdfData = pdfData
        self.pdfURL = pdfURL
        self.isSample = isSample
        self.source = source
        self.status = status
        self.notes = notes
        self.pages = pages
        self.numberOfPages = numberOfPages
        self.metadata = metadata
        self.documentType = documentType
        self.documentDate = documentDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // PayslipBaseProtocol properties
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // PayslipDataProtocol properties
        month = try container.decode(String.self, forKey: .month)
        year = try container.decode(Int.self, forKey: .year)
        credits = try container.decode(Double.self, forKey: .credits)
        debits = try container.decode(Double.self, forKey: .debits)
        dsop = try container.decode(Double.self, forKey: .dsop)
        tax = try container.decode(Double.self, forKey: .tax)
        earnings = try container.decode([String: Double].self, forKey: .earnings)
        deductions = try container.decode([String: Double].self, forKey: .deductions)
        
        // PayslipEncryptionProtocol properties
        name = try container.decode(String.self, forKey: .name)
        accountNumber = try container.decode(String.self, forKey: .accountNumber)
        panNumber = try container.decode(String.self, forKey: .panNumber)
        isNameEncrypted = try container.decode(Bool.self, forKey: .isNameEncrypted)
        isAccountNumberEncrypted = try container.decode(Bool.self, forKey: .isAccountNumberEncrypted)
        isPanNumberEncrypted = try container.decode(Bool.self, forKey: .isPanNumberEncrypted)
        sensitiveData = try container.decodeIfPresent(Data.self, forKey: .sensitiveData)
        encryptionVersion = try container.decode(Int.self, forKey: .encryptionVersion)
        
        // PayslipMetadataProtocol properties
        pdfData = try container.decodeIfPresent(Data.self, forKey: .pdfData)
        pdfURL = try container.decodeIfPresent(URL.self, forKey: .pdfURL)
        isSample = try container.decode(Bool.self, forKey: .isSample)
        source = try container.decode(String.self, forKey: .source)
        status = try container.decode(String.self, forKey: .status)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        numberOfPages = try container.decode(Int.self, forKey: .numberOfPages)
        metadata = try container.decode([String: String].self, forKey: .metadata)
        
        // DocumentManagementProtocol properties
        documentType = try container.decodeIfPresent(String.self, forKey: .documentType) ?? "PDF"
        documentDate = try container.decodeIfPresent(Date.self, forKey: .documentDate)
        
        // PDFPages can't be directly decoded
        pages = nil
    }
    
    // MARK: - Encoding
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // PayslipBaseProtocol properties
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        
        // PayslipDataProtocol properties
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(credits, forKey: .credits)
        try container.encode(debits, forKey: .debits)
        try container.encode(dsop, forKey: .dsop)
        try container.encode(tax, forKey: .tax)
        try container.encode(earnings, forKey: .earnings)
        try container.encode(deductions, forKey: .deductions)
        
        // PayslipEncryptionProtocol properties
        try container.encode(name, forKey: .name)
        try container.encode(accountNumber, forKey: .accountNumber)
        try container.encode(panNumber, forKey: .panNumber)
        try container.encode(isNameEncrypted, forKey: .isNameEncrypted)
        try container.encode(isAccountNumberEncrypted, forKey: .isAccountNumberEncrypted)
        try container.encode(isPanNumberEncrypted, forKey: .isPanNumberEncrypted)
        try container.encodeIfPresent(sensitiveData, forKey: .sensitiveData)
        try container.encode(encryptionVersion, forKey: .encryptionVersion)
        
        // PayslipMetadataProtocol properties
        try container.encodeIfPresent(pdfData, forKey: .pdfData)
        try container.encodeIfPresent(pdfURL, forKey: .pdfURL)
        try container.encode(isSample, forKey: .isSample)
        try container.encode(source, forKey: .source)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(numberOfPages, forKey: .numberOfPages)
        try container.encode(metadata, forKey: .metadata)
        
        // DocumentManagementProtocol properties
        try container.encode(documentType, forKey: .documentType)
        try container.encodeIfPresent(documentDate, forKey: .documentDate)
    }
    
    // MARK: - PayslipEncryptionProtocol Methods
    
    func encryptSensitiveData() async throws {
        // Get the encryption service through the actor-isolated container
        let container = try await DIContainerResolver.resolveAsync()
        guard let encryptionService = await container.resolveAsync(EncryptionServiceProtocol.self) else {
            return
        }
        
        let dataToEncrypt = "\(name)|\(accountNumber)|\(panNumber)".data(using: .utf8)
        if let data = dataToEncrypt {
            sensitiveData = try encryptionService.encrypt(data)
            isNameEncrypted = true
            isAccountNumberEncrypted = true
            isPanNumberEncrypted = true
        }
    }
    
    func decryptSensitiveData() async throws {
        // Get the encryption service through the actor-isolated container
        let container = try await DIContainerResolver.resolveAsync()
        guard let encryptionService = await container.resolveAsync(EncryptionServiceProtocol.self) else {
            return
        }
        
        guard let sensitiveData = self.sensitiveData else {
            throw NSError(domain: "PayslipEncryption", code: 1, userInfo: [NSLocalizedDescriptionKey: "No sensitive data to decrypt"])
        }
        
        let decryptedData = try encryptionService.decrypt(sensitiveData)
        if let decryptedString = String(data: decryptedData, encoding: .utf8) {
            let components = decryptedString.split(separator: "|")
            if components.count >= 3 {
                name = String(components[0])
                accountNumber = String(components[1])
                panNumber = String(components[2])
                
                isNameEncrypted = false
                isAccountNumberEncrypted = false
                isPanNumberEncrypted = false
            }
        }
    }
    
    // MARK: - PayslipProtocol Methods
    
    func getFullDescription() -> String {
        return "Payslip for \(month) \(year) - Credits: \(credits), Debits: \(debits)"
    }
    
    func getNetAmount() -> Double {
        return credits - debits
    }
    
    func getTotalTax() -> Double {
        return tax
    }
    
    var document: PDFDocument? {
        return pdfDocument
    }
    
    var areAllFieldsEncrypted: Bool {
        return isFullyEncrypted
    }
    
    func formattedDescription() -> String {
        return getFullDescription()
    }
    
    // MARK: - DocumentManagementProtocol Methods
    
    func generateThumbnail() -> UIImage? {
        // Implement the thumbnail generation directly
        guard let data = documentData, let pdfDocument = PDFDocument(data: data) else {
            return nil
        }
        
        guard let pdfPage = pdfDocument.page(at: 0) else {
            return nil
        }
        
        let pageRect = pdfPage.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: pageRect.size))
            
            context.cgContext.translateBy(x: 0, y: pageRect.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            pdfPage.draw(with: .mediaBox, to: context.cgContext)
        }
        
        return image
    }
    
    func validateDocument() -> Bool {
        guard let data = documentData else {
            return false
        }
        
        if documentType.lowercased() == "pdf" {
            return PDFDocument(data: data) != nil
        }
        
        return !data.isEmpty
    }
    
    // MARK: - Helper Methods
    
    func getPage(at index: Int) -> PDFPage? {
        guard let pages = pages, let pageData = pages[index], 
              let pdfDocument = PDFDocument(data: pageData),
              let page = pdfDocument.page(at: 0) else {
            return nil
        }
        return page
    }
    
    func getMetadata(for key: String) -> String? {
        return metadata[key]
    }
    
    // MARK: - CodingKeys
    
    enum CodingKeys: String, CodingKey {
        // PayslipBaseProtocol
        case id, timestamp
        
        // PayslipDataProtocol
        case month, year, credits, debits, dsop, tax, earnings, deductions
        
        // PayslipEncryptionProtocol
        case name, accountNumber, panNumber, isNameEncrypted, isAccountNumberEncrypted, isPanNumberEncrypted
        case sensitiveData, encryptionVersion
        
        // PayslipMetadataProtocol
        case pdfData, pdfURL, isSample, source, status, notes
        case numberOfPages, metadata
        
        // DocumentManagementProtocol
        case documentType, documentDate
    }
}

// MARK: - DIContainer Resolver Helper

/// Helper for resolving the DIContainer.
struct DIContainerResolver {
    static func resolve() throws -> DIContainerProtocol {
        guard let container = Dependencies.container else {
            throw NSError(domain: "DIContainerResolver", code: 1, userInfo: [NSLocalizedDescriptionKey: "DIContainer not initialized"])
        }
        return container
    }
    
    /// Asynchronously resolves the DIContainer in a way that is safe for actor isolation
    @MainActor
    static func resolveAsync() async throws -> DIContainerProtocol {
        guard let container = Dependencies.container else {
            throw NSError(domain: "DIContainerResolver", code: 1, userInfo: [NSLocalizedDescriptionKey: "DIContainer not initialized"])
        }
        return container
    }
}

private struct Dependencies {
    static var container: DIContainerProtocol?
    
    static func setup(container: DIContainerProtocol) {
        self.container = container
    }
}
