import Foundation
import SwiftData
import PDFKit

/// The primary data model representing a payslip.
/// This is the core implementation that combines all protocol requirements
/// with SwiftData persistence capabilities.
@Model
final class PayslipItem: Identifiable, Codable, PayslipProtocol, DocumentManagementProtocol, @unchecked Sendable {
    // Note: @unchecked Sendable is safe because PayslipItem is only accessed on MainActor
    // (via @MainActor delegates and SwiftUI views). SwiftData models are reference types
    // with mutable state, so we use @unchecked Sendable with the guarantee that all
    // access is serialized through MainActor.
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
    var sensitiveData: Data?
    var encryptionVersion: Int

    // MARK: - PayslipMetadataProtocol Properties
    var pdfData: Data?
    var pdfURL: URL?
    var isSample: Bool
    var source: String
    var status: String
    var notes: String?
    var pages: [Int: Data]?
    var numberOfPages: Int
    var metadata: [String: String]

    // MARK: - Confidence Tracking Properties
    /// Overall parsing confidence score (0.0-1.0), nil for legacy payslips
    var confidenceScore: Double?
    /// Per-field confidence scores for detailed breakdown
    var fieldConfidences: [String: Double]?

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

    // MARK: - Basic Initialization

    /// Initializes a new PayslipItem with minimal required information.
    /// Use this for basic payslip creation with default values.
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         month: String,
         year: Int,
         credits: Double = 0.0,
         debits: Double = 0.0) {
        self.id = id
        self.timestamp = timestamp
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits

        // Initialize with default values
        self.dsop = 0.0
        self.tax = 0.0
        self.earnings = [:]
        self.deductions = [:]

        // Initialize encryption properties
        self.name = ""
        self.accountNumber = ""
        self.panNumber = ""
        self.isNameEncrypted = false
        self.isAccountNumberEncrypted = false
        self.isPanNumberEncrypted = false
        self.sensitiveData = nil
        self.encryptionVersion = 1

        // Initialize metadata properties
        self.pdfData = nil
        self.pdfURL = nil
        self.isSample = false
        self.source = "Manual"
        self.status = "Active"
        self.notes = nil
        self.pages = nil
        self.numberOfPages = 0
        self.metadata = [:]

        // Initialize confidence properties (nil for manual entries)
        self.confidenceScore = nil
        self.fieldConfidences = nil
    }

    // MARK: - Full Initialization

    /// Initializes a new PayslipItem with detailed information.
    /// This constructor provides full control over all properties.
    convenience init(id: UUID = UUID(),
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
                     confidenceScore: Double? = nil,
                     fieldConfidences: [String: Double]? = nil) {

        // Initialize with basic properties
        self.init(id: id, timestamp: timestamp, month: month, year: year, credits: credits, debits: debits)

        // Set additional properties
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
        self.confidenceScore = confidenceScore
        self.fieldConfidences = fieldConfidences

        // Initialize page count from PDF data if available
        if let pdfData = pdfData, self.numberOfPages == 0 {
            if let pdfDocument = PDFDocument(data: pdfData) {
                self.numberOfPages = pdfDocument.pageCount
            }
        }
    }

    /// Initialize PayslipItem from PayslipDTO (for conversions back from Sendable DTOs)
    convenience init(from dto: PayslipDTO) {
        self.init(id: dto.id,
                  timestamp: dto.timestamp,
                  month: dto.month,
                  year: dto.year,
                  credits: dto.credits,
                  debits: dto.debits,
                  dsop: dto.dsop,
                  tax: dto.tax,
                  earnings: dto.earnings,
                  deductions: dto.deductions,
                  name: dto.name,
                  accountNumber: dto.accountNumber,
                  panNumber: dto.panNumber,
                  isNameEncrypted: dto.isNameEncrypted,
                  isAccountNumberEncrypted: dto.isAccountNumberEncrypted,
                  isPanNumberEncrypted: dto.isPanNumberEncrypted,
                  encryptionVersion: dto.encryptionVersion,
                  pdfData: dto.pdfData,
                  pdfURL: dto.pdfURL,
                  isSample: dto.isSample,
                  source: dto.source,
                  status: dto.status,
                  notes: dto.notes,
                  numberOfPages: dto.numberOfPages,
                  metadata: dto.metadata,
                  confidenceScore: dto.confidenceScore,
                  fieldConfidences: dto.fieldConfidences)
    }

    // MARK: - Codable Implementation

    /// CodingKeys for PayslipItem serialization
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

        // Confidence Tracking
        case confidenceScore, fieldConfidences
    }
}
