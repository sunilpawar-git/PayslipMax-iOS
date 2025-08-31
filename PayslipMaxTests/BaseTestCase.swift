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

        // Create a fresh DIContainer for testing with mocks enabled from the start
        let testContainer = DIContainer.forTesting
        DIContainer.setShared(testContainer)

        // Force WebUpload to use mocks to prevent network calls during tests
        DIContainer.shared.toggleWebUploadMock(true)

        // Register mock feature flag service to prevent real service initialization
        // ServiceRegistry.shared.register(FeatureFlagProtocol.self, instance: MockServiceRegistry.shared.featureFlagService)

        // Clear any cached data or state that might persist between tests
        clearGlobalState()
    }
    
    override func tearDown() {
        // Reset all mock services after test completion
        MockServiceRegistry.shared.resetAllServices()
        
        // Reset to production DIContainer
        let prodContainer = DIContainer()
        DIContainer.setShared(prodContainer)

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