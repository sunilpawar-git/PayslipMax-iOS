import Foundation
import SwiftData

/// Core implementation of the DataService containing properties and initialization logic.
/// This class handles the fundamental setup and state management for the data service,
/// following SOLID principles with single responsibility for core service management.
///
/// Key Responsibilities:
/// - Dependency injection setup for security and repository services
/// - SwiftData ModelContext and ModelContainer initialization
/// - Lazy initialization of repository dependencies
/// - State management for initialization status
/// - Thread-safe property management via @MainActor
@MainActor
final class DataServiceCore {
    // MARK: - Properties
    /// The security service used for initialization and potential future security checks.
    private(set) var securityService: SecurityServiceProtocol
    /// The SwiftData model context used for data operations.
    private(set) var modelContext: ModelContext
    /// The repository responsible for direct interaction with `PayslipItem` data.
    private(set) var payslipRepository: PayslipRepositoryProtocol?

    /// Flag indicating if the service (including the security service dependency) is initialized.
    private(set) var isInitialized: Bool = false

    // MARK: - Initialization
    /// Initializes the data service core with a security service.
    /// Creates a default `ModelContainer` and `ModelContext` for `PayslipItem`.
    /// - Parameter securityService: The security service dependency.
    /// - Throws: ModelContainer creation errors
    init(securityService: SecurityServiceProtocol) throws {
        let modelContainer = try ModelContainer(for: PayslipItem.self)
        let context = ModelContext(modelContainer)

        self.securityService = securityService
        self.modelContext = context
        self.payslipRepository = nil // Initialize lazily
    }

    /// Initializes the data service core for testing with explicit dependencies.
    /// - Parameters:
    ///   - securityService: The security service dependency.
    ///   - modelContext: The specific `ModelContext` to use.
    init(securityService: SecurityServiceProtocol, modelContext: ModelContext) {
        self.securityService = securityService
        self.modelContext = modelContext
        self.payslipRepository = nil // Initialize lazily
    }

    // MARK: - Repository Management
    /// Sets up the payslip repository using dependency injection container.
    /// This method implements lazy initialization to avoid circular dependencies
    /// and ensure the repository is only created when needed.
    func setupPayslipRepository() {
        if self.payslipRepository == nil {
            self.payslipRepository = DIContainer.shared.makePayslipRepository(modelContext: self.modelContext)
        }
    }

    // MARK: - Initialization Management
    /// Initializes the underlying security service.
    /// Sets the `isInitialized` flag upon success.
    /// - Throws: Errors from the `securityService.initialize()` call.
    func initialize() async throws {
        try await securityService.initialize()
        isInitialized = true
    }

    /// Ensures the service is initialized, performing lazy initialization if needed.
    /// - Throws: Errors from `initialize()` if lazy initialization fails.
    func ensureInitialized() async throws {
        if !isInitialized {
            try await initialize()
        }
    }
}
