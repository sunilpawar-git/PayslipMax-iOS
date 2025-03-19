import Foundation
import PDFKit
import SwiftUI

@MainActor
class DIContainer {
    // MARK: - Properties
    
    /// The shared instance of the DI container.
    static let shared = DIContainer()
    
    /// Whether to use mock implementations for testing.
    var useMocks: Bool = false
    
    // MARK: - Initialization
    
    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }
    
    // MARK: - Factory Methods
    
    /// Creates a HomeViewModel.
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            pdfService: pdfService,
            pdfExtractor: pdfExtractor,
            dataService: dataService
        )
    }
    
    /// Creates a PDF service.
    func makePDFService() -> PDFService {
        return DefaultPDFService()
    }
    
    /// Creates an auth view model.
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(securityService: securityService)
    }
    
    /// Creates a payslips view model.
    func makePayslipsViewModel() -> PayslipsViewModel {
        return PayslipsViewModel(dataService: dataService)
    }
    
    /// Creates an insights view model.
    func makeInsightsViewModel() -> InsightsViewModel {
        return InsightsViewModel(dataService: dataService)
    }
    
    /// Creates a settings view model.
    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(securityService: securityService, dataService: dataService)
    }
    
    /// Creates a security view model (for settings).
    func makeSecurityViewModel() -> SecurityViewModel {
        return SecurityViewModel()
    }
    
    // MARK: - Legacy Service Properties
    
    var pdfService: PDFServiceProtocol {
        get {
            return PDFServiceAdapter(makePDFService())
        }
    }
    
    var dataService: DataServiceProtocol {
        get {
            #if DEBUG
            if useMocks {
                return MockDataService()
            }
            #endif
            return DataServiceImpl(securityService: securityService)
        }
    }
    
    var pdfExtractor: PDFExtractorProtocol {
        get {
            #if DEBUG
            if useMocks {
                return MockPDFExtractor()
            }
            #endif
            return DefaultPDFExtractor()
        }
    }
    
    var securityService: SecurityServiceProtocol {
        get {
            #if DEBUG
            if useMocks {
                return MockSecurityService()
            }
            #endif
            return SecurityServiceImpl()
        }
    }
    
    var biometricAuthService: BiometricAuthService {
        get {
            return BiometricAuthService()
        }
    }
    
    // MARK: - Testing Utilities
    
    static var forTesting: DIContainer {
        return DIContainer(useMocks: true)
    }
    
    static func setShared(_ container: DIContainer) {
        // This method is only meant for testing
        #if DEBUG
        // Use Objective-C runtime to directly modify the shared property
        objc_setAssociatedObject(DIContainer.self, "shared", container, .OBJC_ASSOCIATION_RETAIN)
        #endif
    }
} 