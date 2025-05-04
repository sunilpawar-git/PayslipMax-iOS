# PayslipStandaloneTests

A standalone Swift Package for testing the PayslipItem functionality without being affected by the conflicting definitions in the main app.

## Overview

This package provides a clean, isolated environment for testing the core functionality of the PayslipMax app, particularly focusing on the `PayslipItem` model and related view models. It avoids the "imported as struct but defined as class" error that occurs in the main app due to conflicting definitions.

## Components

### Models

- **StandalonePayslipItem**: A standalone implementation of the PayslipItem model that doesn't depend on SwiftData or the main app's code.

### Services

- **MockSecurityService**: A mock implementation of the SecurityServiceProtocol for testing authentication, encryption, and decryption.
- **MockDataService**: A mock implementation of the DataServiceProtocol for testing data storage and retrieval.
- **MockPDFService**: A mock implementation of the PDFServiceProtocol for testing PDF processing and extraction.

### ViewModels

- **AuthViewModel**: A view model for handling authentication.
- **PayslipsViewModel**: A view model for managing payslips.
- **PDFViewModel**: A view model for processing PDFs and extracting payslip data.

## Tests

The package includes comprehensive tests for all components:

### Model Tests

- **StandalonePayslipItemTests**: Tests for the StandalonePayslipItem model, including initialization, sample creation, and Codable functionality.

### Service Tests

- **MockServicesTests**: Tests for the mock services, ensuring they behave as expected.

### ViewModel Tests

- **AuthViewModelTests**: Tests for the AuthViewModel, including authentication success and failure scenarios.
- **PayslipsViewModelTests**: Tests for the PayslipsViewModel, including loading, adding, and deleting payslips.
- **PDFViewModelTests**: Tests for the PDFViewModel, including processing PDFs and extracting payslip data.

## Running the Tests

To run the tests, use the following command:

```bash
swift test
```

To run the tests with code coverage:

```bash
swift test --enable-code-coverage
```

## Benefits of This Approach

1. **Isolation**: The standalone package is completely isolated from the main app's code, avoiding any conflicts with the existing `PayslipItem` definitions.

2. **Simplicity**: The standalone implementation focuses only on the core functionality needed for testing, without the complexity of SwiftData or other dependencies.

3. **Portability**: This approach can be extended to test other components of the app in isolation.

4. **Maintainability**: The standalone tests can be run independently of the main app, making it easier to identify and fix issues.

## Next Steps

1. **Apply learnings to the main app**: The insights gained from the standalone implementation can be used to resolve the conflicts in the main app.

2. **Extend the standalone tests**: Add more test cases to cover additional functionality.

3. **Consider refactoring the main app**: To avoid similar issues in the future, consider consolidating the `PayslipItem` definitions into a single location. 