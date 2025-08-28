import Foundation

/// AI-powered smart totals reconciler
public class SmartTotalsReconciler: SmartTotalsReconcilerProtocol {

    // MARK: - Properties

    private let liteRTService: LiteRTServiceProtocol
    private let reconciliationEngine: ReconciliationEngine
    private let correctionEngine: CorrectionEngine
    private let suggestionEngine: SuggestionEngine
    private let validationEngine: ReconciliationValidationEngine

    // MARK: - Initialization

    public init(liteRTService: LiteRTServiceProtocol? = nil) {
        if let service = liteRTService {
            self.liteRTService = service
        } else {
            self.liteRTService = LiteRTService()
        }
        self.reconciliationEngine = ReconciliationEngine()
        self.correctionEngine = CorrectionEngine()
        self.suggestionEngine = SuggestionEngine()
        self.validationEngine = ReconciliationValidationEngine()
    }

    // MARK: - Public Methods

    /// Reconcile extracted totals with expected values using AI-powered analysis
    public func reconcileTotals(
        extractedCredits: [String: Double],
        extractedDebits: [String: Double],
        expectedCredits: Double?,
        expectedDebits: Double?,
        documentFormat: LiteRTDocumentFormatType
    ) async throws -> ReconciliationResult {

        return try await reconciliationEngine.reconcileTotals(
            extractedCredits: extractedCredits,
            extractedDebits: extractedDebits,
            expectedCredits: expectedCredits,
            expectedDebits: expectedDebits,
            documentFormat: documentFormat
        )
    }

    /// Suggest corrections for identified discrepancies
    public func suggestCorrections(
        discrepancies: [ReconciliationDiscrepancy],
        context: ReconciliationContext
    ) async throws -> [ReconciliationSuggestion] {

        return try await suggestionEngine.suggestCorrections(
            discrepancies: discrepancies,
            context: context
        )
    }

    /// Apply corrections to financial totals
    public func applyCorrections(
        credits: [String: Double],
        debits: [String: Double],
        corrections: [ReconciliationCorrection]
    ) async throws -> CorrectedTotals {

        return try await correctionEngine.applyCorrections(
            credits: credits,
            debits: debits,
            corrections: corrections
        )
    }

    /// Validate the reconciliation process
    public func validateReconciliation(
        originalTotals: OriginalTotals,
        reconciledTotals: CorrectedTotals
    ) async throws -> ReconciliationValidation {

        return try await validationEngine.validateReconciliation(
            originalTotals: originalTotals,
            reconciledTotals: reconciledTotals
        )
    }
}
