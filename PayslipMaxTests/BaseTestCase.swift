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

        // Reset DI container state - use mocks during testing
        DIContainer.shared.useMocks = true
        
        // Clear any cached DI services
        DIContainer.shared.clearAllCaches()
        
        // Register mock feature flag service to prevent real service initialization
        // ServiceRegistry.shared.register(FeatureFlagProtocol.self, instance: MockServiceRegistry.shared.featureFlagService)

        // Clear any cached data or state that might persist between tests
        clearGlobalState()
    }
    
    override func tearDown() {
        // Reset all mock services after test completion
        MockServiceRegistry.shared.resetAllServices()
        
        // Clear any cached DI services
        DIContainer.shared.clearAllCaches()

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