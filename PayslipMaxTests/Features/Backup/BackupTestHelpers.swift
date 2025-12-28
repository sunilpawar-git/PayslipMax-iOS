import Foundation
@testable import PayslipMax

/// Shared helpers for Backup tests
enum BackupTestHelpers {
    static func createMockPayslipDTO(id: UUID = UUID()) -> PayslipDTO {
        return PayslipDTO(
            id: id,
            timestamp: Date(),
            month: "November",
            year: 2025,
            credits: 100000.0,
            debits: 30000.0,
            dsop: 5000.0,
            tax: 10000.0,
            earnings: ["Basic": 80000.0, "DA": 20000.0],
            deductions: ["Tax": 10000.0, "DSOP": 5000.0],
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCD1234E",
            isNameEncrypted: false,
            isAccountNumberEncrypted: false,
            isPanNumberEncrypted: false,
            encryptionVersion: 1,
            pdfData: nil,
            pdfURL: nil,
            isSample: false,
            source: "Test",
            status: "Active",
            notes: nil,
            numberOfPages: 1,
            metadata: [:]
        )
    }

    static func createMockPayslipDTOs(count: Int) -> [PayslipDTO] {
        return (0..<count).map { index in
            var dto = createMockPayslipDTO()
            dto.month = Calendar.current.monthSymbols[(index % 12)]
            dto.year = 2025 - (index / 12)
            return dto
        }
    }

    static func createMockBackupPayslipItem(
        id: UUID = UUID(),
        timestamp: Date = Date()
    ) -> BackupPayslipItem {
        let dto = PayslipDTO(
            id: id,
            timestamp: timestamp,
            month: "November",
            year: 2025,
            credits: 100000.0,
            debits: 30000.0,
            dsop: 5000.0,
            tax: 10000.0,
            earnings: [:],
            deductions: [:],
            name: "Test",
            accountNumber: "123",
            panNumber: "ABC",
            isNameEncrypted: false,
            isAccountNumberEncrypted: false,
            isPanNumberEncrypted: false,
            encryptionVersion: 1,
            pdfData: nil,
            pdfURL: nil,
            isSample: false,
            source: "Test",
            status: "Active",
            notes: nil,
            numberOfPages: 1,
            metadata: [:]
        )
        return BackupPayslipItem(from: dto, encryptedSensitiveData: nil)
    }
}

