# Dependency Injection

## Overview

Dependency Injection (DI) is a design pattern used in Payslip Max to manage dependencies between components. It allows for loose coupling, improved testability, and better maintainability of the codebase.

## Implementation

Payslip Max implements dependency injection through a Service Locator pattern, which provides a centralized registry for services that can be injected into ViewModels and other components.

### Service Locator

The `ServiceLocator` class is the core of the DI system in Payslip Max. It provides methods for registering and resolving services.

```swift
class ServiceLocator {
    private static var services: [String: Any] = [:]
    
    static func register<T>(type: T.Type, service: T) {
        let key = String(describing: type)
        services[key] = service
    }
    
    static func resolve<T>(type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }
    
    static func reset() {
        services.removeAll()
    }
}
```

### Service Protocols

Services in Payslip Max are defined by protocols, which allows for easy substitution of implementations, particularly useful for testing.

```swift
protocol ServiceProtocol: AnyObject {
    // Base protocol for all services
}

protocol NetworkServiceProtocol: ServiceProtocol {
    func get<T: Decodable>(url: URL, completion: @escaping (Result<T, Error>) -> Void)
    func post<T: Decodable>(url: URL, body: [String: Any], completion: @escaping (Result<T, Error>) -> Void)
    // Other network methods...
}

protocol DataServiceProtocol: ServiceProtocol {
    func fetchPayslips(completion: @escaping (Result<[Payslip], Error>) -> Void)
    // Other data methods...
}

protocol AuthServiceProtocol: ServiceProtocol {
    func login(username: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
    func logout(completion: @escaping (Bool) -> Void)
    // Other auth methods...
}
```

### Service Implementations

Concrete implementations of the service protocols are provided and registered with the `ServiceLocator`.

```swift
class NetworkService: NetworkServiceProtocol {
    // Implementation of NetworkServiceProtocol methods
}

class DataService: DataServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // Implementation of DataServiceProtocol methods
}

class AuthService: AuthServiceProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // Implementation of AuthServiceProtocol methods
}
```

### Service Registration

Services are registered with the `ServiceLocator` during app initialization.

```swift
func registerServices() {
    let networkService = NetworkService()
    ServiceLocator.register(type: NetworkServiceProtocol.self, service: networkService)
    
    let dataService = DataService(networkService: networkService)
    ServiceLocator.register(type: DataServiceProtocol.self, service: dataService)
    
    let authService = AuthService(networkService: networkService)
    ServiceLocator.register(type: AuthServiceProtocol.self, service: authService)
}
```

### Service Resolution

Services are resolved from the `ServiceLocator` when needed.

```swift
class PayslipViewModel: ObservableObject {
    private let dataService: DataServiceProtocol
    
    init() {
        self.dataService = ServiceLocator.resolve(type: DataServiceProtocol.self)!
    }
    
    // ViewModel methods using dataService
}
```

## Testing with Dependency Injection

One of the main benefits of dependency injection is improved testability. In Payslip Max, mock implementations of services can be registered with the `ServiceLocator` for testing purposes.

```swift
class MockDataService: DataServiceProtocol {
    var payslips: [Payslip] = []
    
    func fetchPayslips(completion: @escaping (Result<[Payslip], Error>) -> Void) {
        completion(.success(payslips))
    }
    
    // Other mock implementations
}

func setupTestEnvironment() {
    ServiceLocator.reset()
    
    let mockDataService = MockDataService()
    mockDataService.payslips = [/* Test payslips */]
    ServiceLocator.register(type: DataServiceProtocol.self, service: mockDataService)
    
    // Register other mock services
}
```

## Best Practices

When using dependency injection in Payslip Max, follow these best practices:

1. **Define Services with Protocols**: Always define services with protocols to allow for easy substitution of implementations.
2. **Use Constructor Injection**: Prefer constructor injection (passing dependencies through initializers) over property injection or method injection.
3. **Reset ServiceLocator in Tests**: Always reset the `ServiceLocator` before each test to ensure a clean state.
4. **Avoid Service Locator in Production Code**: While the `ServiceLocator` is useful for testing, consider using more direct dependency injection in production code when possible.
5. **Document Dependencies**: Clearly document the dependencies of each class to make the code more maintainable. 