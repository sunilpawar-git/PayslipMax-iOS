# Architecture

An overview of PayslipMax's system architecture and design patterns.

## Overview

PayslipMax follows a protocol-oriented architecture with strong separation of concerns. This architecture ensures testability, maintainability, and scalability while providing a solid foundation for future enhancements.

## Core Architecture Patterns

### Protocol-Based Design

The application is built around protocols that define clear interfaces between components:

```swift
protocol SecurityServiceProtocol {
    func authenticate() async throws -> Bool
    func encryptData(_ data: Data) async throws -> Data
    func decryptData(_ data: Data) async throws -> Data
}

// Implementation
class SecurityService: SecurityServiceProtocol {
    // Implementation details
}
```

This approach enables:
- Clear boundaries between components
- Easy mocking for tests
- Flexibility to change implementations

### Dependency Injection

Services are injected through the `DIContainer`:

```swift
class DIContainer {
    static let shared = DIContainer()
    
    lazy var securityService: SecurityServiceProtocol = {
        return SecurityService()
    }()
    
    lazy var dataService: DataServiceProtocol = {
        return DataService()
    }()
    
    // Other services...
}
```

### MVVM Architecture

The UI layer follows the Model-View-ViewModel pattern:

- **Models**: Data structures like `PayslipItem`
- **Views**: SwiftUI views that display data
- **ViewModels**: Manage UI state and business logic

```swift
class PayslipViewModel: ObservableObject {
    @Published var payslips: [PayslipItem] = []
    @Published var isLoading: Bool = false
    
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }
    
    func loadPayslips() async {
        // Implementation
    }
}
```

## Key Subsystems

### 1. PDF Processing Pipeline

The PDF processing system consists of multiple components:

- `PDFParsingCoordinator`: Orchestrates the parsing process
- `PayslipParser`: Protocol for specialized parsers
- `EnhancedPDFParser`: High-quality PDF extraction
- `DocumentAnalysisService`: Analyzes document characteristics

### 2. Security System

The security system handles authentication and data encryption:

- `SecurityService`: Manages authentication and encryption
- `BiometricAuthService`: Handles biometric authentication
- `EncryptionService`: Encrypts and decrypts sensitive data

### 3. Data Persistence

Data is managed through a layered persistence architecture:

- `DataService`: High-level data operations
- `PayslipRepository`: Domain-specific data operations
- `SwiftData`: Underlying persistence framework

### 4. Navigation System

Navigation follows a coordinator pattern:

- `RouterProtocol`: Defines navigation capabilities
- `NavRouter`: Implements navigation logic
- `DeepLinkCoordinator`: Handles deep linking

## Data Flow

1. **PDF Ingestion**: User selects PDF → `PDFManager` loads document
2. **Parsing**: `PDFParsingCoordinator` selects appropriate parser
3. **Data Extraction**: Parser extracts structured data into `PayslipItem`
4. **Security**: Sensitive data is encrypted by `SecurityService`
5. **Storage**: `DataService` stores the payslip
6. **Presentation**: Data is displayed through appropriate ViewModels and Views

## Design Principles

1. **Separation of Concerns**: Each component has a clear responsibility
2. **Composition over Inheritance**: Use protocols and composition for flexibility
3. **Single Responsibility**: Classes and functions have focused purposes
4. **Dependency Inversion**: High-level modules don't depend on low-level modules
5. **Interface Segregation**: Protocols are focused and specific

## Future Architecture Evolution

The architecture is designed to evolve with:

- Enhanced ML capabilities for document analysis
- Expanded parser ecosystem for more document types
- Improved analytics for financial insights
- Cross-platform extensions 