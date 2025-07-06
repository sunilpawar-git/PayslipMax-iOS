# Mock Services for PayslipMax Tests

This directory contains mock implementations of various services and protocols used throughout the PayslipMax application. Mocks are organized by functional domain to improve maintainability and discoverability.

## Directory Structure

- **Abbreviation/** - Mocks for abbreviation management
- **Analytics/** - Mocks for analytics and data visualization services
- **Core/** - Mocks for core application services and protocols
- **Error/** - Mocks for error handling components
- **Parser/** - Mocks for PDF parsing and data extraction
- **PDF/** - Mocks for PDF processing and manipulation
- **Payslip/** - Mocks for payslip-specific functionality
- **Repository/** - Mocks for data repositories
- **Security/** - Mocks for security and encryption services
- **UI/** - Mocks for UI components and navigation

## Naming Conventions

All mock files follow these naming conventions:

1. All mock classes start with "Mock" followed by the service name (e.g., `MockEncryptionService`)
2. All mock files are named after their main class (e.g., `MockEncryptionService.swift`)
3. All mocks implement the corresponding protocol from the main application

## Implementation Patterns

All mocks should:

1. Track call counts for each method
2. Provide configurable failure modes
3. Allow customization of return values
4. Include a `reset()` method to restore the mock to its initial state

## Usage in Tests

```swift
// Example usage of mocks in tests
func testDataServiceUsage() async {
    // Setup
    let mockDataService = MockDataService()
    mockDataService.shouldFailSave = false
    
    // Execute
    let result = await sut.saveData(using: mockDataService)
    
    // Verify
    XCTAssertEqual(mockDataService.saveCount, 1)
    XCTAssertTrue(result)
}
```

## Contributing New Mocks

When adding new mocks:

1. Place them in the appropriate domain directory
2. Follow the naming conventions
3. Implement all methods from the corresponding protocol
4. Include tracking variables and configurable behavior
5. Add a `reset()` method
6. Update the test documentation if needed 