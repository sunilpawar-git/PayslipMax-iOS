import XCTest
import Foundation
@testable import PayslipMax

/// Base test case class that provides common setup and teardown functionality for all tests.
/// 
/// This class ensures proper test isolation by resetting shared state between test runs,
/// preventing the common issue where tests pass individually but fail when run as a suite.
@MainActor
class BaseTestCase: XCTestCase {
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Reset all mock services to ensure clean state
        MockServiceRegistry.shared.resetAllServices()
        
        // Reset DI container state
        DIContainer.shared.useMocks = false
        
        // Clear any cached data or state that might persist between tests
        clearGlobalState()
    }
    
    override func tearDown() {
        // Reset all mock services after test completion
        MockServiceRegistry.shared.resetAllServices()
        
        // Clear any remaining state
        clearGlobalState()
        
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Clears any global state that might persist between tests
    private func clearGlobalState() {
        // Override in subclasses if additional cleanup is needed
    }
    
    /// Creates a fresh TestDIContainer for test isolation
    func createTestContainer() -> TestDIContainer {
        return TestDIContainer.forTesting()
    }
}