import Foundation
import PDFKit
import SwiftUI
import SwiftData
import Combine

/// Factory for ViewModel creation in the DI container.
/// Handles all ViewModel instantiations and their dependencies.
@MainActor
class ViewModelFactory {

    // MARK: - Dependencies

    /// Core service container for accessing core services
    private let coreContainer: CoreServiceContainerProtocol

    /// Processing container for accessing processing services
    private let processingContainer: ProcessingContainerProtocol

    /// ViewModel container for ViewModel-specific services
    private let viewModelContainer: ViewModelContainerProtocol

    /// Whether to use mock implementations for testing
    private let useMocks: Bool

    // MARK: - Initialization

    init(useMocks: Bool = false, coreContainer: CoreServiceContainerProtocol, processingContainer: ProcessingContainerProtocol, viewModelContainer: ViewModelContainerProtocol) {
        self.useMocks = useMocks
        self.coreContainer = coreContainer
        self.processingContainer = processingContainer
        self.viewModelContainer = viewModelContainer
    }

    // MARK: - Main ViewModels

    /// Creates a HomeViewModel.
    func makeHomeViewModel() -> HomeViewModel {
        return viewModelContainer.makeHomeViewModel()
    }

    /// Creates a PDFProcessingViewModel.
    func makePDFProcessingViewModel() -> any ObservableObject {
        return viewModelContainer.makePDFProcessingViewModel()
    }

    /// Creates a PayslipDataViewModel.
    func makePayslipDataViewModel() -> any ObservableObject {
        return viewModelContainer.makePayslipDataViewModel()
    }

    /// Creates a PayslipsViewModel.
    func makePayslipsViewModel() -> PayslipsViewModel {
        return viewModelContainer.makePayslipsViewModel()
    }

    /// Creates an InsightsCoordinator.
    func makeInsightsCoordinator() -> InsightsCoordinator {
        return viewModelContainer.makeInsightsCoordinator()
    }

    /// Creates a SettingsViewModel.
    func makeSettingsViewModel() -> SettingsViewModel {
        return viewModelContainer.makeSettingsViewModel()
    }

    /// Creates an LLMSettingsViewModel.
    func makeLLMSettingsViewModel() -> LLMSettingsViewModel {
        return viewModelContainer.makeLLMSettingsViewModel()
    }

    /// Creates a SecurityViewModel.
    func makeSecurityViewModel() -> SecurityViewModel {
        return viewModelContainer.makeSecurityViewModel()
    }

    /// Creates an AuthViewModel.
    func makeAuthViewModel() -> AuthViewModel {
        return viewModelContainer.makeAuthViewModel()
    }

    /// Creates a QuizViewModel.
    func makeQuizViewModel() -> QuizViewModel {
        return viewModelContainer.makeQuizViewModel()
    }

    /// Creates a WebUploadViewModel.
    func makeWebUploadViewModel() -> WebUploadViewModel {
        return viewModelContainer.makeWebUploadViewModel()
    }

    // MARK: - Pattern Management ViewModels

    /// Creates a PatternManagementViewModel.
    func makePatternManagementViewModel() -> PatternManagementViewModel {
        return PatternManagementViewModel()
    }

    /// Creates a PatternValidationViewModel.
    func makePatternValidationViewModel() -> PatternValidationViewModel {
        return PatternValidationViewModel()
    }

    /// Creates a PatternListViewModel.
    func makePatternListViewModel() -> PatternListViewModel {
        return PatternListViewModel()
    }

    /// Creates a PatternItemEditViewModel.
    func makePatternItemEditViewModel() -> PatternItemEditViewModel {
        return PatternItemEditViewModel()
    }

    /// Creates a PatternEditViewModel.
    func makePatternEditViewModel() -> PatternEditViewModel {
        return PatternEditViewModel()
    }

    /// Creates a PatternTestingViewModel.
    func makePatternTestingViewModel() -> PatternTestingViewModel {
        // Resolve pattern testing service from AppContainer
        guard let patternTestingService = AppContainer.shared.resolve(PatternTestingServiceProtocol.self) else {
            // Fallback to default service creation if resolution fails
            return PatternTestingViewModel()
        }
        return PatternTestingViewModel(patternTestingService: patternTestingService)
    }

    // MARK: - Background Task Coordinator

    /// Creates a background task coordinator.
    func makeBackgroundTaskCoordinator() -> BackgroundTaskCoordinator {
        // Use the shared instance since BackgroundTaskCoordinator is designed as a singleton
        return BackgroundTaskCoordinator.shared
    }

    // MARK: - Protocol Conformance

    /// Makes the factory conform to DIContainerProtocol for PatternEditViewModel
    private func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        let factory = CoreServiceFactory(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer)
        return factory.makePDFProcessingService()
    }

    /// Makes the factory conform to DIContainerProtocol for PatternEditViewModel
    private func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol {
        let factory = CoreServiceFactory(useMocks: useMocks, coreContainer: coreContainer, processingContainer: processingContainer)
        return factory.makePayslipRepository(modelContext: modelContext)
    }
}
