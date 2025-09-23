import Foundation
import PDFKit
import Combine

/// View model for pattern testing
/// Follows MVVM architecture with dependency injection and clean separation of concerns
class PatternTestingViewModel: ObservableObject {

    // MARK: - Properties

    // Loading state
    @Published var isLoading = false

    // PDF document
    @Published var pdfDocument: PDFDocument?

    // Error handling
    @Published var showError = false
    @Published var errorMessage = ""

    // Test results
    @Published var isTestSuccessful = false

    // Services
    private let patternTestingService: PatternTestingServiceProtocol

    // MARK: - Initialization

    /// Initialize the pattern testing view model
    /// - Parameter patternTestingService: The service for pattern testing operations
    init(patternTestingService: PatternTestingServiceProtocol? = nil) {
        // Use dependency injection or resolve from container
        if let service = patternTestingService {
            self.patternTestingService = service
        } else {
            self.patternTestingService = Self.createDefaultPatternTestingService()
        }
    }

    // MARK: - PDF Loading

    /// Load a PDF document from a URL
    /// - Parameter url: The URL of the PDF document to load
    func loadPDF(from url: URL) {
        isLoading = true

        guard let document = PDFDocument(url: url) else {
            showError(message: "Could not load PDF document")
            isLoading = false
            return
        }

        pdfDocument = document
        isLoading = false
    }

    // MARK: - Pattern Testing

    /// Test a pattern against the loaded PDF document
    /// - Parameters:
    ///   - pattern: The pattern definition to test
    ///   - document: The PDF document to test against
    /// - Returns: The extracted value if successful, nil otherwise
    @MainActor
    func testPattern(pattern: PatternDefinition, document: PDFDocument) async -> String? {
        isLoading = true
        isTestSuccessful = false

        // Delegate to the pattern testing service
        let extractedValue = await patternTestingService.testPattern(pattern, against: document)

        isLoading = false
        isTestSuccessful = extractedValue != nil && !extractedValue!.isEmpty

        // Save test results for analytics
        patternTestingService.saveTestResults(pattern: pattern, testValue: extractedValue)

        return extractedValue
    }

    // MARK: - Error Handling

    /// Show an error message
    /// - Parameter message: The error message to display
    func showError(message: String) {
        errorMessage = message
        showError = true
    }

    // MARK: - Private Methods

    /// Create the default pattern testing service with all dependencies
    /// - Returns: A fully configured PatternTestingService instance
    private static func createDefaultPatternTestingService() -> PatternTestingServiceProtocol {
        // Resolve services from dependency container on MainActor
        let patternProvider = MainActor.assumeIsolated {
            AppContainer.shared.resolve(PatternProvider.self) ?? DefaultPatternProvider()
        }
        let textExtractor = MainActor.assumeIsolated {
            AppContainer.shared.resolve(TextExtractor.self) ?? DefaultTextExtractor(patternProvider: patternProvider)
        }
        let analyticsService = MainActor.assumeIsolated {
            AppContainer.shared.resolve(ExtractionAnalyticsProtocol.self)!
        }

        let validator = PayslipValidator(patternProvider: patternProvider)
        let builder = PayslipBuilder(patternProvider: patternProvider, validator: validator)

        let patternMatcher = UnifiedPatternMatcher()
        let patternValidator = UnifiedPatternValidator(patternProvider: patternProvider)
        let patternDefinitions = UnifiedPatternDefinitions(patternProvider: patternProvider)

        let patternManager = PayslipPatternManager(
            patternMatcher: patternMatcher,
            patternValidator: patternValidator,
            patternDefinitions: patternDefinitions,
            payslipBuilder: builder
        )

        // Resolve pattern application strategies from container
        let patternStrategies = MainActor.assumeIsolated {
            AppContainer.shared.resolve(PatternApplicationStrategies.self) ?? PatternApplicationStrategies()
        }

        return PatternTestingService(
            textExtractor: textExtractor,
            patternManager: patternManager,
            analyticsService: analyticsService,
            patternStrategies: patternStrategies
        )
    }
}
