# Architecture

## Overview

Payslip Max follows the MVVM (Model-View-ViewModel) architecture pattern, which provides a clear separation of concerns and makes the codebase more maintainable, testable, and scalable.

## Architectural Layers

### Model Layer

The Model layer represents the data and business logic of the application. It includes:

- **Data Models**: Swift structs or classes that represent the core data entities like `Payslip`, `User`, `Deduction`, etc.
- **Services**: Classes that handle data operations, such as network requests, data persistence, and authentication.

### View Layer

The View layer is responsible for displaying the UI and capturing user interactions. It includes:

- **SwiftUI Views**: Declarative UI components that render the application's interface.
- **UI Components**: Reusable UI elements that are used across different screens.

### ViewModel Layer

The ViewModel layer acts as a mediator between the Model and View layers. It includes:

- **ViewModels**: Classes that prepare and transform data from the Model layer for presentation in the View layer.
- **State Management**: Logic for managing UI state and handling user interactions.

## Communication Flow

1. **User Interaction**: The user interacts with the View layer.
2. **View to ViewModel**: The View layer communicates these interactions to the ViewModel layer.
3. **ViewModel to Model**: The ViewModel layer processes the interactions and communicates with the Model layer if necessary.
4. **Model to ViewModel**: The Model layer returns data to the ViewModel layer.
5. **ViewModel to View**: The ViewModel layer prepares the data for presentation and updates the View layer.

## Dependency Injection

Payslip Max uses a dependency injection pattern to manage dependencies between components. This is implemented through:

- **Service Locator**: A centralized registry for services that can be injected into ViewModels and other components.
- **Protocol-Based Design**: Services are defined by protocols, allowing for easy substitution of implementations, particularly useful for testing.

For more details on dependency injection, see the [Dependency Injection](./DependencyInjection.md) document.

## Navigation

Navigation in Payslip Max is handled using SwiftUI's navigation system:

- **NavigationView/NavigationStack**: Used for hierarchical navigation.
- **TabView**: Used for tab-based navigation between main sections of the app.
- **Programmatic Navigation**: Implemented using state variables and environment objects for complex navigation scenarios.

## Error Handling

Error handling in Payslip Max follows a consistent pattern:

- **Error Types**: Custom error types are defined for different categories of errors.
- **Result Type**: Swift's `Result` type is used for handling success and failure cases in asynchronous operations.
- **Error Presentation**: Errors are presented to the user through alert views or inline error messages.

## Testing Strategy

The architecture of Payslip Max is designed with testability in mind:

- **Unit Testing**: Each layer can be tested independently due to the clear separation of concerns.
- **Mock Services**: Protocol-based design allows for easy mocking of services for testing.
- **UI Testing**: SwiftUI views can be tested using XCTest's UI testing capabilities.

For more details on testing, see the [Testing Strategy](./TestingStrategy.md) document. 