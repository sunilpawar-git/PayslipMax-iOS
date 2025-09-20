import XCTest
import SwiftData
@testable import PayslipMax

@MainActor
final class PayslipItemTests: XCTestCase {

    var sut: PayslipItem!
    var mockEncryptionService: MockEncryptionService!
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!

    override func setUp() {
        super.setUp()

        // Create in-memory test model container
        let schema = Schema([PayslipItem.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Failed to create test ModelContainer: \(error)")
        }

        // Create a mock encryption service
        mockEncryptionService = MockEncryptionService()

        // Configure the encryption service factory to return our mock
        _ = PayslipItem.setEncryptionServiceFactory { [self] in
            return mockEncryptionService as EncryptionServiceProtocolInternal
        }

        // Create a test instance with known values
        sut = PayslipItem(
            month: "January",
            year: 2024,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 800.0,
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            pdfData: nil
        )

        // Insert into test context for proper memory management
        modelContext.insert(sut)

        // Add test earnings and deductions
        sut.earnings = [
            "Basic Pay": 3000.0,
            "DA": 1500.0,
            "MSP": 500.0
        ]

        sut.deductions = [
            "DSOP": 500.0,
            "ITAX": 800.0,
            "AGIF": 200.0
        ]
    }

    override func tearDown() {
        PayslipItem.resetEncryptionServiceFactory()
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    func testSimpleCalculation() {
        // This test doesn't rely on any external services
        let a = 10
        let b = 20
        XCTAssertEqual(a + b, 30, "Basic addition should work")
    }

    func testInitialization() {
        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.month, "January")
        XCTAssertEqual(sut.year, 2024)
        XCTAssertEqual(sut.credits, 5000.0)
        XCTAssertEqual(sut.debits, 1000.0)
        XCTAssertEqual(sut.dsop, 500.0)
        XCTAssertEqual(sut.tax, 800.0)
    }

    func testBasicCalculations() {
        // Test basic financial calculations
        let expectedNet = sut.credits - sut.debits  // Net = credits - debits
        XCTAssertEqual(expectedNet, 4000.0, "Net calculation should be correct")

        // Test that earnings dictionary is properly set
        XCTAssertEqual(sut.earnings["Basic Pay"], 3000.0)
        XCTAssertEqual(sut.earnings["DA"], 1500.0)
        XCTAssertEqual(sut.earnings["MSP"], 500.0)

        // Test that deductions dictionary is properly set
        XCTAssertEqual(sut.deductions["DSOP"], 500.0)
        XCTAssertEqual(sut.deductions["ITAX"], 800.0)
        XCTAssertEqual(sut.deductions["AGIF"], 200.0)
    }

    func testEncryptionServiceFactory() {
        // Given
        let customMockService = MockEncryptionService()

        // When
        _ = PayslipItem.setEncryptionServiceFactory {
            return customMockService as EncryptionServiceProtocolInternal
        }

        // Then
        let factory = PayslipItem.getEncryptionServiceFactory()
        let service = factory()
        XCTAssertTrue(service === customMockService)
    }

    func testPayslipDataIntegrity() {
        // Test that the payslip maintains data integrity
        let originalName = sut.name
        let originalAccount = sut.accountNumber
        let originalPan = sut.panNumber

        // Modify the payslip
        sut.name = "Modified Name"
        sut.accountNumber = "9876543210"
        sut.panNumber = "ZYXWV5432A"

        // Verify changes were applied
        XCTAssertEqual(sut.name, "Modified Name")
        XCTAssertEqual(sut.accountNumber, "9876543210")
        XCTAssertEqual(sut.panNumber, "ZYXWV5432A")

        // Verify they're different from original
        XCTAssertNotEqual(sut.name, originalName)
        XCTAssertNotEqual(sut.accountNumber, originalAccount)
        XCTAssertNotEqual(sut.panNumber, originalPan)
    }

    func testPayslipProperties() {
        // Test all basic properties are accessible
        XCTAssertEqual(sut.id.uuidString.count, 36) // UUID string length
        XCTAssertNotNil(sut.timestamp)
        XCTAssertEqual(sut.month, "January")
        XCTAssertEqual(sut.year, 2024)
        XCTAssertEqual(sut.credits, 5000.0)
        XCTAssertEqual(sut.debits, 1000.0)
        XCTAssertEqual(sut.dsop, 500.0)
        XCTAssertEqual(sut.tax, 800.0)

        // Test encryption flags
        XCTAssertFalse(sut.isNameEncrypted)
        XCTAssertFalse(sut.isAccountNumberEncrypted)
        XCTAssertFalse(sut.isPanNumberEncrypted)
    }

    func testMockEncryptionServiceIntegration() {
        // Test that our mock service is properly configured
        XCTAssertNotNil(mockEncryptionService)
        XCTAssertFalse(mockEncryptionService.shouldFailEncryption)
        XCTAssertFalse(mockEncryptionService.shouldFailDecryption)
        XCTAssertEqual(mockEncryptionService.encryptionCount, 0)
        XCTAssertEqual(mockEncryptionService.decryptionCount, 0)

        // Test that the factory returns our mock service
        let factory = PayslipItem.getEncryptionServiceFactory()
        let service = factory()
        XCTAssertTrue(service === mockEncryptionService)
    }

    func testFactoryReset() {
        // Given
        let customMockService = MockEncryptionService()
        _ = PayslipItem.setEncryptionServiceFactory {
            return customMockService as EncryptionServiceProtocolInternal
        }

        // When
        PayslipItem.resetEncryptionServiceFactory()

        // Then
        let newService = PayslipItem.getEncryptionServiceFactory()()
        XCTAssertNotNil(newService, "Factory should return a non-nil service")
        XCTAssertFalse(newService === customMockService, "Factory should return a different instance after reset")
    }

    func testPayslipCreationWithDifferentValues() {
        // Test creating payslip with different values
        let newPayslip = PayslipItem(
            month: "February",
            year: 2025,
            credits: 6000.0,
            debits: 1200.0,
            dsop: 600.0,
            tax: 900.0,
            name: "Another User",
            accountNumber: "0987654321",
            panNumber: "FGHIJ6789K",
            pdfData: nil
        )

        XCTAssertEqual(newPayslip.month, "February")
        XCTAssertEqual(newPayslip.year, 2025)
        XCTAssertEqual(newPayslip.credits, 6000.0)
        XCTAssertEqual(newPayslip.debits, 1200.0)
        XCTAssertEqual(newPayslip.dsop, 600.0)
        XCTAssertEqual(newPayslip.tax, 900.0)
        XCTAssertEqual(newPayslip.name, "Another User")
        XCTAssertEqual(newPayslip.accountNumber, "0987654321")
        XCTAssertEqual(newPayslip.panNumber, "FGHIJ6789K")
    }
}
