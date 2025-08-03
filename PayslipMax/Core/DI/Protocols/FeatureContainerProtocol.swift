import Foundation

/// Protocol defining the interface for Feature services container.
/// This container handles feature-specific services like WebUpload, Quiz, and Achievement systems.
@MainActor 
protocol FeatureContainerProtocol {
    // MARK: - Configuration
    
    /// Whether to use mock implementations for testing.
    var useMocks: Bool { get }
    
    // MARK: - WebUpload Feature
    
    /// Creates a WebUploadService instance with proper configuration.
    func makeWebUploadService() -> WebUploadServiceProtocol
    
    /// Creates a WebUploadDeepLinkHandler.
    func makeWebUploadDeepLinkHandler() -> WebUploadDeepLinkHandler
    
    /// Toggle the use of mock WebUploadService.
    /// - Parameter useMock: Whether to use the mock service
    func toggleWebUploadMock(_ useMock: Bool)
    
    /// Set the base URL for API calls.
    /// - Parameter url: The base URL to use
    func setWebAPIBaseURL(_ url: URL)
    
    // MARK: - Gamification Feature
    
    /// Creates a quiz generation service.
    func makeQuizGenerationService() -> QuizGenerationService
    
    /// Creates an achievement service.
    func makeAchievementService() -> AchievementService
}