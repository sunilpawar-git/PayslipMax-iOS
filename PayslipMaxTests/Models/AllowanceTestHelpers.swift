import XCTest
import SwiftData
@testable import PayslipMax

/// Shared test helpers and utilities for Allowance model testing
/// Provides common setup, teardown, and test data generation
class AllowanceTestHelpers {
    /// Creates a configured in-memory SwiftData ModelContext for testing
    static func createInMemoryModelContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Allowance.self, configurations: config)
        return ModelContext(container)
    }

    /// Standard test allowances for various scenarios
    struct TestAllowanceData {
        static let houseRentAllowance = Allowance(name: "House Rent Allowance", amount: 15000.0, category: "Standard")
        static let transportAllowance = Allowance(name: "Transport Allowance", amount: 3000.0, category: "Standard")
        static let medicalAllowance = Allowance(name: "Medical Allowance", amount: 5000.0, category: "Standard")
        static let specialAllowance = Allowance(name: "Special Allowance", amount: 10000.0, category: "Special")
        static let overtimeAllowance = Allowance(name: "Overtime Allowance", amount: 5000.0, category: "Variable")
        static let educationAllowance = Allowance(name: "Education Allowance", amount: 1000.0, category: "Welfare")

        static var allCommonAllowances: [Allowance] {
            [houseRentAllowance, transportAllowance, medicalAllowance, specialAllowance, overtimeAllowance, educationAllowance]
        }
    }

    /// Edge case test data
    struct EdgeCaseData {
        static let zeroAmount = Allowance(name: "Zero Allowance", amount: 0.0, category: "Test")
        static let negativeAmount = Allowance(name: "Negative Allowance", amount: -1000.0, category: "Test")
        static let largeAmount = Allowance(name: "Large Allowance", amount: 1000000.0, category: "Test")
        static let decimalAmount = Allowance(name: "Decimal Allowance", amount: 1234.56, category: "Test")
        static let maxDouble = Allowance(name: "Max Double", amount: Double.greatestFiniteMagnitude, category: "Extreme")
        static let minDouble = Allowance(name: "Min Double", amount: -Double.greatestFiniteMagnitude, category: "Extreme")
        static let infinity = Allowance(name: "Infinity", amount: Double.infinity, category: "Extreme")
        static let negativeInfinity = Allowance(name: "Negative Infinity", amount: -Double.infinity, category: "Extreme")
        static let nanAmount = Allowance(name: "NaN Amount", amount: Double.nan, category: "Special")

        static var allEdgeCases: [Allowance] {
            [zeroAmount, negativeAmount, largeAmount, decimalAmount, maxDouble, minDouble, infinity, negativeInfinity, nanAmount]
        }
    }

    /// String test cases for property validation
    struct StringTestData {
        static let emptyName = ""
        static let emptyCategory = ""
        static let longName = "Very Long Allowance Name That Exceeds Normal Length Expectations For Testing Purposes And Validates String Handling Capabilities"
        static let specialCharacters = "Allowance with Special Characters: !@#$%^&*()_+-=[]{}|;':\",./<>?"
        static let unicodeCharacters = "भत्ता 津贴 手当 لوازم"
        static let standardName = "Standard Allowance"
    }

    /// Generates multiple test allowances with unique IDs
    static func generateMultipleAllowances(count: Int, baseName: String = "Test Allowance", baseAmount: Double = 1000.0, category: String = "Test") -> [Allowance] {
        (0..<count).map { index in
            Allowance(name: "\(baseName) \(index + 1)", amount: baseAmount + Double(index * 100), category: category)
        }
    }

    /// Persists an allowance to the model context and saves
    static func persistAllowance(_ allowance: Allowance, in context: ModelContext) throws {
        context.insert(allowance)
        try context.save()
    }

    /// Fetches all allowances from the model context
    static func fetchAllAllowances(from context: ModelContext) throws -> [Allowance] {
        let fetchDescriptor = FetchDescriptor<Allowance>()
        return try context.fetch(fetchDescriptor)
    }

    /// Fetches allowances by predicate
    static func fetchAllowances(with predicate: Predicate<Allowance>, from context: ModelContext) throws -> [Allowance] {
        let fetchDescriptor = FetchDescriptor<Allowance>(predicate: predicate)
        return try context.fetch(fetchDescriptor)
    }

    /// Deletes an allowance from the model context and saves
    static func deleteAllowance(_ allowance: Allowance, from context: ModelContext) throws {
        context.delete(allowance)
        try context.save()
    }

    /// Updates an allowance's properties and saves
    static func updateAllowance(_ allowance: Allowance, name: String? = nil, amount: Double? = nil, category: String? = nil, in context: ModelContext) throws {
        if let name = name { allowance.name = name }
        if let amount = amount { allowance.amount = amount }
        if let category = category { allowance.category = category }
        try context.save()
    }
}

/// Base test case providing common setup and teardown for Allowance tests
class AllowanceTestCase: XCTestCase {
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        modelContext = try AllowanceTestHelpers.createInMemoryModelContext()
    }

    override func tearDownWithError() throws {
        modelContext = nil
        try super.tearDownWithError()
    }
}
