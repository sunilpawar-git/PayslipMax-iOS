import Foundation

/// Sendable data transfer object for PayslipItem
/// This enables safe passage across async boundaries in Swift 6
/// Maintains all essential data while being Sendable-compliant
struct PayslipDTO: Sendable, Codable, Identifiable, PayslipProtocol {
    // MARK: - Core Properties (PayslipBaseProtocol)
    let id: UUID
    var timestamp: Date

    // MARK: - Payslip Data (PayslipDataProtocol)
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var earnings: [String: Double]
    var deductions: [String: Double]

    // MARK: - Personal Information (PayslipEncryptionProtocol)
    var name: String
    var accountNumber: String
    var panNumber: String
    var isNameEncrypted: Bool
    var isAccountNumberEncrypted: Bool
    var isPanNumberEncrypted: Bool
    let encryptionVersion: Int

    // MARK: - Metadata (PayslipMetadataProtocol)
    var pdfData: Data? = nil  // DTOs don't carry PDF data for Sendable compliance
    var pdfURL: URL? = nil
    var isSample: Bool
    var source: String
    var status: String
    var notes: String?
    let numberOfPages: Int
    let metadata: [String: String]

    // MARK: - Initialization

    /// Creates a PayslipDTO from essential data
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        month: String,
        year: Int,
        credits: Double = 0.0,
        debits: Double = 0.0,
        dsop: Double = 0.0,
        tax: Double = 0.0,
        earnings: [String: Double] = [:],
        deductions: [String: Double] = [:],
        name: String = "",
        accountNumber: String = "",
        panNumber: String = "",
        isNameEncrypted: Bool = false,
        isAccountNumberEncrypted: Bool = false,
        isPanNumberEncrypted: Bool = false,
        encryptionVersion: Int = 1,
        isSample: Bool = false,
        source: String = "Manual",
        status: String = "Active",
        notes: String? = nil,
        numberOfPages: Int = 0,
        metadata: [String: String] = [:]
    ) {
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
        self.encryptionVersion = encryptionVersion
        self.isSample = isSample
        self.source = source
        self.status = status
        self.notes = notes
        self.numberOfPages = numberOfPages
        self.metadata = metadata
    }
}

// MARK: - Computed Properties

extension PayslipDTO {
    /// Net pay calculation (credits - debits)
    var netPay: Double {
        credits - debits
    }

    /// Total earnings from earnings dictionary
    var totalEarnings: Double {
        earnings.values.reduce(0, +)
    }

    /// Total deductions from deductions dictionary
    var totalDeductions: Double {
        deductions.values.reduce(0, +)
    }

    /// Formatted month/year display
    var displayPeriod: String {
        "\(month) \(year)"
    }
}

// MARK: - PayslipItem Conversion

extension PayslipDTO {
    /// Creates a PayslipDTO from a PayslipItem
    /// - Parameter payslip: The PayslipItem to convert
    init(from payslip: PayslipItem) {
        self.init(
            id: payslip.id,
            timestamp: payslip.timestamp,
            month: payslip.month,
            year: payslip.year,
            credits: payslip.credits,
            debits: payslip.debits,
            dsop: payslip.dsop,
            tax: payslip.tax,
            earnings: payslip.earnings,
            deductions: payslip.deductions,
            name: payslip.name,
            accountNumber: payslip.accountNumber,
            panNumber: payslip.panNumber,
            isNameEncrypted: payslip.isNameEncrypted,
            isAccountNumberEncrypted: payslip.isAccountNumberEncrypted,
            isPanNumberEncrypted: payslip.isPanNumberEncrypted,
            encryptionVersion: payslip.encryptionVersion,
            isSample: payslip.isSample,
            source: payslip.source,
            status: payslip.status,
            notes: payslip.notes,
            numberOfPages: payslip.numberOfPages,
            metadata: payslip.metadata
        )
    }
}

extension PayslipItem {
    /// Updates this PayslipItem with data from a PayslipDTO
    /// - Parameter dto: The PayslipDTO containing updated data
    func updateFrom(_ dto: PayslipDTO) {
        self.month = dto.month
        self.year = dto.year
        self.credits = dto.credits
        self.debits = dto.debits
        self.dsop = dto.dsop
        self.tax = dto.tax
        self.earnings = dto.earnings
        self.deductions = dto.deductions
        self.name = dto.name
        self.accountNumber = dto.accountNumber
        self.panNumber = dto.panNumber
        self.isNameEncrypted = dto.isNameEncrypted
        self.isAccountNumberEncrypted = dto.isAccountNumberEncrypted
        self.isPanNumberEncrypted = dto.isPanNumberEncrypted
        self.encryptionVersion = dto.encryptionVersion
        self.isSample = dto.isSample
        self.source = dto.source
        self.status = dto.status
        self.notes = dto.notes
        self.numberOfPages = dto.numberOfPages
        self.metadata = dto.metadata
        self.timestamp = dto.timestamp
    }

    /// Converts this PayslipItem to a PayslipDTO
    /// - Returns: A Sendable PayslipDTO representation
    func toDTO() -> PayslipDTO {
        PayslipDTO(from: self)
    }
}

// MARK: - PayslipEncryptionProtocol Implementation

extension PayslipDTO {
    /// Encrypts sensitive data in the payslip DTO
    /// Note: DTOs are immutable by design, so this method doesn't modify the DTO
    func encryptSensitiveData() async throws {
        // DTOs are immutable snapshots, so encryption would need to be handled
        // at the repository level when converting back to PayslipItem
        print("PayslipDTO: Encryption should be handled at the repository level")
    }

    /// Decrypts sensitive data in the payslip DTO
    /// Note: DTOs are immutable by design, so this method doesn't modify the DTO
    func decryptSensitiveData() async throws {
        // DTOs are immutable snapshots, so decryption would need to be handled
        // at the repository level when converting back to PayslipItem
        print("PayslipDTO: Decryption should be handled at the repository level")
    }
}
