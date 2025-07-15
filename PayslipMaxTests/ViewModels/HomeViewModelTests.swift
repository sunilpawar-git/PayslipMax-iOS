import XCTest
import Foundation
import Combine
import PDFKit
@testable import PayslipMax

@MainActor
/// Tests focusing on HomeViewModel functionality with TestDIContainer integration
class HomeViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: HomeViewModel!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Use TestDIContainer which provides controlled test services
        let testContainer = TestDIContainer()
        sut = testContainer.makeHomeViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        cancellables = nil
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