import XCTest
import SwiftData
@testable import PayslipMax

class DeductionTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup in-memory SwiftData context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Deduction.self, configurations: config)
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
        let name = "Income Tax"
        let amount = 2500.0
        let category = "Statutory"
        
        // When
        let deduction = Deduction(id: id, name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(deduction.id, id)
        XCTAssertEqual(deduction.name, name)
        XCTAssertEqual(deduction.amount, amount)
        XCTAssertEqual(deduction.category, category)
    }
    
    func testInitialization_WithDefaultId_GeneratesUniqueId() {
        // Given
        let name = "Provident Fund"
        let amount = 1800.0
        let category = "Voluntary"
        
        // When
        let deduction = Deduction(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertNotNil(deduction.id)
        XCTAssertEqual(deduction.name, name)
        XCTAssertEqual(deduction.amount, amount)
        XCTAssertEqual(deduction.category, category)
    }
    
    func testInitialization_MultipleInstances_GenerateUniqueIds() {
        // Given
        let name1 = "Employee Provident Fund"
        let name2 = "Professional Tax"
        let amount = 500.0
        let category = "Statutory"
        
        // When
        let deduction1 = Deduction(name: name1, amount: amount, category: category)
        let deduction2 = Deduction(name: name2, amount: amount, category: category)
        
        // Then
        XCTAssertNotEqual(deduction1.id, deduction2.id)
    }
    
    // MARK: - Property Tests
    
    func testDeduction_WithZeroAmount_SetsAmountCorrectly() {
        // Given
        let name = "Waived Tax"
        let amount = 0.0
        let category = "Special"
        
        // When
        let deduction = Deduction(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(deduction.amount, 0.0)
    }
    
    func testDeduction_WithNegativeAmount_SetsAmountCorrectly() {
        // Given
        let name = "Tax Refund"
        let amount = -500.0
        let category = "Adjustment"
        
        // When
        let deduction = Deduction(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(deduction.amount, -500.0)
    }
    
    func testDeduction_WithLargeAmount_SetsAmountCorrectly() {
        // Given
        let name = "High Value Deduction"
        let amount = 50000.0
        let category = "Voluntary"
        
        // When
        let deduction = Deduction(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(deduction.amount, 50000.0)
    }
    
    func testDeduction_WithDecimalAmount_SetsAmountCorrectly() {
        // Given
        let name = "Partial Deduction"
        let amount = 1234.56
        let category = "Partial"
        
        // When
        let deduction = Deduction(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(deduction.amount, 1234.56, accuracy: 0.01)
    }
    
    func testDeduction_WithEmptyName_SetsNameCorrectly() {
        // Given
        let name = ""
        let amount = 500.0
        let category = "Statutory"
        
        // When
        let deduction = Deduction(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(deduction.name, "")
    }
    
    func testDeduction_WithEmptyCategory_SetsCategoryCorrectly() {
        // Given
        let name = "Unnamed Deduction"
        let amount = 500.0
        let category = ""
        
        // When
        let deduction = Deduction(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(deduction.category, "")
    }
    
    func testDeduction_WithLongName_SetsNameCorrectly() {
        // Given
        let name = "Very Long Deduction Name That Exceeds Normal Length Expectations For Testing Purposes"
        let amount = 500.0
        let category = "Statutory"
        
        // When
        let deduction = Deduction(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(deduction.name, name)
    }
    
    func testDeduction_WithSpecialCharactersInName_SetsNameCorrectly() {
        // Given
        let name = "Deduction with Special Characters: !@#$%^&*()_+-=[]{}|;':\",./<>?"
        let amount = 500.0
        let category = "Special"
        
        // When
        let deduction = Deduction(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(deduction.name, name)
    }
    
    func testDeduction_WithUnicodeCharacters_SetsNameCorrectly() {
        // Given
        let name = "कटौती 扣除 控除 خصم"
        let amount = 500.0
        let category = "International"
        
        // When
        let deduction = Deduction(name: name, amount: amount, category: category)
        
        // Then
        XCTAssertEqual(deduction.name, name)
    }
    
    // MARK: - SwiftData Persistence Tests
    
    func testDeduction_CanBePersisted() throws {
        // Given
        let deduction = Deduction(name: "Test Deduction", amount: 1000.0, category: "Test")
        
        // When
        modelContext.insert(deduction)
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<Deduction>()
        let fetchedDeductions = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedDeductions.count, 1)
        XCTAssertEqual(fetchedDeductions.first?.name, "Test Deduction")
    }
    
    func testDeduction_UniqueIdConstraint_PreventsDuplicates() throws {
        // Given
        let id = UUID()
        let deduction1 = Deduction(id: id, name: "First Deduction", amount: 1000.0, category: "Test")
        let deduction2 = Deduction(id: id, name: "Second Deduction", amount: 2000.0, category: "Test")
        
        // When
        modelContext.insert(deduction1)
        try modelContext.save()
        
        modelContext.insert(deduction2)
        
        // Then
        XCTAssertThrowsError(try modelContext.save()) { error in
            // Should throw an error due to unique constraint violation
        }
    }
    
    func testDeduction_CanBeFetchedById() throws {
        // Given
        let id = UUID()
        let deduction = Deduction(id: id, name: "Fetchable Deduction", amount: 1500.0, category: "Test")
        
        // When
        modelContext.insert(deduction)
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<Deduction>(predicate: #Predicate { $0.id == id })
        let fetchedDeductions = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedDeductions.count, 1)
        XCTAssertEqual(fetchedDeductions.first?.id, id)
    }
    
    func testDeduction_CanBeFetchedByName() throws {
        // Given
        let name = "Searchable Deduction"
        let deduction = Deduction(name: name, amount: 1200.0, category: "Test")
        
        // When
        modelContext.insert(deduction)
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<Deduction>(predicate: #Predicate { $0.name == name })
        let fetchedDeductions = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedDeductions.count, 1)
        XCTAssertEqual(fetchedDeductions.first?.name, name)
    }
    
    func testDeduction_CanBeFetchedByCategory() throws {
        // Given
        let category = "Statutory"
        let deduction1 = Deduction(name: "Income Tax", amount: 2000.0, category: category)
        let deduction2 = Deduction(name: "Professional Tax", amount: 200.0, category: category)
        let deduction3 = Deduction(name: "Loan EMI", amount: 5000.0, category: "Voluntary")
        
        // When
        modelContext.insert(deduction1)
        modelContext.insert(deduction2)
        modelContext.insert(deduction3)
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<Deduction>(predicate: #Predicate { $0.category == category })
        let fetchedDeductions = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedDeductions.count, 2)
        XCTAssertTrue(fetchedDeductions.allSatisfy { $0.category == category })
    }
    
    func testDeduction_CanBeUpdated() throws {
        // Given
        let deduction = Deduction(name: "Original Name", amount: 1000.0, category: "Original")
        modelContext.insert(deduction)
        try modelContext.save()
        
        // When
        deduction.name = "Updated Name"
        deduction.amount = 2000.0
        deduction.category = "Updated"
        try modelContext.save()
        
        // Then
        let fetchDescriptor = FetchDescriptor<Deduction>(predicate: #Predicate { $0.id == deduction.id })
        let fetchedDeductions = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedDeductions.count, 1)
        
        let updatedDeduction = fetchedDeductions.first!
        XCTAssertEqual(updatedDeduction.name, "Updated Name")
        XCTAssertEqual(updatedDeduction.amount, 2000.0)
        XCTAssertEqual(updatedDeduction.category, "Updated")
    }
    
    func testDeduction_CanBeDeleted() throws {
        // Given
        let deduction = Deduction(name: "Deletable Deduction", amount: 1000.0, category: "Test")
        modelContext.insert(deduction)
        try modelContext.save()
        
        // Verify it exists
        var fetchDescriptor = FetchDescriptor<Deduction>()
        var fetchedDeductions = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedDeductions.count, 1)
        
        // When
        modelContext.delete(deduction)
        try modelContext.save()
        
        // Then
        fetchDescriptor = FetchDescriptor<Deduction>()
        fetchedDeductions = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedDeductions.count, 0)
    }
    
    // MARK: - Edge Case Tests
    
    func testDeduction_WithExtremeValues_HandlesCorrectly() {
        // Given
        let deductions = [
            Deduction(name: "Max Double", amount: Double.greatestFiniteMagnitude, category: "Extreme"),
            Deduction(name: "Min Double", amount: -Double.greatestFiniteMagnitude, category: "Extreme"),
            Deduction(name: "Infinity", amount: Double.infinity, category: "Extreme"),
            Deduction(name: "Negative Infinity", amount: -Double.infinity, category: "Extreme")
        ]
        
        // When/Then
        for deduction in deductions {
            // Should not crash during initialization
            XCTAssertNotNil(deduction.id)
            XCTAssertFalse(deduction.name.isEmpty)
            XCTAssertFalse(deduction.category.isEmpty)
        }
    }
    
    func testDeduction_WithNaNAmount_HandlesCorrectly() {
        // Given
        let deduction = Deduction(name: "NaN Amount", amount: Double.nan, category: "Special")
        
        // When/Then
        XCTAssertTrue(deduction.amount.isNaN)
        XCTAssertEqual(deduction.name, "NaN Amount")
        XCTAssertEqual(deduction.category, "Special")
    }
    
    // MARK: - Common Use Case Tests
    
    func testDeduction_CommonDeductionTypes_CreateCorrectly() {
        // Given
        let commonDeductions = [
            ("Income Tax", 5000.0, "Statutory"),
            ("Employee Provident Fund", 1800.0, "Statutory"),
            ("Professional Tax", 200.0, "Statutory"),
            ("Employee State Insurance", 150.0, "Statutory"),
            ("Term Life Insurance", 500.0, "Voluntary"),
            ("Medical Insurance Premium", 1000.0, "Voluntary"),
            ("Home Loan EMI", 8000.0, "Voluntary"),
            ("Car Loan EMI", 5000.0, "Voluntary"),
            ("Voluntary Provident Fund", 2000.0, "Voluntary"),
            ("Meal Coupon", 300.0, "Welfare")
        ]
        
        // When
        let deductions = commonDeductions.map { name, amount, category in
            Deduction(name: name, amount: amount, category: category)
        }
        
        // Then
        XCTAssertEqual(deductions.count, 10)
        for (index, deduction) in deductions.enumerated() {
            let expected = commonDeductions[index]
            XCTAssertEqual(deduction.name, expected.0)
            XCTAssertEqual(deduction.amount, expected.1)
            XCTAssertEqual(deduction.category, expected.2)
        }
    }
    
    // MARK: - Tax Calculation Helper Tests
    
    func testDeduction_StatutoryDeductions_CanBeFiltered() throws {
        // Given
        let deductions = [
            Deduction(name: "Income Tax", amount: 5000.0, category: "Statutory"),
            Deduction(name: "EPF", amount: 1800.0, category: "Statutory"),
            Deduction(name: "Professional Tax", amount: 200.0, category: "Statutory"),
            Deduction(name: "Home Loan", amount: 8000.0, category: "Voluntary"),
            Deduction(name: "Insurance", amount: 1000.0, category: "Voluntary")
        ]
        
        // When
        for deduction in deductions {
            modelContext.insert(deduction)
        }
        try modelContext.save()
        
        // Then
        let statutoryFetchDescriptor = FetchDescriptor<Deduction>(
            predicate: #Predicate { $0.category == "Statutory" }
        )
        let statutoryDeductions = try modelContext.fetch(statutoryFetchDescriptor)
        
        let voluntaryFetchDescriptor = FetchDescriptor<Deduction>(
            predicate: #Predicate { $0.category == "Voluntary" }
        )
        let voluntaryDeductions = try modelContext.fetch(voluntaryFetchDescriptor)
        
        XCTAssertEqual(statutoryDeductions.count, 3)
        XCTAssertEqual(voluntaryDeductions.count, 2)
        
        let totalStatutoryAmount = statutoryDeductions.reduce(0) { $0 + $1.amount }
        let totalVoluntaryAmount = voluntaryDeductions.reduce(0) { $0 + $1.amount }
        
        XCTAssertEqual(totalStatutoryAmount, 7000.0, accuracy: 0.01)
        XCTAssertEqual(totalVoluntaryAmount, 9000.0, accuracy: 0.01)
    }
    
    func testDeduction_WithPercentageBasedCalculation_WorksCorrectly() {
        // Given - Simulating percentage-based deductions
        let basicSalary = 50000.0
        let epfRate = 0.12 // 12%
        let esicRate = 0.0075 // 0.75%
        
        // When
        let epfDeduction = Deduction(
            name: "Employee Provident Fund",
            amount: basicSalary * epfRate,
            category: "Statutory"
        )
        
        let esicDeduction = Deduction(
            name: "Employee State Insurance",
            amount: basicSalary * esicRate,
            category: "Statutory"
        )
        
        // Then
        XCTAssertEqual(epfDeduction.amount, 6000.0, accuracy: 0.01)
        XCTAssertEqual(esicDeduction.amount, 375.0, accuracy: 0.01)
    }
}