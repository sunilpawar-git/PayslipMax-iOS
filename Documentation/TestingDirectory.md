# Testing Infrastructure

This document provides an overview of the various test directories in the PayslipMax project.

## Main Test Directories

### 1. PayslipMaxTests

**Purpose**: Contains XCTest-based unit tests for the PayslipMax application.

**Directory Structure**:
- `Models/`: Tests for model classes
- `ViewModels/`: Tests for view model classes
- `Services/`: Tests for service implementations
- `Mocks/`: Mock implementations for testing
- `Helpers/`: Test helper utilities
- `Integration/`: Tests that verify interactions between components
- `EdgeCases/`: Tests for extreme conditions, performance, and boundary cases

**Running Tests**:
```bash
xcodebuild test -project "PayslipMax.xcodeproj" -scheme "PayslipMax" -destination "platform=iOS Simulator,name=iPhone 16"
```

### 2. PayslipStandaloneTests

**Purpose**: A standalone Swift Package for testing the PayslipItem functionality without being affected by the conflicting definitions in the main app.

**Components**:
- **Models**: Standalone implementations of app models
- **Services**: Mock implementations of services
- **ViewModels**: Standalone implementations of view models

**Running Tests**:
```bash
swift test
```

### 3. PayslipMaxUITests

**Purpose**: Contains UI tests for the PayslipMax iOS application to verify that the user interface works correctly.

**Test Structure**:
- **Screen Objects**: Classes that represent screens in the app
- **Test Cases**: Classes that contain test methods for specific screens
- **UITestHelper**: A utility class with common testing functions

**Running Tests**:
```bash
xcodebuild test -project "PayslipMax.xcodeproj" -scheme "PayslipMaxUITests" -destination "platform=iOS Simulator,name=iPhone 16"
```

### 4. StandaloneTests

**Purpose**: Independent tests that don't rely on the main app's dependencies.

**Organization**:
- AuthTests/
- PayslipTests/
- Utilities/

## Test Writing Best Practices

1. **Follow AAA Pattern**: Arrange-Act-Assert
2. **Use Descriptive Names**: Test method names should describe what's being tested
3. **Independence**: Keep tests independent of each other
4. **Mock Dependencies**: Use mocks to isolate the component under test
5. **Test Edge Cases**: Include tests for boundary conditions and error scenarios
6. **Performance**: Consider performance implications in critical sections

## Cross-Referencing

For more detailed information on the testing strategy, please refer to:
- [TestPlan.md](./TestPlan.md) - Overall testing strategy and organization
- [MockServicesRefactoring.md](./MockServicesRefactoring.md) - Plans for mock services organization 