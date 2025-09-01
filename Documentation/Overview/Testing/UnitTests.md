# PayslipMaxTests

This directory contains the XCTest-based unit tests for the PayslipMax application.

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
xcodebuild test -project "PayslipMax.xcodeproj" -scheme "PayslipMax" -destination "platform=iOS Simulator,name=iPhone 16"
```

To run specific test classes:

```bash
xcodebuild test -project "PayslipMax.xcodeproj" -scheme "PayslipMax" -destination "platform=iOS Simulator,name=iPhone 16" -only-testing:PayslipMaxTests/TestAuthViewModelTests
```