# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PayslipMax is a sophisticated iOS application built with SwiftUI and SwiftData that processes payslip PDFs and provides financial insights. The app uses clean architecture principles with MVVM pattern, extensive protocol-based design, and comprehensive testing infrastructure.

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project PayslipMax.xcodeproj -scheme PayslipMax build

# Run tests
xcodebuild -project PayslipMax.xcodeproj -scheme PayslipMax test

# Run specific test
xcodebuild -project PayslipMax.xcodeproj -scheme PayslipMax -only-testing:PayslipMaxTests/[TestClass]/[testMethod] test
```

### Code Quality
```bash
# Run SwiftLint (if configured)
swiftlint lint

# Run SwiftLint with autocorrect
swiftlint lint --fix
```

## Architecture Overview

### Core Architecture Pattern
- **MVVM with Clean Architecture**: Models, Views, ViewModels with clear separation
- **Protocol-Oriented Programming**: Extensive use of protocols for dependency injection
- **Feature-Based Organization**: Code organized by features rather than technical layers
- **Dependency Injection**: Custom DI container system in `Core/DI/`

### Key Directories
- `Core/`: Infrastructure components (DI, Analytics, Security, Performance)
- `Features/`: Feature modules (Authentication, Home, Payslips, Insights, Settings)
- `Models/`: Data models and SwiftData persistence
- `Services/`: Business logic services with protocol-based design
- `Views/`: Reusable UI components
- `Navigation/`: Navigation coordination system

### Critical Services
- **PDF Processing**: Complex pipeline for extracting payslip data from PDFs
- **Text Extraction**: OCR and pattern matching for data extraction
- **Data Encryption**: AES encryption for sensitive financial data
- **Analytics**: Performance tracking and user behavior analytics
- **Background Processing**: Async task coordination and queue management

## Testing Infrastructure

### Test Structure
- **Unit Tests**: 943+ Swift test files with comprehensive coverage
- **UI Tests**: Complete UI testing suite for user workflows
- **Integration Tests**: End-to-end feature testing
- **Performance Tests**: Memory and performance monitoring
- **Mock Services**: Complete mocking infrastructure for isolated testing

### Running Tests
```bash
# Run all tests
xcodebuild test -project PayslipMax.xcodeproj -scheme PayslipMax

# Run tests for specific feature
xcodebuild test -project PayslipMax.xcodeproj -scheme PayslipMax -only-testing:PayslipMaxTests/[FeatureName]Tests

# Run UI tests only
xcodebuild test -project PayslipMax.xcodeproj -scheme PayslipMax -only-testing:PayslipMaxUITests
```

## Key Design Patterns

### Dependency Injection
- Custom DI container in `Core/DI/DIContainer.swift`
- Services registered as protocols, not concrete types
- Environment-based configuration (development, staging, production)

### PDF Processing Architecture
- Multi-stage processing pipeline
- Strategy pattern for different PDF formats
- Background processing with progress tracking
- Error recovery and retry mechanisms

### Security Architecture
- Biometric authentication (Face ID/Touch ID)
- AES encryption for sensitive data
- Keychain integration for secure storage
- App sandbox with restricted file access

## Data Layer

### SwiftData Models
- Core data models in `Models/` directory
- Relationships between Payslip, Insight, and User models
- Migration strategies for schema changes

### Persistence Strategy
- SwiftData for local storage
- Encrypted storage for sensitive financial data
- Background sync with careful transaction management

## Navigation and Deep Linking

### Deep Link Support
- Custom URL scheme: `payslipmax://`
- Universal links for `payslipmax.com` and `www.payslipmax.com`
- Coordinator pattern for navigation management

### Navigation Architecture
- Centralized navigation coordination
- State-driven navigation with SwiftUI
- Deep link handling throughout the app

## Performance Considerations

### Memory Management
- Efficient PDF processing to avoid memory spikes
- Background processing for heavy operations
- Caching strategies for frequently accessed data

### Background Processing
- Async task coordination
- Progress tracking for long-running operations
- Error handling and retry mechanisms

## Security Requirements

### Data Protection
- All financial data must be encrypted at rest
- Biometric authentication required for sensitive operations
- Secure keychain storage for authentication tokens

### Privacy
- Minimal data collection
- User consent for analytics
- Secure transmission of sensitive data

## Common Development Workflows

### Adding New Features
1. Create feature directory under `Features/`
2. Implement ViewModels with protocol-based dependencies
3. Add comprehensive unit tests
4. Update DI container registration
5. Add UI tests for user workflows

### PDF Processing Changes
- Understand the multi-stage pipeline in `Services/PDFProcessingService`
- Add tests for new PDF formats or edge cases
- Consider performance impact of changes
- Update error handling and recovery logic

### Security Changes
- Review encryption implementations
- Test biometric authentication flows
- Validate keychain storage operations
- Ensure compliance with security requirements

## Documentation

The codebase includes 130+ markdown files with comprehensive documentation covering architecture, API design, testing strategies, and development workflows. Refer to these files for detailed implementation guidance.