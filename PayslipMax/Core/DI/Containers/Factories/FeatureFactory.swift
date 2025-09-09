import Foundation
import PDFKit

/// Factory for feature-specific services in the DI container.
/// Handles Quiz, Achievement, WebUpload, and other feature services.
@MainActor
class FeatureFactory {

    // MARK: - Dependencies

    /// Feature container for accessing feature services
    private let featureContainer: FeatureContainerProtocol

    /// Whether to use mock implementations for testing
    private let useMocks: Bool

    // MARK: - Initialization

    init(useMocks: Bool = false, featureContainer: FeatureContainerProtocol) {
        self.useMocks = useMocks
        self.featureContainer = featureContainer
    }

    // MARK: - Quiz Services

    /// Creates a QuizGenerationService.
    func makeQuizGenerationService() -> QuizGenerationService {
        return featureContainer.makeQuizGenerationService()
    }

    /// Creates an AchievementService.
    func makeAchievementService() -> AchievementService {
        return featureContainer.makeAchievementService()
    }

    // MARK: - WebUpload Services

    /// Toggles WebUpload mock usage.
    func toggleWebUploadMock(_ useMock: Bool) {
        featureContainer.toggleWebUploadMock(useMock)
    }

    /// Sets WebAPI base URL.
    func setWebAPIBaseURL(_ url: URL) {
        featureContainer.setWebAPIBaseURL(url)
    }

    /// Creates a WebUploadService.
    func makeWebUploadService() -> WebUploadServiceProtocol {
        return featureContainer.makeWebUploadService()
    }

    /// Creates a WebUploadDeepLinkHandler.
    func makeWebUploadDeepLinkHandler() -> WebUploadDeepLinkHandler {
        return featureContainer.makeWebUploadDeepLinkHandler()
    }

    // MARK: - Subscription Service

    /// Creates a SubscriptionManager.
    func makeSubscriptionManager() -> SubscriptionManager {
        return featureContainer.makeSubscriptionManager()
    }

    // MARK: - Cache Management

    /// Clears feature caches.
    func clearFeatureCaches() {
        featureContainer.clearFeatureCaches()
    }
}
