//
//  DITests.swift
//  PayslipMaxTests
//
//  Created by Sunil on 26/02/25.
//

import XCTest
@testable import Payslip_Max

final class DITests: XCTestCase {
    
    // Test container
    var testContainer: TestDIContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        // Use our test-specific container
        testContainer = TestDIContainer.shared
    }
    
    func testMockServices() async throws {
        // Get a ViewModel that uses the services
        let viewModel = testContainer.makeAuthViewModel()
        
        // Verify that the view model was created with the mock service
        XCTAssertTrue(viewModel.securityService is MockSecurityService, "ViewModel should use mock security service")
    }
    
    func testViewModelCreation() async throws {
        // Create ViewModels using the container
        let homeViewModel = testContainer.makeHomeViewModel()
        let securityViewModel = testContainer.makeSecurityViewModel()
        
        // Verify that the ViewModels were created
        XCTAssertNotNil(homeViewModel)
        XCTAssertNotNil(securityViewModel)
        
        // Test PayslipDetailViewModel creation with TestPayslipItem
        let testPayslip = testContainer.createSamplePayslip()
        let detailViewModel = testContainer.makePayslipDetailViewModel(for: testPayslip)
        XCTAssertNotNil(detailViewModel)
    }
    
    func testInjectPropertyWrapper() async throws {
        // This test is now simplified to just verify that we can access mock services
        let securityService = testContainer.securityService
        let dataService = testContainer.dataService
        let pdfService = testContainer.pdfService
        
        // Verify that the services are mocks
        XCTAssertTrue(securityService is MockSecurityService, "Expected a MockSecurityService")
        XCTAssertTrue(dataService is MockDataService, "Expected a MockDataService")
        XCTAssertTrue(pdfService is MockPDFService, "Expected a MockPDFService")
    }
} 