import Foundation

/// Mock implementation of FinancialDataSectionParserProtocol for testing purposes.
///
/// This mock service simulates financial data parsing functionality without
/// requiring actual regex processing. It provides controllable behavior
/// for testing various financial data extraction scenarios.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockFinancialDataSectionParser: FinancialDataSectionParserProtocol {
    
    // MARK: - Properties
    
    /// The earnings data to return from parsing operations
    var mockEarnings: [String: Double] = [:]
    
    /// The deductions data to return from parsing operations
    var mockDeductions: [String: Double] = [:]
    
    /// The tax data to return from parsing operations
    var mockTaxData: [String: Double] = [:]
    
    /// The DSOP data to return from parsing operations
    var mockDSOPData: [String: Double] = [:]
    
    /// Controls whether operations should fail
    var shouldFail = false
    
    // MARK: - Initialization
    
    init() {
        setupDefaultMockData()
    }
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        setupDefaultMockData()
        shouldFail = false
    }
    
    /// Mock implementation of earnings parsing
    /// - Parameter section: The document section (ignored in mock)
    /// - Returns: The configured mock earnings data
    func parseEarningsSection(_ section: DocumentSection) -> [String: Double] {
        if shouldFail {
            return [:]
        }
        
        return mockEarnings
    }
    
    /// Mock implementation of deductions parsing
    /// - Parameter section: The document section (ignored in mock)
    /// - Returns: The configured mock deductions data
    func parseDeductionsSection(_ section: DocumentSection) -> [String: Double] {
        if shouldFail {
            return [:]
        }
        
        return mockDeductions
    }
    
    /// Mock implementation of tax section parsing
    /// - Parameter section: The document section (ignored in mock)
    /// - Returns: The configured mock tax data
    func parseTaxSection(_ section: DocumentSection) -> [String: Double] {
        if shouldFail {
            return [:]
        }
        
        return mockTaxData
    }
    
    /// Mock implementation of DSOP section parsing
    /// - Parameter section: The document section (ignored in mock)
    /// - Returns: The configured mock DSOP data
    func parseDSOPSection(_ section: DocumentSection) -> [String: Double] {
        if shouldFail {
            return [:]
        }
        
        return mockDSOPData
    }
    
    // MARK: - Private Methods
    
    /// Sets up default mock financial data for testing
    private func setupDefaultMockData() {
        mockEarnings = [
            "Basic Pay": 45000.0,
            "Grade Pay": 5400.0,
            "DA": 13500.0,
            "HRA": 9000.0,
            "Transport Allowance": 3200.0
        ]
        
        mockDeductions = [
            "GPF": 4500.0,
            "CGHS": 500.0,
            "Income Tax": 3200.0,
            "Professional Tax": 200.0
        ]
        
        mockTaxData = [
            "incomeTax": 3200.0,
            "edCess": 96.0,
            "totalTaxPayable": 3296.0,
            "grossSalary": 76100.0,
            "standardDeduction": 50000.0,
            "netTaxableIncome": 26100.0
        ]
        
        mockDSOPData = [
            "openingBalance": 150000.0,
            "subscription": 4500.0,
            "miscAdjustment": 0.0,
            "withdrawal": 0.0,
            "refund": 0.0,
            "closingBalance": 154500.0
        ]
    }
}