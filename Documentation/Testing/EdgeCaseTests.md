# Edge Case and Performance Tests

This directory contains specialized test cases focused on testing the application's behavior under extreme conditions, edge cases, and performance scenarios.

## Purpose

The tests in this directory aim to:

1. Verify the application's robustness when handling unusual or extreme inputs
2. Test data consistency across components and operations
3. Measure performance under load
4. Ensure proper handling of boundary conditions

## Test Categories

### PDF Processing Edge Cases (`PDFProcessingEdgeCaseTests.swift`)

Tests the PDF processing system with:
- Minimal valid PDF structures
- Partially corrupted PDFs
- Very large PDFs
- PDFs with special characters
- Malformed internal structures
- PDFs with embedded unusual formats
- PDFs with potential security exploits

### Encryption Edge Cases (`EncryptionEdgeCaseTests.swift`) 

Tests the encryption system with:
- Empty strings
- Very large strings
- Special characters
- Emojis and Unicode characters
- Invalid base64 data
- Invalid UTF-8 data
- Repeated operations
- Concurrent operations
- Custom error handling

### Data Consistency Tests (`DataConsistencyTests.swift`)

Tests the consistency of data as it flows through different components:
- PDF service to data service consistency
- Consistency through encryption and decryption
- ViewModel and Model consistency
- Full round-trip flow consistency

### Performance and Boundary Tests (`PerformanceAndBoundaryTests.swift`)

Tests performance and boundary conditions:
- Large batch processing performance
- Encryption performance
- PDF extraction performance
- Maximum value boundaries
- Zero and negative value boundaries
- Large-scale operations

## Running the Tests

Run these tests using Xcode's Test Navigator or with the following command:

```bash
xcodebuild test -project "PayslipMax.xcodeproj" -scheme "PayslipMax" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:PayslipMaxTests/EdgeCases/PDFProcessingEdgeCaseTests
```

Substitute the specific test name as needed.

## When to Use These Tests

- Before releases to ensure robustness
- When making significant changes to core components
- To verify fixes for edge case bugs
- When optimizing performance
- As part of thorough QA processes

## Creating New Edge Case Tests

When adding new edge case tests, consider:

1. What extreme conditions might occur in real-world usage?
2. What unusual inputs could cause failures?
3. What performance bottlenecks might exist?
4. Are there any boundary conditions not covered?
5. How might components interact in unexpected ways?

Always provide detailed test documentation with clear descriptions of the edge case being tested.