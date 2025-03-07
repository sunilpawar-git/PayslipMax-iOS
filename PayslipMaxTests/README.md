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

### Best Practices

1. Follow the Arrange-Act-Assert pattern
2. Use descriptive test method names
3. Test both success and failure cases
4. Use mocks to isolate the component under test
5. Keep tests independent of each other
6. Avoid testing implementation details 