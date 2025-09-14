//
//  DIFactoryMethodOrganizer.swift
//  PayslipMax
//
//  Extracted from DIContainer for architectural compliance
//  Organizes factory methods by logical groups to reduce container size
//

import Foundation
import SwiftData

/// Protocol for organizing factory methods into logical groups
protocol DIFactoryMethodOrganizerProtocol {
    // Core Services
    func makePDFProcessingService() -> PDFProcessingServiceProtocol
    func makeTextExtractionService() -> TextExtractionServiceProtocol
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol
    func makePayslipValidationService() -> PayslipValidationServiceProtocol

    // Processing Services
    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol
    func makePayslipProcessorFactory() -> PayslipProcessorFactory
    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline

    // ViewModels
    func makeHomeViewModel() -> HomeViewModel
    func makePayslipsViewModel() -> PayslipsViewModel
    func makeSettingsViewModel() -> SettingsViewModel
    func makeAuthViewModel() -> AuthViewModel

    // Data Services
    func makeDataService() -> DataServiceProtocol
    func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol
    func makePayslipMigrationUtilities(modelContext: ModelContext) -> PayslipMigrationUtilities
    func makePayslipBatchOperations(modelContext: ModelContext) -> PayslipBatchOperations
}

/// Service responsible for organizing and providing factory methods
/// Reduces DIContainer complexity by grouping related factory methods
@MainActor
class DIFactoryMethodOrganizer: @preconcurrency DIFactoryMethodOrganizerProtocol {

    // MARK: - Dependencies
    private let coreServiceFactory: CoreServiceFactory
    private let viewModelFactory: ViewModelFactory
    private let processingFactory: ProcessingFactory
    private let featureFactory: FeatureFactory
    private let globalServiceFactory: GlobalServiceFactory
    private let unifiedFactory: UnifiedDIContainerFactory

    // MARK: - Initialization
    init(
        coreServiceFactory: CoreServiceFactory,
        viewModelFactory: ViewModelFactory,
        processingFactory: ProcessingFactory,
        featureFactory: FeatureFactory,
        globalServiceFactory: GlobalServiceFactory,
        unifiedFactory: UnifiedDIContainerFactory
    ) {
        self.coreServiceFactory = coreServiceFactory
        self.viewModelFactory = viewModelFactory
        self.processingFactory = processingFactory
        self.featureFactory = featureFactory
        self.globalServiceFactory = globalServiceFactory
        self.unifiedFactory = unifiedFactory
    }

    // MARK: - Core Services

    func makePDFProcessingService() -> PDFProcessingServiceProtocol {
        return unifiedFactory.makePDFProcessingService()
    }

    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        return coreServiceFactory.makeTextExtractionService()
    }

    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return coreServiceFactory.makePayslipFormatDetectionService()
    }

    func makePayslipValidationService() -> PayslipValidationServiceProtocol {
        return coreServiceFactory.makePayslipValidationService()
    }

    // MARK: - Processing Services

    func makePDFTextExtractionService() -> PDFTextExtractionServiceProtocol {
        return processingFactory.makePDFTextExtractionService()
    }

    func makePayslipProcessorFactory() -> PayslipProcessorFactory {
        return processingFactory.makePayslipProcessorFactory()
    }

    func makePayslipProcessingPipeline() -> PayslipProcessingPipeline {
        return processingFactory.makePayslipProcessingPipeline()
    }

    // MARK: - ViewModels

    func makeHomeViewModel() -> HomeViewModel {
        return unifiedFactory.makeHomeViewModel()
    }

    func makePayslipsViewModel() -> PayslipsViewModel {
        return unifiedFactory.makePayslipsViewModel()
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        return unifiedFactory.makeSettingsViewModel()
    }

    func makeAuthViewModel() -> AuthViewModel {
        return viewModelFactory.makeAuthViewModel()
    }

    // MARK: - Data Services

    func makeDataService() -> DataServiceProtocol {
        return unifiedFactory.makeDataService()
    }

    func makePayslipRepository(modelContext: ModelContext) -> PayslipRepositoryProtocol {
        return unifiedFactory.makePayslipRepository(modelContext: modelContext)
    }

    func makePayslipMigrationUtilities(modelContext: ModelContext) -> PayslipMigrationUtilities {
        return unifiedFactory.makePayslipMigrationUtilities(modelContext: modelContext)
    }

    func makePayslipBatchOperations(modelContext: ModelContext) -> PayslipBatchOperations {
        return unifiedFactory.makePayslipBatchOperations(modelContext: modelContext)
    }
}

// MARK: - Additional Service Categories

/// Extension for pattern-related services
extension DIFactoryMethodOrganizer {
    func makePatternLoader() -> PatternLoaderProtocol {
        return coreServiceFactory.makePatternLoader()
    }

    func makePatternMatchingService() -> PatternMatchingServiceProtocol {
        return coreServiceFactory.makePatternMatchingService()
    }

    func makeTabularDataExtractor() -> TabularDataExtractorProtocol {
        return coreServiceFactory.makeTabularDataExtractor()
    }
}

/// Extension for security and encryption services
extension DIFactoryMethodOrganizer {
    func makeSecurityService() -> SecurityServiceProtocol {
        return coreServiceFactory.makeSecurityService()
    }

    func makeSecureStorage() -> SecureStorageProtocol {
        return coreServiceFactory.makeSecureStorage()
    }

    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol {
        return coreServiceFactory.makePayslipEncryptionService()
    }

    @MainActor func makeEncryptionService() -> EncryptionServiceProtocol {
        return coreServiceFactory.makeEncryptionService()
    }
}

/// Extension for feature services (WebUpload, Quiz, Achievement)
extension DIFactoryMethodOrganizer {
    func makeWebUploadService() -> WebUploadServiceProtocol {
        return featureFactory.makeWebUploadService()
    }

    func makeQuizGenerationService() -> QuizGenerationService {
        return featureFactory.makeQuizGenerationService()
    }

    func makeAchievementService() -> AchievementService {
        return featureFactory.makeAchievementService()
    }

    @MainActor func makeSubscriptionManager() -> SubscriptionManager {
        return featureFactory.makeSubscriptionManager()
    }
}
