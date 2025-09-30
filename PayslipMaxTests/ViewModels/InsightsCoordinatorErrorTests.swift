import XCTest
import Combine
@testable import PayslipMax

/// Tests for InsightsCoordinator error handling
@MainActor
class InsightsCoordinatorErrorTests: XCTestCase {

    // MARK: - Properties

    private var coordinator: InsightsCoordinator!
    private var mockDataService: MockDataService!
    private var cancellables: Set<AnyCancellable>!
    private var testPayslips: [PayslipItem]!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        mockDataService = MockDataService()
        coordinator = InsightsCoordinator(dataService: mockDataService)
        cancellables = Set<AnyCancellable>()

        // Create test payslips with realistic data
        testPayslips = InsightsViewModelTestHelpers.createStandardTestPayslips()

        // Configure mock data service
        mockDataService.payslipsToReturn = testPayslips
    }

    override func tearDown() {
        cancellables.removeAll()
        coordinator = nil
        mockDataService = nil
        testPayslips = nil
        super.tearDown()
    }

    // MARK: - Error Handling Tests

    func testErrorHandling() {
        let expectation = XCTestExpectation(description: "Error handling")

        coordinator.$error
            .compactMap { $0 }
            .sink { error in
                XCTAssertEqual(error, "Test error")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate error by setting it directly on child ViewModel
        // Since refreshData doesn't use the mock service directly
        coordinator.financialSummary.error = "Test error"

        wait(for: [expectation], timeout: 1.0)
    }

    func testErrorClearance() {
        // First set an error directly on child ViewModel
        coordinator.financialSummary.error = "Test error"

        XCTAssertNotNil(coordinator.error)

        // Then clear the error
        coordinator.financialSummary.error = nil

        XCTAssertNil(coordinator.error)
    }

    // MARK: - Child ViewModel Binding Tests

    func testChildViewModelLoadingStateBinding() {
        let expectation = XCTestExpectation(description: "Loading state binding")

        // Monitor coordinator loading state
        coordinator.$isLoading
            .dropFirst()
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Simulate child ViewModel loading
        coordinator.financialSummary.isLoading = true
        coordinator.refreshData(payslips: testPayslips.map { PayslipDTO(from: $0) })

        wait(for: [expectation], timeout: 2.0)
    }

    func testChildViewModelErrorBinding() {
        let expectation = XCTestExpectation(description: "Error binding")

        coordinator.$error
            .compactMap { $0 }
            .sink { error in
                XCTAssertEqual(error, "Child error")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate child ViewModel error
        coordinator.financialSummary.error = "Child error"

        wait(for: [expectation], timeout: 1.0)
    }

}
