# PayslipMax Testing Infrastructure

This directory contains the unit, integration, and functional tests for the PayslipMax application.

## Phase 5: Testing Infrastructure Enhancement Plan

The following plan outlines our approach to enhancing the testing infrastructure as part of our technical debt reduction efforts.

### 1. Split Large Test Files

We're targeting the following files for splitting into more focused test suites:

- `DiagnosticTests.swift` (289 lines) → Split by test category
  - `PayslipItemTests.swift` - Basic model tests
  - `BalanceCalculationTests.swift` - Financial calculation tests
  - `MockServiceTests.swift` - Tests for mock service behavior

- `DocumentAnalysisServiceTests.swift` (491 lines) → Split by analysis type
  - `DocumentCharacteristicsTests.swift` - Tests for document feature detection
  - `DocumentStrategiesTests.swift` - Tests for strategy selection
  - `DocumentParametersTests.swift` - Tests for extraction parameters

### 2. Standardized Test Data Generation

We'll implement a comprehensive test data generation system:

- Create `TestDataGenerator.swift` with factory methods for common test objects
- Implement domain-specific data generators:
  - `PayslipTestDataGenerator.swift`
  - `PDFTestDataGenerator.swift`
  - `SecurityTestDataGenerator.swift`
- Add test data versioning for backward compatibility

### 3. Property-Based Testing

For critical components, we'll implement property-based testing:

- Add a property testing framework
- Create property tests for parsers to validate they work with randomized inputs
- Implement property tests for calculation logic to verify mathematical properties
- Add property tests for data encryption/decryption

### 4. Test Coverage Goals

Our test coverage targets are:

- Core business logic: 95%+ coverage
- Data models: 90%+ coverage
- UI components: 80%+ coverage
- Overall application: 90%+ coverage

### 5. Test Optimization

Performance improvements for the test suite:

- Parallelize test execution where possible
- Reduce redundant setup/teardown
- Optimize mock implementations for faster test execution
- Use shared fixtures where appropriate

## Implementation Timeline

1. **Week 1**: Split large test files
2. **Week 2**: Implement standardized test data generators
3. **Week 3**: Add property-based testing for critical components
4. **Week 4**: Optimize test execution and measure coverage

## Success Criteria

- All test files under 300 lines
- Test suite execution time reduced by 30%
- Test coverage increased to target levels
- No duplicate test data setup code

## Purpose

These tests verify the behavior of individual components of the application, ensuring that they work as expected in isolation.

## Directory Structure

- `Models/`: Tests for model classes
- `ViewModels/`: Tests for view model classes
- `Services/`: Tests for service implementations
- `Mocks/`: Mock implementations for testing
- `Helpers/`: Test helper utilities
- `Integration/`: Tests that verify interactions between components
- `EdgeCases/`: Tests for extreme conditions, performance, and boundary cases

## Running Tests

Run the tests using Xcode's Test Navigator or with the following command:

```bash
xcodebuild test -project "Payslip Max.xcodeproj" -scheme "Payslip Max" -destination "platform=iOS Simulator,name=iPhone 16"
```

To run specific test classes:

```bash
xcodebuild test -project "Payslip Max.xcodeproj" -scheme "Payslip Max" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:PayslipMaxTests/TestAuthViewModelTests
```

## Writing Tests

### Test Class Structure

```swift
import XCTest
@testable import Payslip_Max

class SomeClassTests: XCTestCase {
    // Properties
    var sut: SystemUnderTest!
    var mockDependency: MockDependency!
    
    // Setup
    override func setUp() {
        super.setUp()
        mockDependency = MockDependency()
        sut = SystemUnderTest(dependency: mockDependency)
    }
    
    // Teardown
    override func tearDown() {
        sut = nil
        mockDependency = nil
        super.tearDown()
    }
    
    // Tests
    func testSomeMethod_WhenSomeCondition_ThenExpectedResult() {
        // Given
        // Setup test conditions
        
        // When
        // Call the method being tested
        
        // Then
        // Verify the results
    }
}
```

### Test Categories

The project includes several types of tests:

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test interactions between components
3. **Edge Case Tests**: Test extreme conditions and boundary cases
4. **Performance Tests**: Measure and verify performance characteristics

### Edge Case Testing

For testing edge cases, extreme conditions, and performance, see the `EdgeCases/` directory. These tests verify:

- PDF processing with unusual or corrupted content
- Encryption/decryption with special characters or extreme data sizes
- Data consistency across the entire application flow
- Performance under load and with large datasets
- Handling of boundary values (zero, negative, maximum)
- Concurrent and large-scale operations

### Best Practices

1. Follow the Arrange-Act-Assert pattern
2. Use descriptive test method names
3. Test both success and failure cases
4. Use mocks to isolate the component under test
5. Keep tests independent of each other
6. Avoid testing implementation details 
7. Include appropriate edge case tests for critical components
8. Document test cases clearly, especially for edge cases and performance tests 