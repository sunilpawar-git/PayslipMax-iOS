import XCTest
import SwiftUI
@testable import PayslipMax

@MainActor
final class DIContainerWiringTests: XCTestCase {

    // MARK: - Helpers

    private func makeProdContainer() -> DIContainer {
        DIContainer(useMocks: false)
    }

    private func makeMockContainer() -> DIContainer {
        DIContainer(useMocks: true)
    }

    // MARK: - Default wiring (non-mock)

    func test_DefaultWiring_resolvesExpectedImplementations() {
        let container = makeProdContainer()

        // Core services via factory methods
        let pdfService = container.makePDFService()
        XCTAssertTrue(pdfService is PDFServiceAdapter)

        let dataService = container.makeDataService()
        XCTAssertTrue(dataService is DataServiceImpl)

        let securityService = container.makeSecurityService()
        XCTAssertTrue(securityService is SecurityServiceImpl)

        // Processing services via factory methods
        let pdfTextExtraction = container.makePDFTextExtractionService()
        XCTAssertTrue(pdfTextExtraction is PDFTextExtractionService)

        let formatDetection = container.makePayslipFormatDetectionService()
        XCTAssertNotNil(formatDetection)

        let validationService = container.makePayslipValidationService()
        XCTAssertNotNil(validationService)

        // PDF extractor may be DefaultPDFExtractor or ModularPDFExtractor depending on ServiceRegistry
        let pdfExtractor = container.makePDFExtractor()
        XCTAssertNotNil(pdfExtractor)
    }

    // MARK: - Mock wiring

    func test_MockWiring_resolvesMocksWhenUseMocksEnabled() {
        let container = makeMockContainer()

        // Core services via factory methods
        let pdfService = container.makePDFService()
        XCTAssertTrue(pdfService is MockPDFService)

        // DataService is intentionally DataServiceImpl even under mocks (uses mock Security under the hood)
        let dataService = container.makeDataService()
        XCTAssertTrue(dataService is DataServiceImpl)

        let securityService = container.makeSecurityService()
        XCTAssertTrue(securityService is CoreMockSecurityService)

        // Processing services via factory methods
        let pdfTextExtraction = container.makePDFTextExtractionService()
        XCTAssertNotNil(pdfTextExtraction)

        let formatDetection = container.makePayslipFormatDetectionService()
        XCTAssertNotNil(formatDetection)

        let validationService = container.makePayslipValidationService()
        XCTAssertNotNil(validationService)

        let encryptionService = container.makeEncryptionService()
        XCTAssertNotNil(encryptionService)

        let payslipEncryptionService = container.makePayslipEncryptionService()
        XCTAssertTrue(payslipEncryptionService is MockPayslipEncryptionService)

        let secureStorage = container.makeSecureStorage()
        XCTAssertTrue(secureStorage is MockSecureStorage)

        let pdfExtractor = container.makePDFExtractor()
        XCTAssertTrue(pdfExtractor is MockPDFExtractor)
    }

    // MARK: - ServiceRegistry behavior

    func test_ServiceRegistry_duplicateRegistration_latestWins() {
        protocol TestRegistryProtocol {}
        final class ImplA: TestRegistryProtocol {}
        final class ImplB: TestRegistryProtocol {}

        // Register A then B for the same protocol
        ServiceRegistry.shared.register(TestRegistryProtocol.self, instance: ImplA())
        ServiceRegistry.shared.register(TestRegistryProtocol.self, instance: ImplB())

        let resolved: TestRegistryProtocol? = ServiceRegistry.shared.resolve(TestRegistryProtocol.self)
        XCTAssertNotNil(resolved)
        XCTAssertTrue(resolved is ImplB, "Latest registration should win")
    }

    func test_ServiceRegistry_canOverride_DIResolutionForKnownType() {
        // Use DestinationFactoryProtocol which DIContainer can also create
        final class DummyFactory: DestinationFactoryProtocol {
            @ViewBuilder
            func makeDestinationView(for destination: AppNavigationDestination) -> AnyView { AnyView(EmptyView()) }
            @ViewBuilder
            func makeModalView(for destination: AppNavigationDestination, isSheet: Bool, onDismiss: @escaping () -> Void) -> AnyView { AnyView(EmptyView()) }
        }

        // Register override directly in ServiceRegistry and verify resolve from registry
        ServiceRegistry.shared.register((any DestinationFactoryProtocol).self, instance: DummyFactory())
        let resolvedFromRegistry: (any DestinationFactoryProtocol)? = ServiceRegistry.shared.resolve((any DestinationFactoryProtocol).self)
        XCTAssertNotNil(resolvedFromRegistry)
        XCTAssertTrue(resolvedFromRegistry is DummyFactory)
    }

    // MARK: - Feature mocks

    func test_WebUploadService_mockToggleSwapsImplementation() {
        let container = makeProdContainer()

        // Default should be real (coordinator-based) service
        let realService = container.makeWebUploadService()
        XCTAssertFalse(realService is MockWebUploadService)

        // Toggle mock
        container.toggleWebUploadMock(true)
        let mockService = container.makeWebUploadService()
        XCTAssertTrue(mockService is MockWebUploadService)
    }

    // MARK: - Resolve returns nil for unknown type

    func test_Resolve_unregisteredTypeReturnsNil() {
        let container = makeProdContainer()
        protocol UnregisteredProtocol {}
        let none = container.resolve(UnregisteredProtocol.self)
        XCTAssertNil(none)
    }
}


