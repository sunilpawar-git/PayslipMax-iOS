import Foundation
import SwiftUI
import _Concurrency

/// Protocol defining the interface for dependency injection containers.
/// 
/// This protocol provides a common interface for accessing dependencies,
/// making it easier to test components that rely on the container.
@preconcurrency protocol DIContainerProtocol {
    // MARK: - Configuration
    
    /// Whether to use mock implementations for testing.
    var useMocks: Bool { get }
    
    // MARK: - Services
    
    /// Creates a PDF processing service.
    func makePDFProcessingService() -> PDFProcessingServiceProtocol
    
    /// Creates a text extraction service.
    func makeTextExtractionService() -> TextExtractionServiceProtocol
    
    /// Creates a payslip format detection service.
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol
    
    /// Creates a PDF validation service.
    func makePayslipValidationService() -> PayslipValidationServiceProtocol
    
    /// Creates a PDF service.
    func makePDFService() -> PDFServiceProtocol
    
    /// Creates a PDF extractor.
    func makePDFExtractor() -> PDFExtractorProtocol
    
    /// Creates a data service.
    func makeDataService() -> DataServiceProtocol
    
    /// Creates a security service.
    func makeSecurityService() -> SecurityServiceProtocol
    
    /// Creates a chart data preparation service.
    func makeChartDataPreparationService() -> ChartDataPreparationService
    
    /// Creates a payslip encryption service.
    func makePayslipEncryptionService() -> PayslipEncryptionServiceProtocol
    
    // MARK: - View Models
    
    /// Creates a home view model.
    func makeHomeViewModel() -> HomeViewModel
    
    /// Creates a payslips view model.
    func makePayslipsViewModel() -> PayslipsViewModel
    
    /// Creates an insights view model.
    func makeInsightsViewModel() -> InsightsViewModel
    
    /// Creates a settings view model.
    func makeSettingsViewModel() -> SettingsViewModel
    
    /// Creates a destination factory.
    func makeDestinationFactory() -> DestinationFactoryProtocol
    
    /// Resolves a service of the specified type
    /// - Returns: An instance of the requested service type
    func resolve<T>(_ type: T.Type) -> T?
}

// MARK: - Extension for DIContainer

/// Make DIContainer conform to DIContainerProtocol
extension DIContainer: DIContainerProtocol {} 