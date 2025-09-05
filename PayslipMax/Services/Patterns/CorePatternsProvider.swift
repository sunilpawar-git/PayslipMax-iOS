import Foundation

/// Coordinator for accessing domain-specific pattern providers.
///
/// This class has been refactored as part of SOLID compliance improvements to follow
/// the Single Responsibility Principle. Instead of directly implementing all pattern
/// definitions, it now coordinates between domain-specific providers.
///
/// ## Architectural Improvements
///
/// The refactored `CorePatternsProvider` now follows the Coordinator pattern:
/// - **Personal Information**: Delegated to `PersonalInfoPatternsProvider`
/// - **Financial Data**: Delegated to `FinancialPatternsProvider`
/// - **Banking Information**: Delegated to `BankingPatternsProvider`
/// - **Tax Information**: Delegated to `TaxPatternsProvider`
/// - **Coordination**: Handled by this class (aggregation only)
///
/// This separation allows:
/// - Independent development and testing of domain-specific patterns
/// - Easier maintenance of patterns within specific domains
/// - Better extensibility for new pattern categories
/// - Clearer responsibility boundaries between different data domains
///
/// ## Component Relationships
///
/// The provider coordinates between:
/// - **Domain Providers**: Specialized providers for different data categories
/// - **Pattern Repository**: Consumers that need aggregated pattern collections
/// - **Existing Clients**: Maintains the same interface for backward compatibility
///
/// The public interface remains unchanged, ensuring backward compatibility while
/// improving internal architecture quality.
class CorePatternsProvider {
    /// Retrieves all default core patterns organized by category.
    ///
    /// This method now delegates to domain-specific providers while maintaining
    /// the same public interface for backward compatibility.
    ///
    /// - Returns: A complete array of core `PatternDefinition` objects across all categories.
    static func getDefaultCorePatterns() -> [PatternDefinition] {
        var patterns: [PatternDefinition] = []
        
        // Delegate to domain-specific providers
        patterns.append(contentsOf: PersonalInfoPatternsProvider.getPersonalInfoPatterns())
        patterns.append(contentsOf: FinancialPatternsProvider.getEarningsPatterns())
        patterns.append(contentsOf: FinancialPatternsProvider.getDeductionsPatterns())
        patterns.append(contentsOf: BankingPatternsProvider.getBankingPatterns())
        patterns.append(contentsOf: TaxPatternsProvider.getTaxPatterns())
        
        return patterns
    }
    
    // MARK: - Legacy Delegation Methods
    // These methods maintain backward compatibility by delegating to domain-specific providers
    
    /// Creates pattern definitions for extracting personal information from payslips.
    ///
    /// This method delegates to PersonalInfoPatternsProvider for backward compatibility.
    ///
    /// - Returns: An array of `PatternDefinition` objects for personal information extraction.
    static func getPersonalInfoPatterns() -> [PatternDefinition] {
        return PersonalInfoPatternsProvider.getPersonalInfoPatterns()
    }
    
    /// Creates pattern definitions for extracting earnings-related financial data.
    ///
    /// This method delegates to FinancialPatternsProvider for backward compatibility.
    ///
    /// - Returns: An array of `PatternDefinition` objects for earnings extraction.
    static func getEarningsPatterns() -> [PatternDefinition] {
        return FinancialPatternsProvider.getEarningsPatterns()
    }
    
    /// Creates pattern definitions for extracting deduction-related financial data.
    ///
    /// This method delegates to FinancialPatternsProvider for backward compatibility.
    ///
    /// - Returns: An array of `PatternDefinition` objects for deductions extraction.
    static func getDeductionsPatterns() -> [PatternDefinition] {
        return FinancialPatternsProvider.getDeductionsPatterns()
    }
    
    /// Creates pattern definitions for extracting banking information from payslips.
    ///
    /// This method delegates to BankingPatternsProvider for backward compatibility.
    ///
    /// - Returns: An array of `PatternDefinition` objects for banking information extraction.
    static func getBankingPatterns() -> [PatternDefinition] {
        return BankingPatternsProvider.getBankingPatterns()
    }
    
    /// Creates pattern definitions for extracting tax information from payslips.
    ///
    /// This method delegates to TaxPatternsProvider for backward compatibility.
    ///
    /// - Returns: An array of `PatternDefinition` objects for tax information extraction.
    static func getTaxPatterns() -> [PatternDefinition] {
        return TaxPatternsProvider.getTaxPatterns()
    }
} 