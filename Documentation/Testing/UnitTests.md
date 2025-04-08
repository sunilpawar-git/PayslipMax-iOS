# PayslipMaxTests

This directory contains the XCTest-based unit tests for the Payslip Max application.

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