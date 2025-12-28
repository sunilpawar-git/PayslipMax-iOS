import Foundation
@testable import PayslipMax

/// Helpers for PDF backup tests
enum PDFBackupTestHelpers {
    static func createTestPayslipWithPDF(pdfData: Data) -> PayslipItem {
        let item = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "November",
            year: 2025,
            credits: 100000.0,
            debits: 30000.0,
            dsop: 5000.0,
            tax: 10000.0,
            pdfData: pdfData
        )
        item.earnings = ["Basic Pay": 80000.0, "DA": 20000.0]
        item.deductions = ["Tax": 10000.0, "DSOP": 5000.0, "Other": 15000.0]
        item.name = "Test User"
        item.accountNumber = "1234567890"
        return item
    }

    static func createRealisticPDFData() -> Data {
        var pdfData = Data()
        pdfData.append(contentsOf: [0x25, 0x50, 0x44, 0x46])
        pdfData.append(Data(repeating: 0x20, count: 100_000 - 4))
        return pdfData
    }

    static func createMockBackupFile(with payslips: [BackupPayslipItem]) -> PayslipBackupFile {
        let earliest = payslips.map { $0.timestamp }.min() ?? Date()
        let latest = payslips.map { $0.timestamp }.max() ?? Date()

        let metadata = BackupMetadata(
            totalPayslips: payslips.count,
            dateRange: BackupDateRange(earliest: earliest, latest: latest),
            estimatedSize: payslips.count * 100_000
        )

        return PayslipBackupFile(
            version: "1.0",
            exportDate: Date(),
            deviceId: "test-device",
            encryptionVersion: 1,
            userName: "Test User",
            payslips: payslips,
            metadata: metadata,
            checksum: ""
        )
    }
}

// MARK: - Mock Repository for PDF Backup Tests

@MainActor
final class MockPDFBackupRepository: SendablePayslipRepository {
    var mockPayslips: [PayslipDTO] = []
    var savedPayslips: [PayslipDTO] = []

    func fetchAllPayslips() async throws -> [PayslipDTO] {
        return mockPayslips
    }

    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipDTO] {
        return mockPayslips
    }

    func fetchPayslip(byId id: UUID) async throws -> PayslipDTO? {
        return mockPayslips.first { $0.id == id }
    }

    func savePayslip(_ dto: PayslipDTO) async throws -> UUID {
        savedPayslips.append(dto)
        return dto.id
    }

    func updatePayslip(withId id: UUID, from dto: PayslipDTO) async throws -> Bool {
        return true
    }

    func deletePayslip(withId id: UUID) async throws -> Bool {
        return true
    }

    func countPayslips() async throws -> Int {
        return mockPayslips.count
    }
}

