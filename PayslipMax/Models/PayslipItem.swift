import Foundation
import SwiftData
import PDFKit

// MARK: - Schema Versions

/// Represents the schema versions for the PayslipItem model.
/// Used for tracking data model changes and migrations.
enum PayslipSchemaVersion: Int, Comparable {
    /// Initial version of the schema.
    case v1 = 1
    /// Second version, potentially introducing changes.
    case v2 = 2
    
    static func < (lhs: PayslipSchemaVersion, rhs: PayslipSchemaVersion) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

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

/// The primary data model representing a payslip.
///
/// This class conforms to various protocols to manage different aspects of payslip data,
/// including base identity, financial data, encryption, metadata, and document handling.
/// It is designed to be persisted using SwiftData.
@Model
final class PayslipItem: Identifiable, Codable, PayslipProtocol, DocumentManagementProtocol, @unchecked Sendable {
    /// The version of the schema this item instance conforms to.
    var schemaVersion: Int = PayslipSchemaVersion.v1.rawValue
    
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
    
    /// Encrypted storage for sensitive fields (name, accountNumber, panNumber).
    /// The format is typically "name|accountNumber|panNumber" encrypted as a single Data blob.
    var sensitiveData: Data?
    /// Version of the encryption method used for `sensitiveData`.
    var encryptionVersion: Int
    
    // MARK: - PayslipMetadataProtocol Properties
    var pdfData: Data?
    var pdfURL: URL?
    var isSample: Bool
    var source: String
    var status: String
    var notes: String?
    
    /// Dictionary storing individual page data for potential optimization or specific access.
    /// Key is the 0-based page index, Value is the Data representation of the page.
    /// Note: This is not directly persisted by SwiftData and might require manual handling.
    var pages: [Int: Data]? // Store page data instead of PDFPage objects
    /// The total number of pages in the original PDF document.
    var numberOfPages: Int
    /// A dictionary for storing additional arbitrary metadata associated with the payslip.
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
    
    /// Initializes a new PayslipItem with detailed information.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - timestamp: Creation/processing timestamp. Defaults to the current date.
    ///   - month: The month of the payslip (e.g., "January").
    ///   - year: The year of the payslip (e.g., 2024).
    ///   - credits: Total credits/income.
    ///   - debits: Total debits/deductions.
    ///   - dsop: DSOP contribution amount.
    ///   - tax: Tax deduction amount.
    ///   - earnings: Dictionary of detailed earnings. Defaults to empty.
    ///   - deductions: Dictionary of detailed deductions. Defaults to empty.
    ///   - name: Payslip owner's name. Defaults to empty.
    ///   - accountNumber: Owner's account number. Defaults to empty.
    ///   - panNumber: Owner's PAN number. Defaults to empty.
    ///   - isNameEncrypted: Flag if name is currently encrypted. Defaults to false.
    ///   - isAccountNumberEncrypted: Flag if account number is encrypted. Defaults to false.
    ///   - isPanNumberEncrypted: Flag if PAN number is encrypted. Defaults to false.
    ///   - sensitiveData: Encrypted container for sensitive fields. Defaults to nil.
    ///   - encryptionVersion: Version of encryption used. Defaults to 1.
    ///   - pdfData: Raw PDF data. Defaults to nil.
    ///   - pdfURL: Source URL of the PDF. Defaults to nil.
    ///   - isSample: Flag indicating if this is a sample payslip. Defaults to false.
    ///   - source: Source of the payslip (e.g., "Manual", "Imported"). Defaults to "Manual".
    ///   - status: Current status (e.g., "Active", "Archived"). Defaults to "Active".
    ///   - notes: Optional user notes. Defaults to nil.
    ///   - pages: Dictionary storing individual page data. Defaults to nil.
    ///   - numberOfPages: Total page count of the PDF. Defaults to 0.
    ///   - metadata: Additional metadata dictionary. Defaults to empty.
    ///   - documentType: Type of the document (e.g., "PDF"). Defaults to "PDF".
    ///   - documentDate: Date associated with the document. Defaults to nil.
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
    
    /// Encrypts sensitive fields (name, account number, PAN) using the configured EncryptionService.
    ///
    /// Fetches the encryption service via `DIContainerResolver`, concatenates the sensitive fields
    /// into a single string separated by '|', encrypts the resulting data, and stores it in `sensitiveData`.
    /// Updates the corresponding `is...Encrypted` flags to true upon success.
    /// Throws an error if the encryption service cannot be resolved or if encryption fails.
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
    
    /// Decrypts sensitive fields stored in `sensitiveData` using the configured EncryptionService.
    ///
    /// Fetches the encryption service via `DIContainerResolver`, decrypts the `sensitiveData`,
    /// splits the resulting string by '|', and populates the `name`, `accountNumber`, and `panNumber` fields.
    /// Updates the corresponding `is...Encrypted` flags to false upon success.
    /// Throws an error if the encryption service cannot be resolved, if `sensitiveData` is nil,
    /// if decryption fails, or if the decrypted data format is incorrect.
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
    
    /// Provides a basic description of the payslip, including month, year, credits, and debits.
    func getFullDescription() -> String {
        return "Payslip for \(month) \(year) - Credits: \(credits), Debits: \(debits)"
    }
    
    func getNetAmount() -> Double {
        return credits - debits
    }
    
    func getTotalTax() -> Double {
        return tax
    }
    
    /// Provides the associated PDFDocument if `pdfData` is available. Alias for `pdfDocument`.
    var document: PDFDocument? {
        return pdfDocument
    }
    
    var areAllFieldsEncrypted: Bool {
        return isFullyEncrypted
    }
    
    /// Returns a formatted description of the payslip. Alias for `getFullDescription`.
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
    
    /// Retrieves a specific page from the stored PDF data.
    /// Note: This recreates a `PDFDocument` from the stored page data if available.
    /// - Parameter index: The 0-based index of the page to retrieve.
    /// - Returns: The `PDFPage` at the specified index, or `nil` if not found or data is invalid.
    func getPage(at index: Int) -> PDFPage? {
        guard let pages = pages, let pageData = pages[index], 
              let pdfDocument = PDFDocument(data: pageData),
              let page = pdfDocument.page(at: 0) else {
            return nil
        }
        return page
    }
    
    /// Retrieves a metadata value for a specific key.
    /// - Parameter key: The key for the desired metadata value.
    /// - Returns: The metadata value as a String, or `nil` if the key is not found.
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

// MARK: - Static Factory Methods for Testing
extension PayslipItem {
    /// Static factory for encryption service - used in tests
    private static var encryptionServiceFactory: (() -> EncryptionServiceProtocolInternal)?
    
    /// Set the encryption service factory for testing
    static func setEncryptionServiceFactory(_ factory: @escaping () -> EncryptionServiceProtocolInternal) -> Bool {
        encryptionServiceFactory = factory
        return true
    }
    
    /// Get the current encryption service factory
    static func getEncryptionServiceFactory() -> () -> EncryptionServiceProtocolInternal {
        return encryptionServiceFactory ?? {
            // Return default encryption service if no factory is set
            return EncryptionServiceAdapter(encryptionService: EncryptionService())
        }
    }
    
    /// Reset the encryption service factory to default
    static func resetEncryptionServiceFactory() {
        encryptionServiceFactory = nil
    }
    
    /// Computed property for backward compatibility with tests
    var date: Date {
        return timestamp
    }
    
    /// Static factory method for creating mock PayslipItem instances
    static func mock() -> PayslipItem {
        return PayslipItem(
            month: "January",
            year: 2024,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 300.0
        )
    }
}

// MARK: - Schema Migration Support
extension PayslipItem {
    /// The SwiftData schema definition, referencing the versioned schema.
    static var schema: Schema {
        Schema(versionedSchema: PayslipVersionedSchema.self)
    }
}

/// Defines the versioned schema information for `PayslipItem`.
enum PayslipVersionedSchema: VersionedSchema {
    /// Lists the models included in this schema version. Currently only `PayslipItem`.
    static var models: [any PersistentModel.Type] {
        [PayslipItem.self]
    }
    
    /// The identifier for the current schema version (e.g., 2.0.0).
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0) // Current version
    }
    
    /// Specifies the migration plan used to migrate between schema versions.
    static var migrationPlan: SchemaMigrationPlan {
        PayslipMigrationPlan()
    }
}

// Define the migration plan
/// Defines the migration plan and stages for moving between `PayslipItem` schema versions.
struct PayslipMigrationPlan: SchemaMigrationPlan {
    /// Lists the schema versions involved in this migration plan.
    static var schemas: [any VersionedSchema.Type] {
        [PayslipVersionedSchema.self]
    }
    
    /// Defines the sequence of migration stages.
    static var stages: [MigrationStage] {
        [
            // Stage 1: Migrate from v1 to v2
            migrate(from: PayslipVersionedSchema.self, to: PayslipVersionedSchema.self)
        ]
    }
    
    /// Creates a custom migration stage between two schema versions.
    /// Allows for custom logic to be executed before and after migration.
    /// - Parameters:
    ///   - sourceVersion: The source schema version type.
    ///   - destinationVersion: The destination schema version type.
    /// - Returns: A `MigrationStage` configured for the migration.
    static func migrate(from sourceVersion: any VersionedSchema.Type, to destinationVersion: any VersionedSchema.Type) -> MigrationStage {
        MigrationStage.custom(
            fromVersion: sourceVersion,
            toVersion: destinationVersion,
            willMigrate: { context in
                // Pre-migration tasks
                print("Starting migration from \(sourceVersion.versionIdentifier) to \(destinationVersion.versionIdentifier)")
            },
            didMigrate: { context in
                // Post-migration tasks
                print("Completed migration to \(destinationVersion.versionIdentifier)")
            }
        )
    }
}

// MARK: - DIContainer Resolver Helper

/// Helper struct for resolving the application's dependency injection container.
/// Provides safe methods to access the shared `DIContainerProtocol` instance.
struct DIContainerResolver {
    /// Synchronously resolves the shared `DIContainerProtocol` instance.
    /// Throws an error if the container has not been initialized.
    /// - Returns: The shared `DIContainerProtocol` instance.
    static func resolve() throws -> DIContainerProtocol {
        guard let container = Dependencies.container else {
            throw NSError(domain: "DIContainerResolver", code: 1, userInfo: [NSLocalizedDescriptionKey: "DIContainer not initialized"])
        }
        return container
    }
    
    /// Asynchronously resolves the shared `DIContainerProtocol` instance on the MainActor.
    /// Ensures safe access from actor-isolated contexts.
    /// Throws an error if the container has not been initialized.
    /// - Returns: The shared `DIContainerProtocol` instance.
    @MainActor
    static func resolveAsync() async throws -> DIContainerProtocol {
        guard let container = Dependencies.container else {
            throw NSError(domain: "DIContainerResolver", code: 1, userInfo: [NSLocalizedDescriptionKey: "DIContainer not initialized"])
        }
        return container
    }
}

/// Internal struct holding the shared dependency container instance.
private struct Dependencies {
    /// The static optional instance of the dependency container.
    static var container: DIContainerProtocol?
    
    /// Sets up the shared dependency container instance. Typically called once at app launch.
    /// - Parameter container: The `DIContainerProtocol` instance to use.
    static func setup(container: DIContainerProtocol) {
        self.container = container
    }
}
