import XCTest
import SwiftData
@testable import PayslipMax

class AllowanceTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup in-memory SwiftData context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Allowance.self, configurations: config)
        modelContext = ModelContext(container)
    }
    
    override func tearDownWithError() throws {
        modelContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_WithAllParameters_SetsPropertiesCorrectly() {
        // Given
        let id = UUID()
        let name = "House Rent Allowance"
        let amount = 1500.0
        let category = "Standard"
        
        // When
        let allowance = Allowance(id: id, name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(allowance.id, id)
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, category)
    }
    
    func testInitialization_WithDefaultId_GeneratesUniqueId() {
        // Given
        let name = "Transport Allowance"
        let amount = 800.0
        let category = "Standard"
        
        // When
        let allowance = Allowance(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertNotNil(allowance.id)
        XCTAssertEqual(allowance.name, name)
        XCTAssertEqual(allowance.amount, amount)
        XCTAssertEqual(allowance.category, category)
    }
    
    func testInitialization_MultipleInstances_GenerateUniqueIds() {
        // Given
        let name1 = "Medical Allowance"
        let name2 = "Food Allowance"
        let amount = 500.0
        let category = "Standard"
        
        // When
        let allowance1 = Allowance(name: name1, amount: amount, category: category)
        let allowance2 = Allowance(name: name2, amount: amount, category: category)
        
        // Then
        XCTAssertNotEqual(allowance1.id, allowance2.id)
    }
    
    // MARK: - Property Tests
    
    func testAllowance_WithZeroAmount_SetsAmountCorrectly() {
        // Given
        let name = "Special Allowance"
        let amount = 0.0
        let category = "Special"
        
        // When
        let allowance = Allowance(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(allowance.amount, 0.0)
    }
    
    func testAllowance_WithNegativeAmount_SetsAmountCorrectly() {
        // Given
        let name = "Adjustment Allowance"
        let amount = -100.0
        let category = "Adjustment"
        
        // When
        let allowance = Allowance(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(allowance.amount, -100.0)
    }
    
    func testAllowance_WithLargeAmount_SetsAmountCorrectly() {
        // Given
        let name = "Executive Allowance"
        let amount = 100000.0
        let category = "Executive"
        
        // When
        let allowance = Allowance(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(allowance.amount, 100000.0)
    }
    
    func testAllowance_WithDecimalAmount_SetsAmountCorrectly() {
        // Given
        let name = "Partial Allowance"
        let amount = 1234.56
        let category = "Partial"
        
        // When
        let allowance = Allowance(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(allowance.amount, 1234.56, accuracy: 0.01)
    }
    
    func testAllowance_WithEmptyName_SetsNameCorrectly() {
        // Given
        let name = ""
        let amount = 500.0
        let category = "Standard"
        
        // When
        let allowance = Allowance(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(allowance.name, "")
    }
    
    func testAllowance_WithEmptyCategory_SetsCategoryCorrectly() {
        // Given
        let name = "Unnamed Allowance"
        let amount = 500.0
        let category = ""
        
        // When
        let allowance = Allowance(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(allowance.category, "")
    }
    
    func testAllowance_WithLongName_SetsNameCorrectly() {
        // Given
        let name = "Very Long Allowance Name That Exceeds Normal Length Expectations For Testing Purposes"
        let amount = 500.0
        let category = "Standard"
        
        // When
        let allowance = Allowance(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(allowance.name, name)
    }
    
    func testAllowance_WithSpecialCharactersInName_SetsNameCorrectly() {
        // Given
        let name = "Allowance with Special Characters: !@#$%^&*()_+-=[]{}|;':\",./<>?"
        let amount = 500.0
        let category = "Special"
        
        // When
        let allowance = Allowance(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(allowance.name, name)
    }
    
    func testAllowance_WithUnicodeCharacters_SetsNameCorrectly() {
        // Given
        let name = "भत्ता 津贴 手当 لوازم"
        let amount = 500.0
        let category = "International"
        
        // When
        let allowance = Allowance(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(allowance.name, name)
    }
    
    // MARK: - SwiftData Persistence Tests
    
    func testAllowance_CanBePersisted() throws {
        // Given
        let allowance = Allowance(name: "Test Allowance", amount: 1000.0, category: "Test")
        
        // When
        modelContext.insert(allowance)
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<Allowance>()
        let fetchedAllowances = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedAllowances.count, 1)
        XCTAssertEqual(fetchedAllowances.first?.name, "Test Allowance")
    }
    
    func testAllowance_UniqueIdConstraint_PreventssDuplicates() throws {
        // Given
        let id = UUID()
        let allowance1 = Allowance(id: id, name: "First Allowance", amount: 1000.0, category: "Test")
        let allowance2 = Allowance(id: id, name: "Second Allowance", amount: 2000.0, category: "Test")
        
        // When
        modelContext.insert(allowance1)
        try modelContext.save()
        
        modelContext.insert(allowance2)
        
        // Then
        XCTAssertThrowsError(try modelContext.save()) { error in
            // Should throw an error due to unique constraint violation
        }
    }
    
    func testAllowance_CanBeFetchedById() throws {
        // Given
        let id = UUID()
        let allowance = Allowance(id: id, name: "Fetchable Allowance", amount: 1500.0, category: "Test")
        
        // When
        modelContext.insert(allowance)
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<Allowance>(predicate: #Predicate { $0.id == id })
        let fetchedAllowances = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedAllowances.count, 1)
        XCTAssertEqual(fetchedAllowances.first?.id, id)
    }
    
    func testAllowance_CanBeFetchedByName() throws {
        // Given
        let name = "Searchable Allowance"
        let allowance = Allowance(name: name, amount: 1200.0, category: "Test")
        
        // When
        modelContext.insert(allowance)
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<Allowance>(predicate: #Predicate { $0.name == name })
        let fetchedAllowances = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedAllowances.count, 1)
        XCTAssertEqual(fetchedAllowances.first?.name, name)
    }
    
    func testAllowance_CanBeFetchedByCategory() throws {
        // Given
        let category = "Premium"
        let allowance1 = Allowance(name: "Premium Allowance 1", amount: 1000.0, category: category)
        let allowance2 = Allowance(name: "Premium Allowance 2", amount: 1500.0, category: category)
        let allowance3 = Allowance(name: "Standard Allowance", amount: 800.0, category: "Standard")
        
        // When
        modelContext.insert(allowance1)
        modelContext.insert(allowance2)
        modelContext.insert(allowance3)
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<Allowance>(predicate: #Predicate { $0.category == category })
        let fetchedAllowances = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedAllowances.count, 2)
        XCTAssertTrue(fetchedAllowances.allSatisfy { $0.category == category })
    }
    
    func testAllowance_CanBeUpdated() throws {
        // Given
        let allowance = Allowance(name: "Original Name", amount: 1000.0, category: "Original")
        modelContext.insert(allowance)
        try modelContext.save()
        
        // When
        allowance.name = "Updated Name"
        allowance.amount = 2000.0
        allowance.category = "Updated"
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<Allowance>(predicate: #Predicate { $0.id == allowance.id })
        let fetchedAllowances = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedAllowances.count, 1)
        
        let updatedAllowance = fetchedAllowances.first!
        XCTAssertEqual(updatedAllowance.name, "Updated Name")
        XCTAssertEqual(updatedAllowance.amount, 2000.0)
        XCTAssertEqual(updatedAllowance.category, "Updated")
    }
    
    func testAllowance_CanBeDeleted() throws {
        // Given
        let allowance = Allowance(name: "Deletable Allowance", amount: 1000.0, category: "Test")
        modelContext.insert(allowance)
        try modelContext.save()
        
        // Verify it exists
        var fetchDescriptor = FetchDescriptor<Allowance>()
        var fetchedAllowances = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedAllowances.count, 1)
        
        // When
        modelContext.delete(allowance)
        try modelContext.save()
        
        // Then
        fetchDescriptor = FetchDescriptor<Allowance>()
        fetchedAllowances = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedAllowances.count, 0)
    }
    
    // MARK: - Edge Case Tests
    
    func testAllowance_WithExtremeValues_HandlesCorrectly() {
        // Given
        let allowances = [
            Allowance(name: "Max Double", amount: Double.greatestFiniteMagnitude, category: "Extreme"),
            Allowance(name: "Min Double", amount: -Double.greatestFiniteMagnitude, category: "Extreme"),
            Allowance(name: "Infinity", amount: Double.infinity, category: "Extreme"),
            Allowance(name: "Negative Infinity", amount: -Double.infinity, category: "Extreme")
        ]
        
        // When/Then
        for allowance in allowances {
            // Should not crash during initialization
            XCTAssertNotNil(allowance.id)
            XCTAssertFalse(allowance.name.isEmpty)
            XCTAssertFalse(allowance.category.isEmpty)
        }
    }
    
    func testAllowance_WithNaNAmount_HandlesCorrectly() {
        // Given
        let allowance = Allowance(name: "NaN Amount", amount: Double.nan, category: "Special")
        
        // When/Then
        XCTAssertTrue(allowance.amount.isNaN)
        XCTAssertEqual(allowance.name, "NaN Amount")
        XCTAssertEqual(allowance.category, "Special")
    }
    
    // MARK: - Common Use Case Tests
    
    func testAllowance_CommonAllowanceTypes_CreateCorrectly() {
        // Given
        let commonAllowances = [
            ("House Rent Allowance", 15000.0, "Standard"),
            ("Transport Allowance", 3000.0, "Standard"),
            ("Medical Allowance", 5000.0, "Standard"),
            ("Food Allowance", 2000.0, "Standard"),
            ("Special Allowance", 10000.0, "Special"),
            ("Overtime Allowance", 5000.0, "Variable"),
            ("Shift Allowance", 2500.0, "Variable"),
            ("Education Allowance", 1000.0, "Welfare"),
            ("Mobile Allowance", 500.0, "Communication"),
            ("Fuel Allowance", 3000.0, "Transport")
        ]
        
        // When
        let allowances = commonAllowances.map { name, amount, category in
            Allowance(name: name, amount: amount, category: category)
        }
        
        // Then
        XCTAssertEqual(allowances.count, 10)
        for (index, allowance) in allowances.enumerated() {
            let expected = commonAllowances[index]
            XCTAssertEqual(allowance.name, expected.0)
            XCTAssertEqual(allowance.amount, expected.1)
            XCTAssertEqual(allowance.category, expected.2)
        }
    }
}