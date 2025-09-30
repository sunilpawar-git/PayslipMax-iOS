# Documentation Style Guide

This document outlines the documentation standards for the PayslipMax project.

## Code Documentation

### File Headers

Each file should begin with a header comment that includes:

```swift
//
//  FileName.swift
//  PayslipMax
//
//  Created by Author on Date.
//  Copyright © Year Organization. All rights reserved.
//
//  [Brief description of the file's purpose]
//
```

### Type Documentation

Document classes, structs, enums, and protocols with a comment that explains their purpose:

```swift
/// A view model that manages authentication state and operations.
/// 
/// This class handles user authentication, including biometric authentication,
/// PIN verification, and session management.
class AuthViewModel: ObservableObject {
    // Implementation
}
```

### Property Documentation

Document properties with a comment that explains their purpose:

```swift
/// Indicates whether the user is currently authenticated.
@Published private(set) var isAuthenticated = false

/// The error that occurred during the last authentication attempt, if any.
@Published var error: Error?
```

### Method Documentation

Document methods with a comment that explains their purpose, parameters, and return value:

```swift
/// Authenticates the user using the provided credentials.
///
/// This method attempts to authenticate the user with the security service.
/// If successful, it updates the `isAuthenticated` property to `true`.
/// If unsuccessful, it sets the `error` property and leaves `isAuthenticated` as `false`.
///
/// - Parameters:
///   - username: The username to authenticate with.
///   - password: The password to authenticate with.
/// - Returns: A boolean indicating whether authentication was successful.
/// - Throws: An error if authentication fails.
func authenticate(username: String, password: String) async throws -> Bool {
    // Implementation
}
```

### MARK Comments

Use MARK comments to organize code into logical sections:

```swift
// MARK: - Properties

// MARK: - Initialization

// MARK: - Public Methods

// MARK: - Private Methods

// MARK: - Helpers
```

## Documentation Comments

Use documentation comments (triple-slash `///`) for public APIs and regular comments (double-slash `//`) for implementation details.

### Documentation Comment Format

```swift
/// [Brief description]
///
/// [Detailed description, if needed]
///
/// - Parameters:
///   - [paramName]: [Parameter description]
/// - Returns: [Return value description]
/// - Throws: [Description of errors that can be thrown]
/// - Note: [Additional notes, if needed]
/// - Warning: [Warnings, if needed]
/// - Important: [Important information, if needed]
```

## SwiftUI View Documentation

For SwiftUI views, include a comment that explains the view's purpose and usage:

```swift
/// A view that displays the login screen.
///
/// This view presents input fields for username and password,
/// along with buttons for logging in and resetting the password.
///
/// Example usage:
/// ```
/// LoginView(viewModel: authViewModel)
/// ```
struct LoginView: View {
    // Implementation
}
```

## Protocol Documentation

For protocols, document the requirements and purpose:

```swift
/// A protocol that defines the requirements for a security service.
///
/// Implementations of this protocol provide security-related functionality,
/// such as authentication, encryption, and decryption.
protocol SecurityServiceProtocol {
    // Requirements
}
```

## Extension Documentation

For extensions, document the purpose of the extension:

```swift
/// Adds convenience methods for working with dates.
extension Date {
    // Implementation
}
```

## Best Practices

1. **Be Concise**: Keep documentation brief but informative.
2. **Use Complete Sentences**: Start with a capital letter and end with a period.
3. **Focus on Why, Not How**: Explain why the code exists, not how it works (the code itself shows that).
4. **Keep Documentation Updated**: Update documentation when code changes.
5. **Document Edge Cases**: Mention any edge cases or special considerations.
6. **Use Examples**: Provide examples for complex APIs.
7. **Document Assumptions**: Note any assumptions the code makes. 