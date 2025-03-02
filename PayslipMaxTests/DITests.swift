//
//  DITests.swift
//  PayslipMaxTests
//
//  Created by Sunil on 26/02/25.
//

import XCTest
@testable import Payslip_Max

class DITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        ServiceLocator.reset()
    }
    
    override func tearDown() {
        ServiceLocator.reset()
        super.tearDown()
    }
    
    func testServiceLocator() {
        // Register a mock service
        let mockDataService = MockDataServiceImpl()
        ServiceLocator.register(type: DataServiceProtocol.self, service: mockDataService)
        
        // Resolve the service
        let resolvedService: DataServiceProtocol? = ServiceLocator.resolve()
        
        // Verify the service was resolved correctly
        XCTAssertNotNil(resolvedService)
        XCTAssertTrue(resolvedService === mockDataService)
    }
    
    func testInject() {
        // Register a mock service
        let mockDataService = MockDataServiceImpl()
        ServiceLocator.register(type: DataServiceProtocol.self, service: mockDataService)
        
        // Create a test class with the injected service
        let testClass = TestClassWithInjection()
        
        // Verify the injected service is the same as the registered service
        XCTAssertTrue(testClass.dataService === mockDataService)
    }
    
    func testMockServices() {
        // Register mock services
        let mockDataService = MockDataServiceImpl()
        let mockSecurityService = MockSecurityServiceImpl()
        
        ServiceLocator.register(type: DataServiceProtocol.self, service: mockDataService)
        ServiceLocator.register(type: SecurityServiceProtocol.self, service: mockSecurityService)
        
        // Resolve the services
        let resolvedDataService: DataServiceProtocol? = ServiceLocator.resolve()
        let resolvedSecurityService: SecurityServiceProtocol? = ServiceLocator.resolve()
        
        // Verify the services were resolved correctly
        XCTAssertNotNil(resolvedDataService)
        XCTAssertNotNil(resolvedSecurityService)
    }
}

// MARK: - Test Classes

class TestViewModel {
    let dataService: DataServiceProtocol
    
    init() {
        self.dataService = ServiceLocator.resolve() ?? MockDataServiceImpl()
    }
}

class TestClassWithInjection {
    @Inject var dataService: DataServiceProtocol
}

// MARK: - Mock Implementations

class MockDataServiceImpl: DataServiceProtocol {
    func fetchPayslips() async throws -> [Payslip] {
        return []
    }
    
    func fetchPayslip(id: String) async throws -> Payslip {
        return Payslip(id: "test", month: "January", year: 2023, grossSalary: 5000, netSalary: 4000, deductions: [])
    }
}

class MockSecurityServiceImpl: SecurityServiceProtocol {
    func encrypt(_ string: String) throws -> String {
        return string
    }
    
    func decrypt(_ string: String) throws -> String {
        return string
    }
} 