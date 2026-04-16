import XCTest
@testable import PayslipMax

/// Tests that PayslipDetailActionsHandler uses the injected repository
/// rather than pulling one from DIContainer inside action methods.
@MainActor
final class PayslipDetailActionsHandlerTests: BaseTestCase {

    // MARK: - Properties

    private var sut: PayslipDetailActionsHandler!
    private var mockRepo: MockSendablePayslipRepository!
    private var stateManager: PayslipDetailStateManager!
    private var pdfHandler: PayslipDetailPDFHandler!
    private var payslip: PayslipItem!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        payslip = PayslipItem(
            id: UUID(), timestamp: Date(),
            month: "April", year: 2025,
            credits: 50_000, debits: 10_000,
            dsop: 2_500, tax: 7_500,
            name: "Test Soldier",
            accountNumber: "ACC123", panNumber: "PAN123"
        )
        mockRepo = MockSendablePayslipRepository()
        stateManager = PayslipDetailStateManager(payslip: payslip, repository: mockRepo)
        pdfHandler = PayslipDetailPDFHandler(
            payslip: payslip,
            repository: mockRepo,
            pdfService: PayslipPDFService()
        )
        sut = PayslipDetailActionsHandler(
            stateManager: stateManager,
            pdfHandler: pdfHandler,
            payslip: payslip,
            repository: mockRepo
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        stateManager = nil
        pdfHandler = nil
        mockRepo = nil
        payslip = nil
        try super.tearDownWithError()
    }

    // MARK: - Tests

    func test_updateOtherEarnings_callsSaveOnInjectedRepository() async throws {
        // Given: mock repo starts empty
        XCTAssertEqual(mockRepo.payslips.count, 0)

        // When: update other earnings (triggers saveAndNotify)
        payslip.earnings = ["Basic Pay": 40_000, "Other Earnings": 10_000]
        await sut.updateOtherEarnings(["MSP": 5_000])

        // Then: the injected repo received the save call
        XCTAssertEqual(mockRepo.payslips.count, 1, "savePayslip must be called on the injected repository")
    }

    func test_updateOtherDeductions_callsSaveOnInjectedRepository() async throws {
        // Given: mock repo starts empty
        XCTAssertEqual(mockRepo.payslips.count, 0)

        // When: update other deductions (triggers saveAndNotify)
        payslip.deductions = ["DSOP": 2_500, "Other Deductions": 5_000]
        await sut.updateOtherDeductions(["AGIF": 1_000])

        // Then: the injected repo received the save call
        XCTAssertEqual(mockRepo.payslips.count, 1, "savePayslip must be called on the injected repository")
    }

    func test_updateOtherEarnings_withRepositoryError_doesNotCrash() async throws {
        // Given: mock repo will throw
        mockRepo.shouldThrowError = true

        // When: update other earnings — should not crash
        payslip.earnings = ["Basic Pay": 40_000, "Other Earnings": 10_000]
        await sut.updateOtherEarnings(["MSP": 5_000])

        // Then: no payslips saved (error path), state manager records error
        XCTAssertEqual(mockRepo.payslips.count, 0)
    }
}
