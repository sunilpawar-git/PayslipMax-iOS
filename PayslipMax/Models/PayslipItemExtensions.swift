import Foundation
import PDFKit

// MARK: - Codable Implementation
extension PayslipItem {
    /// Custom decoder initialization
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Initialize properties directly
        let id = try container.decode(UUID.self, forKey: .id)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let month = try container.decode(String.self, forKey: .month)
        let year = try container.decode(Int.self, forKey: .year)
        let credits = try container.decode(Double.self, forKey: .credits)
        let debits = try container.decode(Double.self, forKey: .debits)
        let dsop = try container.decode(Double.self, forKey: .dsop)
        let tax = try container.decode(Double.self, forKey: .tax)
        let earnings = try container.decode([String: Double].self, forKey: .earnings)
        let deductions = try container.decode([String: Double].self, forKey: .deductions)
        let name = try container.decode(String.self, forKey: .name)
        let accountNumber = try container.decode(String.self, forKey: .accountNumber)
        let panNumber = try container.decode(String.self, forKey: .panNumber)
        let isNameEncrypted = try container.decode(Bool.self, forKey: .isNameEncrypted)
        let isAccountNumberEncrypted = try container.decode(Bool.self, forKey: .isAccountNumberEncrypted)
        let isPanNumberEncrypted = try container.decode(Bool.self, forKey: .isPanNumberEncrypted)
        let sensitiveData = try container.decodeIfPresent(Data.self, forKey: .sensitiveData)
        let encryptionVersion = try container.decode(Int.self, forKey: .encryptionVersion)
        let pdfData = try container.decodeIfPresent(Data.self, forKey: .pdfData)
        let pdfURL = try container.decodeIfPresent(URL.self, forKey: .pdfURL)
        let isSample = try container.decode(Bool.self, forKey: .isSample)
        let source = try container.decode(String.self, forKey: .source)
        let status = try container.decode(String.self, forKey: .status)
        let notes = try container.decodeIfPresent(String.self, forKey: .notes)
        let numberOfPages = try container.decode(Int.self, forKey: .numberOfPages)
        let metadata = try container.decode([String: String].self, forKey: .metadata)
        let documentType = try container.decodeIfPresent(String.self, forKey: .documentType) ?? "PDF"
        let documentDate = try container.decodeIfPresent(Date.self, forKey: .documentDate)

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
        self.pages = nil
        self.numberOfPages = numberOfPages
        self.metadata = metadata
        self.documentType = documentType
        self.documentDate = documentDate
    }

    /// Custom encoder implementation
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(credits, forKey: .credits)
        try container.encode(debits, forKey: .debits)
        try container.encode(dsop, forKey: .dsop)
        try container.encode(tax, forKey: .tax)
        try container.encode(earnings, forKey: .earnings)
        try container.encode(deductions, forKey: .deductions)
        try container.encode(name, forKey: .name)
        try container.encode(accountNumber, forKey: .accountNumber)
        try container.encode(panNumber, forKey: .panNumber)
        try container.encode(isNameEncrypted, forKey: .isNameEncrypted)
        try container.encode(isAccountNumberEncrypted, forKey: .isAccountNumberEncrypted)
        try container.encode(isPanNumberEncrypted, forKey: .isPanNumberEncrypted)
        try container.encodeIfPresent(sensitiveData, forKey: .sensitiveData)
        try container.encode(encryptionVersion, forKey: .encryptionVersion)
        try container.encodeIfPresent(pdfData, forKey: .pdfData)
        try container.encodeIfPresent(pdfURL, forKey: .pdfURL)
        try container.encode(isSample, forKey: .isSample)
        try container.encode(source, forKey: .source)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(numberOfPages, forKey: .numberOfPages)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(documentType, forKey: .documentType)
        try container.encodeIfPresent(documentDate, forKey: .documentDate)
    }
}

// MARK: - Protocol Method Implementations
extension PayslipItem {
    // MARK: - PayslipEncryptionProtocol Methods
    // Note: encryptSensitiveData() and decryptSensitiveData() are implemented in PayslipEncryptionMethods.swift
}

// MARK: - Helper Methods
extension PayslipItem {
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

    /// Sets a metadata value for a specific key.
    /// - Parameters:
    ///   - value: The metadata value to set.
    ///   - key: The key for the metadata value.
    func setMetadata(_ value: String, for key: String) {
        // Ensure SwiftData access happens on the main thread
        if Thread.isMainThread {
            metadata[key] = value
        } else {
            DispatchQueue.main.sync {
                metadata[key] = value
            }
        }
    }

    /// Creates a sample payslip for testing and demonstration purposes.
    /// - Parameters:
    ///   - month: The month for the sample payslip.
    ///   - year: The year for the sample payslip.
    /// - Returns: A fully configured sample PayslipItem.
    static func createSample(for month: String, year: Int) -> PayslipItem {
        let earnings: [String: Double] = [
            "Basic Pay": 50000.0,
            "Dearness Allowance": 10000.0,
            "House Rent Allowance": 15000.0,
            "Conveyance Allowance": 19200.0
        ]

        let deductions: [String: Double] = [
            "Provident Fund": 6000.0,
            "Professional Tax": 2350.0,
            "Income Tax": 8500.0
        ]

        let totalEarnings = earnings.values.reduce(0, +)
        let totalDeductions = deductions.values.reduce(0, +)

        return PayslipItem(
            month: month,
            year: year,
            credits: totalEarnings,
            debits: totalDeductions,
            dsop: 1000.0,
            tax: 8500.0,
            earnings: earnings,
            deductions: deductions,
            name: "Sample Employee",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            isSample: true,
            source: "Sample",
            status: "Active",
            numberOfPages: 1,
            metadata: ["Generated": "Sample Data", "Version": "1.0"]
        )
    }

    /// Creates a copy of the payslip with modified properties.
    /// - Parameters:
    ///   - modifications: A closure that modifies the copied payslip.
    /// - Returns: A new PayslipItem instance with the modifications applied.
    func copy(modifications: (inout PayslipItem) -> Void) -> PayslipItem {
        // Use the factory service to create a copy
        return PayslipItemFactory.copy(self, modifications: modifications)
    }
}
