import Foundation
import SwiftUI

/// Protocol defining the interface for ViewModels container.
/// This container handles all ViewModel factory methods and their dependencies.
@MainActor
protocol ViewModelContainerProtocol {
    // MARK: - Configuration

    /// Whether to use mock implementations for testing.
    var useMocks: Bool { get }

    // MARK: - Core ViewModels

    /// Creates a HomeViewModel.
    func makeHomeViewModel() -> HomeViewModel

    /// Creates a PDFProcessingViewModel (delegates to HomeViewModel).
    func makePDFProcessingViewModel() -> any ObservableObject

    /// Creates a PayslipDataViewModel (delegates to PayslipsViewModel).
    func makePayslipDataViewModel() -> any ObservableObject

    /// Creates an AuthViewModel.
    func makeAuthViewModel() -> AuthViewModel

    /// Creates a PayslipsViewModel (cached for state consistency).
    func makePayslipsViewModel() -> PayslipsViewModel

    /// Creates an InsightsCoordinator.
    func makeInsightsCoordinator() -> InsightsCoordinator

    /// Creates a SettingsViewModel.
    func makeSettingsViewModel() -> SettingsViewModel

    /// Creates an LLMSettingsViewModel.
    func makeLLMSettingsViewModel() -> LLMSettingsViewModel

    /// Creates a SecurityViewModel.
    func makeSecurityViewModel() -> SecurityViewModel

    // MARK: - Feature ViewModels

    /// Creates a QuizViewModel (cached for state consistency).
    func makeQuizViewModel() -> QuizViewModel

    /// Creates a WebUploadViewModel.
    func makeWebUploadViewModel() -> WebUploadViewModel
}
