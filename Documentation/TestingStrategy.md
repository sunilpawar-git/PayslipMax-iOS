# Testing Strategy

## Overview

Payslip Max follows a comprehensive testing strategy to ensure the quality, reliability, and correctness of the application. This document outlines the different types of tests used in the project, how they are organized, and best practices for writing and maintaining tests.

## Test Types

### Unit Tests

Unit tests focus on testing individual components in isolation. In Payslip Max, unit tests are primarily used for:

- **ViewModels**: Testing the business logic and state management in ViewModels.
- **Services**: Testing the functionality of service classes.
- **Utilities**: Testing utility functions and helper classes.

### Integration Tests

Integration tests focus on testing the interaction between multiple components. In Payslip Max, integration tests are used for:

- **Service Interactions**: Testing how different services interact with each other.
- **ViewModel-Service Interactions**: Testing how ViewModels interact with services.

### UI Tests

UI tests focus on testing the user interface and user interactions. In Payslip Max, UI tests are used for:

- **Screen Navigation**: Testing navigation between different screens.
- **User Interactions**: Testing how the UI responds to user interactions.
- **Visual Appearance**: Testing the visual appearance of UI components.

## Test Organization

Tests in Payslip Max are organized in a way that mirrors the structure of the main codebase:

- **Unit Tests**: Located in the `PayslipMaxTests` target, with a directory structure that mirrors the main codebase.
- **UI Tests**: Located in the `PayslipMaxUITests` target.

## Mocking

Mocking is a key part of the testing strategy in Payslip Max. Mock implementations of services and other dependencies are used to isolate components during testing.

### Mock Services

Mock services are implementations of service protocols that provide controlled behavior for testing purposes. They are defined in the `PayslipMaxTests/Helpers/MockServices.swift` file.

```swift
class MockNetworkService: NetworkServiceProtocol {
    var lastRequestURL: URL?
    var lastRequestBody: [String: Any]?
    var responseData: Data?
    var responseError: Error?
    
    func get<T: Decodable>(url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        lastRequestURL = url
        
        if let error = responseError {
            completion(.failure(error))
            return
        }
        
        if let data = responseData, let decoded = try? JSONDecoder().decode(T.self, from: data) {
            completion(.success(decoded))
        } else {
            completion(.failure(NSError(domain: "MockNetworkService", code: -1, userInfo: nil)))
        }
    }
    
    // Other mock implementations...
}
```

### Dependency Injection in Tests

Dependency injection is used to provide mock implementations of services and other dependencies during testing. This is typically done in the `setUp` method of test classes.

```swift
class AuthViewModelTests: XCTestCase {
    var viewModel: AuthViewModel!
    var mockAuthService: MockAuthService!
    
    override func setUpWithError() throws {
        super.setUp()
        
        ServiceLocator.reset()
        
        mockAuthService = MockAuthService()
        ServiceLocator.register(type: AuthServiceProtocol.self, service: mockAuthService!)
        
        viewModel = AuthViewModel()
    }
    
    // Test methods...
}
```

## Test Coverage

Payslip Max aims for high test coverage, with a focus on covering critical functionality and edge cases. Test coverage is monitored using Xcode's code coverage tools.

## Continuous Integration

Tests in Payslip Max are run as part of the continuous integration (CI) pipeline. The CI pipeline is configured to:

- Run all tests on every pull request.
- Run all tests on every merge to the main branch.
- Generate test coverage reports.

## Best Practices

When writing tests for Payslip Max, follow these best practices:

1. **Test One Thing at a Time**: Each test should focus on testing one specific behavior or functionality.
2. **Use Descriptive Test Names**: Test names should clearly describe what is being tested and the expected outcome.
3. **Set Up and Tear Down Properly**: Use the `setUp` and `tearDown` methods to set up and clean up test environments.
4. **Use Assertions Effectively**: Use the appropriate assertions for the type of test being performed.
5. **Mock External Dependencies**: Always mock external dependencies to ensure tests are isolated and deterministic.
6. **Test Edge Cases**: Include tests for edge cases and error conditions, not just the happy path.
7. **Keep Tests Fast**: Tests should be fast to run to encourage frequent testing during development.
8. **Keep Tests Independent**: Tests should not depend on the state or outcome of other tests.
9. **Maintain Tests**: Keep tests up to date as the codebase evolves.
10. **Document Test Scenarios**: Document complex test scenarios to make it clear what is being tested and why. 