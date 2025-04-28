# Getting Started with PayslipMax

Learn how to use the core functionality of PayslipMax.

## Overview

PayslipMax simplifies payslip management for military personnel by providing advanced PDF extraction, secure storage, and insightful analysis tools. This guide will help you understand the core architecture and get started with key functionality.

## Installation Requirements

- iOS 16.0+ / macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## Basic Usage

### Processing Payslips

PayslipMax processes payslips through its PDF parsing pipeline:

```swift
import PayslipMax

// Initialize the core services
let container = DIContainer.shared

// Parse a payslip
func processPayslip(url: URL) async throws -> PayslipItem? {
    let pdfService = container.pdfService
    let document = try await pdfService.loadDocument(from: url)
    return try await pdfService.parsePayslip(document)
}
```

### Working with Encrypted Data

PayslipMax securely stores sensitive information using encryption:

```swift
// Access encrypted data
func accessSensitiveData() async throws {
    // Get the security service
    let securityService = container.securityService
    
    // Authenticate the user
    let isAuthenticated = try await securityService.authenticate()
    guard isAuthenticated else {
        throw SecurityError.authenticationFailed
    }
    
    // Now you can access sensitive data
    let payslip = /* get payslip item */
    let decryptedName = try await securityService.decryptData(payslip.name)
}
```

## Architecture Overview

PayslipMax is built using a protocol-oriented architecture with dependency injection:

1. **Models**: Core data structures like ``PayslipItem``
2. **Services**: Business logic encapsulated in services like ``PDFProcessingService``
3. **ViewModels**: UI state and business logic bridge
4. **Views**: SwiftUI views for user interaction

## Key Protocols

The system is built around these core protocols:

- ``PayslipProtocol``: Core payslip interface
- ``PayslipParserProtocol``: PDF parsing capability
- ``SecurityServiceProtocol``: Secure data handling

## Next Steps

- Check out <doc:Architecture> for an in-depth architecture overview
- Try the PDF processing tutorial with <doc:PDFProcessingTutorial>
- Learn about military-specific features in <doc:MilitaryFeatures> 