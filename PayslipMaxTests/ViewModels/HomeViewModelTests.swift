import XCTest
import Foundation
import Combine
import PDFKit
@testable import PayslipMax

@MainActor
/// Tests focusing on HomeViewModel functionality with TestDIContainer integration
class HomeViewModelTests: BaseTestCase {
    
    // MARK: - Properties
    
    private var sut: HomeViewModel!
    private var cancellables: Set<AnyCancellable>!
    private var asyncTasks: Set<Task<Void, Never>>!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Use TestDIContainer which provides controlled test services
        let testContainer = TestDIContainer.forTesting()
        sut = testContainer.makeHomeViewModel()
        cancellables = Set<AnyCancellable>()
        asyncTasks = Set<Task<Void, Never>>()
    }
    
    override func tearDownWithError() throws {
        // Cancel all async operations
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Cancel all tasks
        asyncTasks.forEach { $0.cancel() }
        asyncTasks.removeAll()
        
        sut = nil
        cancellables = nil
        asyncTasks = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsDefaultValues() {
        // When: HomeViewModel is initialized through TestDIContainer
        
        // Then: Should have proper default state
        XCTAssertNotNil(sut)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showPasswordEntryView)
        XCTAssertNil(sut.currentPasswordProtectedPDFData)
        XCTAssertTrue(sut.recentPayslips.isEmpty) // TestDIContainer starts with empty data
    }
    
    // MARK: - Data Loading Tests
    
    func testLoadRecentPayslips_WithTestContainer_UpdatesState() async {
        // Given: HomeViewModel with TestDIContainer services
        
        // When: Loading recent payslips
        sut.loadRecentPayslips()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Should complete without error (TestDIContainer handles this)
        // Note: TestDIContainer may return empty data, which is expected in tests
        XCTAssertFalse(sut.isLoading)
    }
}