# PayslipMax iOS

A secure and efficient iOS application designed for military personnel to manage and analyze their payslips. In phased manner, it will also add pension slips for pensioners.

## Features

- **Secure Authentication**
  - Biometric authentication (Face ID/Touch ID)
  - PIN-based login
  - Military-grade encryption

- **PDF Processing**
  - Upload payslip PDFs
  - Automatic data extraction
  - Secure document storage

- **Financial Analysis**
  - Monthly income tracking
  - Deductions breakdown
  - Visual charts and insights
  - Yearly summaries

- **Data Management**
  - Encrypted storage
  - Backup and restore
  - Export capabilities
  - Secure data handling

## Technical Stack

- **Framework:** SwiftUI
- **iOS Version:** 15.0+
- **Data Persistence:** SwiftData
- **Security:** 
  - AES-256 encryption
  - Keychain integration
  - LocalAuthentication framework

## Architecture

PayslipMax follows a protocol-oriented architecture with MVVM design pattern, leveraging Swift's powerful type system to create flexible, testable, and maintainable code.

### Protocol-Based Design

The application uses protocols as abstractions for its core components, providing several benefits:

1. **Improved Testability**: By programming to interfaces rather than concrete implementations, we can easily create mock objects for testing.
2. **Flexibility**: New implementations can be added without modifying existing code.
3. **Decoupling**: Components depend on abstractions rather than concrete types, reducing tight coupling.
4. **Clear Contracts**: Protocols define clear contracts that implementations must fulfill.

#### Key Protocols

- **`PayslipItemProtocol`**: Defines the core functionality of a payslip item.
- **`PDFExtractorProtocol`**: Defines the functionality for extracting data from PDF documents.
- **`ServiceProtocol`**: Base protocol for all services in the application.
- **`SecurityServiceProtocol`**: Defines the functionality for encryption, decryption, and authentication.
- **`DataServiceProtocol`**: Defines the functionality for data persistence.
- **`PDFServiceProtocol`**: Defines the functionality for processing PDF files.

### Dependency Injection

The application uses a custom dependency injection container (`DIContainer`) to manage dependencies and facilitate testing:

- **Service Locator Pattern**: The container acts as a service locator, providing access to services and factory methods.
- **Lazy Initialization**: Services are created lazily to avoid circular dependencies.
- **Testing Support**: The container can be configured with mock services for testing.

### MVVM Architecture

The application follows the MVVM (Model-View-ViewModel) architecture:

- **Models**: Data models like `PayslipItem` that conform to protocols like `PayslipItemProtocol`.
- **Views**: SwiftUI views that display data and handle user interactions.
- **ViewModels**: Classes that prepare data for display and handle business logic.

## Security Features

- Military-grade encryption (AES-256)
- Biometric authentication
- Secure enclave integration
- Data encryption at rest
- Secure PDF processing

## Testing

The application includes comprehensive tests for its components:

- **Unit Tests**: Tests for individual components like models, view models, and services.
- **Integration Tests**: Tests for interactions between components.
- **Mock Objects**: Mock implementations of protocols for testing.

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

### Installation

1. Clone the repository
2. Open `PayslipMax.xcodeproj` in Xcode
3. Build and run the application

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Technical Debt Reduction

### Phase 1: Service Layer Consolidation (Completed)

The first phase of our technical debt reduction focused on consolidating PDF processing functionality:

- Created a unified `PDFProcessingServiceProtocol` to define a clear contract for PDF processing
- Implemented a consolidated `PDFProcessingService` that extracts PDF processing from view models
- Added comprehensive testing with mock implementations
- Updated view models and views to use the new service
- Simplified dependency injection through the DIContainer

This refactoring improves:
- Code organization and maintenance
- Testability through clear separation of concerns
- Reusability across different parts of the application
- Consistency in PDF processing behavior

### Future Phases

- Phase 2: Error handling standardization
- Phase 3: UI component modularization
- Phase 4: Data layer optimization

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
