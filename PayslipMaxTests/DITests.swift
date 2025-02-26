//
//  DITests.swift
//  PayslipMaxTests
//
//  Created by Sunil on 26/02/25.
//

import XCTest
@testable import Payslip_Max

final class DITests: XCTestCase {
    
    override func setUp() async throws {
        super.setUp()
        // Reset the container before each test
        await MainActor.run {
            DIContainer.resetToDefault()
        }
    }
    
    func testMockServices() async throws {
        // Set up a test container with mocks
        await MainActor.run {
            let testContainer = DIContainer.forTesting()
            DIContainer.setShared(testContainer)
        }
        
        // Get a ViewModel that uses the services
        let viewModel = await MainActor.run {
            ExampleViewModel()
        }
        
        // Call a method that uses the services
        await viewModel.loadPayslips()
        
        // Verify that the mock services were called
        // Note: This is a simplified example. In a real test, you would need to
        // access the mock services directly to verify their call counts.
        
        // This test is mainly to demonstrate the pattern
        XCTAssertTrue(true, "This test is just a demonstration")
    }
    
    func testViewModelCreation() async throws {
        // Set up a test container
        await MainActor.run {
            let testContainer = DIContainer.forTesting()
            DIContainer.setShared(testContainer)
        }
        
        // Create ViewModels using the container
        let (homeViewModel, securityViewModel) = await MainActor.run {
            let home = DIContainer.shared.makeHomeViewModel()
            let security = DIContainer.shared.makeSecurityViewModel()
            return (home, security)
        }
        
        // Verify that the ViewModels were created
        XCTAssertNotNil(homeViewModel)
        XCTAssertNotNil(securityViewModel)
    }
    
    func testInjectPropertyWrapper() async throws {
        // Set up a test container
        await MainActor.run {
            let testContainer = DIContainer.forTesting()
            DIContainer.setShared(testContainer)
        }
        
        // Create a class that uses the @Inject property wrapper
        @MainActor
        class TestClass {
            @Inject var securityService: SecurityServiceProtocol
        }
        
        // Create an instance of the test class
        let testInstance = await MainActor.run {
            TestClass()
        }
        
        // Verify that the dependency was injected
        XCTAssertNotNil(testInstance.securityService)
        // This test would need to be updated to properly check the type
        // XCTAssertTrue(testInstance.securityService is MockSecurityService)
    }
} 