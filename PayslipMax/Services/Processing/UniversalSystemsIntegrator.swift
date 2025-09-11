//
//  UniversalSystemsIntegrator.swift
//  PayslipMax
//
//  Created for Phase 5: Enhanced Structure Preservation
//  Integrates universal pay code search and arrears pattern matching with spatial intelligence
//

import Foundation

/// Service that integrates universal systems with spatial extraction for Phase 5 enhanced processing
final class UniversalSystemsIntegrator {

    // MARK: - Properties

    /// Universal pay code search engine for comprehensive coverage
    private let universalPayCodeSearch: UniversalPayCodeSearchEngineProtocol

    /// Universal arrears pattern matcher for comprehensive arrears detection
    private let universalArrearsPattern: UniversalArrearsPatternMatcherProtocol

    /// Legacy pattern extractor for fallback compatibility
    private let patternExtractor: FinancialPatternExtractor

    // MARK: - Initialization

    /// Initializes the universal systems integrator with required dependencies
    /// - Parameters:
    ///   - universalPayCodeSearch: Universal pay code search engine
    ///   - universalArrearsPattern: Universal arrears pattern matcher
    ///   - patternExtractor: Legacy pattern extractor for fallback
    init(
        universalPayCodeSearch: UniversalPayCodeSearchEngineProtocol,
        universalArrearsPattern: UniversalArrearsPatternMatcherProtocol,
        patternExtractor: FinancialPatternExtractor
    ) {
        self.universalPayCodeSearch = universalPayCodeSearch
        self.universalArrearsPattern = universalArrearsPattern
        self.patternExtractor = patternExtractor
    }

    // MARK: - Public Interface

    /// Enhances existing extraction data with universal systems
    /// - Parameters:
    ///   - existingData: Already extracted data from spatial analysis
    ///   - documentText: Full document text for universal search
    ///   - minimumThreshold: Minimum number of components before using universal systems
    /// - Returns: Enhanced extraction data with universal system results
    func enhanceExtractionWithUniversalSystems(
        existingData: [String: Double],
        documentText: String,
        minimumThreshold: Int = 3
    ) async -> [String: Double] {

        var enhancedData = existingData

        // Only use universal systems if we haven't found enough components
        guard enhancedData.count < minimumThreshold else {
            print("[UniversalSystemsIntegrator] Sufficient data found (\(enhancedData.count) items), skipping universal enhancement")
            return enhancedData
        }

        // Phase 5: Use universal pay code search for comprehensive coverage
        let universalPayCodeResults = await universalPayCodeSearch.searchAllPayCodes(in: documentText)
        for (payCode, searchResult) in universalPayCodeResults {
            if enhancedData[payCode] == nil {
                enhancedData[payCode] = searchResult.value
            }
        }
        print("[UniversalSystemsIntegrator] Universal pay code search added \(universalPayCodeResults.count) items")

        // Phase 5: Use universal arrears pattern matching
        let universalArrearsResults = await universalArrearsPattern.extractArrearsComponents(from: documentText)
        for (arrearsCode, amount) in universalArrearsResults {
            if enhancedData[arrearsCode] == nil {
                enhancedData[arrearsCode] = amount
            }
        }
        print("[UniversalSystemsIntegrator] Universal arrears pattern added \(universalArrearsResults.count) items")

        return enhancedData
    }

    /// Applies universal systems to complement spatial analysis results
    /// - Parameters:
    ///   - spatialData: Data extracted through spatial analysis
    ///   - documentText: Full document text for comprehensive search
    /// - Returns: Complemented data with universal system findings
    func complementSpatialAnalysis(
        spatialData: [String: Double],
        documentText: String
    ) async -> [String: Double] {

        var complementedData = spatialData

        // Use universal systems to find components that spatial analysis might have missed
        let universalResults = await universalPayCodeSearch.searchAllPayCodes(in: documentText)
        for (payCode, searchResult) in universalResults {
            if complementedData[payCode] == nil {
                complementedData[payCode] = searchResult.value
                print("[UniversalSystemsIntegrator] Universal search found missed: \(payCode) = ₹\(searchResult.value)")
            }
        }

        // Use universal arrears matching to find any missed arrears
        let arrearsResults = await universalArrearsPattern.extractArrearsComponents(from: documentText)
        for (arrearsCode, amount) in arrearsResults {
            if complementedData[arrearsCode] == nil {
                complementedData[arrearsCode] = amount
                print("[UniversalSystemsIntegrator] Universal arrears found missed: \(arrearsCode) = ₹\(amount)")
            }
        }

        return complementedData
    }

    /// Provides fallback extraction using universal systems and legacy patterns
    /// - Parameter documentText: Full document text for extraction
    /// - Returns: Extracted financial data using universal systems and legacy fallback
    func extractWithUniversalFallback(from documentText: String) async -> [String: Double] {
        var extractedData: [String: Double] = [:]

        // Step 1: Use universal pay code search for comprehensive coverage
        let universalPayCodeResults = await universalPayCodeSearch.searchAllPayCodes(in: documentText)
        for (payCode, searchResult) in universalPayCodeResults {
            extractedData[payCode] = searchResult.value
        }
        print("[UniversalSystemsIntegrator] Universal pay code search extracted \(universalPayCodeResults.count) items")

        // Step 2: Use universal arrears pattern matching
        let universalArrearsResults = await universalArrearsPattern.extractArrearsComponents(from: documentText)
        for (arrearsCode, amount) in universalArrearsResults {
            if extractedData[arrearsCode] == nil {
                extractedData[arrearsCode] = amount
            }
        }
        print("[UniversalSystemsIntegrator] Universal arrears pattern extracted \(universalArrearsResults.count) items")

        // Step 3: Fallback to legacy patterns only if universal systems didn't find enough
        if extractedData.count < 2 {
            let legacyData = patternExtractor.extractFinancialData(from: documentText)
            for (key, value) in legacyData {
                if extractedData[key] == nil {
                    extractedData[key] = value
                }
            }
            print("[UniversalSystemsIntegrator] Legacy extraction added \(legacyData.count) items")
        }

        return extractedData
    }
}
