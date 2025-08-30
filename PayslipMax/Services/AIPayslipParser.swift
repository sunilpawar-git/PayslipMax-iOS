import Foundation
import Vision
import PDFKit
import SwiftUI

/// A modern Vision-based payslip parser that uses Apple's Vision framework
/// Enhanced with Phase 4 adaptive learning capabilities
class VisionPayslipParser: PayslipParser {
    // MARK: - Properties

    /// Dictionary to store user corrections for learning
    private var userCorrections: [String: String] = [:]

    /// Learning engine for adaptive improvements
    private let learningEngine: AdaptiveLearningEngineProtocol?

    /// User feedback processor for capturing corrections
    private let feedbackProcessor: UserFeedbackProcessorProtocol?

    /// Personalized insights engine for user-specific optimizations
    private let insightsEngine: PersonalizedInsightsEngineProtocol?

    /// Parser performance tracker
    private let performanceTracker: PerformanceTrackerProtocol?

    /// Name of the parser for identification
    var name: String {
        return "VisionPayslipParser"
    }

    // MARK: - Initialization

    /// Initialize parser with learning capabilities
    init(
        learningEngine: AdaptiveLearningEngineProtocol? = nil,
        feedbackProcessor: UserFeedbackProcessorProtocol? = nil,
        insightsEngine: PersonalizedInsightsEngineProtocol? = nil,
        performanceTracker: PerformanceTrackerProtocol? = nil
    ) {
        self.learningEngine = learningEngine
        self.feedbackProcessor = feedbackProcessor
        self.insightsEngine = insightsEngine
        self.performanceTracker = performanceTracker
    }
    
    // MARK: - Protocol Methods
    
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A PayslipItem if parsing is successful, nil otherwise
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        // ✅ CLEAN: Eliminated DispatchSemaphore - using DispatchGroup for cleaner concurrency
        var result: PayslipItem?
        let group = DispatchGroup()
        
        group.enter()
        Task {
            do {
                result = try await parseInternal(pdfDocument: pdfDocument)
                group.leave()
            } catch {
                print("Error parsing payslip: \(error)")
                group.leave()
            }
        }
        
        // Wait for the async task to complete
        group.wait()
        return result
    }
    
    /// Evaluates the confidence level of the parsing result
    /// - Parameter payslipItem: The parsed PayslipItem
    /// - Returns: The confidence level of the parsing result
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        // Basic confidence evaluation based on required fields
        if payslipItem.name != "Unknown" && 
           payslipItem.month != "Unknown" && 
           payslipItem.credits > 0 && 
           payslipItem.debits > 0 {
            return .high
        } else if payslipItem.name != "Unknown" && 
                  (payslipItem.credits > 0 || payslipItem.debits > 0) {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Internal Methods
    
    /// Internal async implementation of the parsing logic
    private func parseInternal(pdfDocument: PDFDocument) async throws -> PayslipItem {
        let startTime = Date()

        var allText = ""

        // Extract text from all pages
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let text = try await extractText(from: page) else { continue }
            allText += text + "\n"
        }

        // Apply learned corrections to improve text recognition
        let correctedText = applyLearnedCorrections(to: allText)

        // Parse components with learning-enhanced extraction
        let personalInfo = extractPersonalInfo(from: correctedText)
        let earnings = extractEarnings(from: correctedText)
        let deductions = extractDeductions(from: correctedText)
        let _ = extractNetRemittance(from: correctedText)
        let dsop = extractDSOP(from: correctedText)
        let tax = extractIncomeTax(from: correctedText)

        // Apply learning adaptations asynchronously (fire-and-forget)
        Task.detached { [weak self] in
            await self?.applyLearningAdaptations(to: earnings, deductions: deductions, dsop: dsop, tax: tax, from: correctedText)
        }

        // Create PayslipItem
        let payslip = PayslipItem(
            month: personalInfo.month ?? "Unknown",
            year: personalInfo.year ?? Calendar.current.component(.year, from: Date()),
            credits: earnings.values.reduce(0, +),
            debits: deductions.values.reduce(0, +),
            dsop: dsop,
            tax: tax,
            name: personalInfo.name ?? "Unknown",
            accountNumber: personalInfo.accountNumber ?? "Unknown",
            panNumber: personalInfo.panNumber ?? "Unknown"
        )

        payslip.earnings = earnings
        payslip.deductions = deductions

        // Track parsing performance for learning (async)
        let processingTime = Date().timeIntervalSince(startTime)
        Task.detached { [weak self] in
            await self?.trackParsingPerformance(
                documentType: .corporate, // Could be enhanced to detect document type
                processingTime: processingTime,
                accuracy: self?.evaluateConfidence(for: payslip) ?? .low
            )
        }

        return payslip
    }
    
    /// Applies a user correction to improve future parsing
    /// - Parameters:
    ///   - originalText: The original incorrectly recognized text
    ///   - correctedText: The user-provided correct text
    func applyUserCorrection(originalText: String, correctedText: String) {
        userCorrections[originalText] = correctedText

        // Phase 4: Integrate with learning system
        Task {
            await processCorrectionForLearning(originalText: originalText, correctedText: correctedText)
        }
    }

    /// Process correction through the learning system
    private func processCorrectionForLearning(originalText: String, correctedText: String) async {
        guard let _ = learningEngine,
              let feedbackProcessor = feedbackProcessor else { return }

        do {
            // Create a user correction object
            let correction = UserCorrection(
                fieldName: "text_recognition",
                originalValue: originalText,
                correctedValue: correctedText,
                documentType: .corporate,
                parserUsed: name,
                timestamp: Date(),
                confidenceImpact: 0.1,
                extractedPattern: originalText,
                suggestedValidationRule: nil,
                totalExtractions: 1
            )

            // Process through feedback processor
            try await feedbackProcessor.captureUserCorrection(correction)

        } catch {
            print("[VisionPayslipParser] Error processing correction for learning: \(error)")
        }
    }
    // MARK: - Private Methods
    
    /// Extracts text from a PDF page using Vision framework
    private func extractText(from page: PDFPage) async throws -> String? {
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: pageRect.size))
            ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let text = observations.compactMap { observation -> String? in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: text)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            do {
                try VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
                    .perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Extracts personal information from text
    private func extractPersonalInfo(from text: String) -> (name: String?, accountNumber: String?, panNumber: String?, month: String?, year: Int?) {
        let name = text.match(pattern: "Name:\\s*([^\\n]+)")
        let accountNumber = text.match(pattern: "A/C(?:\\s+No)?[.:]?\\s*([^\\n]+)")
        let panNumber = text.match(pattern: "PAN\\s*(?:No)?[.:]?\\s*([^\\n]+)")
        
        // Extract month and year
        let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        var month: String?
        var year: Int?
        
        for monthName in months {
            if text.contains(monthName) {
                month = monthName
                if let yearStr = text.match(pattern: "\\b(20\\d{2})\\b"),
                   let yearInt = Int(yearStr) {
                    year = yearInt
                }
                break
            }
        }
        
        return (name, accountNumber, panNumber, month, year)
    }
    
    /// Extracts earnings from text
    private func extractEarnings(from text: String) -> [String: Double] {
        var earnings: [String: Double] = [:]
        
        // Standard components
        let standardComponents = [
            "Basic Pay",
            "Grade Pay",
            "Military Service Pay",
            "Dearness Allowance",
            "Transport Allowance",
            "House Rent Allowance"
        ]
        
        for component in standardComponents {
            if let amount = extractAmount(for: component, from: text) {
                earnings[component] = amount
            }
        }
        
        return earnings
    }
    
    /// Extracts deductions from text
    private func extractDeductions(from text: String) -> [String: Double] {
        var deductions: [String: Double] = [:]
        
        // Standard components
        let standardComponents = [
            "DSOP Fund",
            "AGIF",
            "Income Tax",
            "AFMS",
            "ACWF"
        ]
        
        for component in standardComponents {
            if let amount = extractAmount(for: component, from: text) {
                deductions[component] = amount
            }
        }
        
        return deductions
    }
    
    /// Extracts net remittance from text
    private func extractNetRemittance(from text: String) -> Double {
        let patterns = [
            "Net\\s+Remittance\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)",
            "Net\\s+Amount\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)"
        ]
        
        for pattern in patterns {
            if let amountStr = text.match(pattern: pattern)?.replacingOccurrences(of: ",", with: ""),
               let amount = Double(amountStr) {
                return amount
            }
        }
        
        return 0
    }
    
    /// Extracts DSOP amount from text
    private func extractDSOP(from text: String) -> Double {
        let patterns = [
            "DSOP\\s+Fund\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)",
            "PF\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)"
        ]
        
        for pattern in patterns {
            if let amountStr = text.match(pattern: pattern)?.replacingOccurrences(of: ",", with: ""),
               let amount = Double(amountStr) {
                return amount
            }
        }
        
        return 0
    }
    
    /// Extracts income tax amount from text
    private func extractIncomeTax(from text: String) -> Double {
        let patterns = [
            "Income\\s+Tax\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)",
            "ITAX\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)"
        ]
        
        for pattern in patterns {
            if let amountStr = text.match(pattern: pattern)?.replacingOccurrences(of: ",", with: ""),
               let amount = Double(amountStr) {
                return amount
            }
        }
        
        return 0
    }
    /// Helper function to extract amount for a component
    private func extractAmount(for component: String, from text: String) -> Double? {
        let pattern = "\\(\(component)\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)"
        if let amountStr = text.match(pattern: pattern)?.replacingOccurrences(of: ",", with: ""),
           let amount = Double(amountStr) {
            return amount
        }
        return nil
    }

    // MARK: - Phase 4 Learning Methods

    /// Apply learned corrections to improve text recognition
    private func applyLearnedCorrections(to text: String) -> String {
        var correctedText = text

        // Apply stored corrections
        for (original, correction) in userCorrections {
            correctedText = correctedText.replacingOccurrences(of: original, with: correction)
        }

        return correctedText
    }

    /// Apply learning adaptations asynchronously
    private func applyLearningAdaptations(to earnings: [String: Double], deductions: [String: Double], dsop: Double, tax: Double, from text: String) async {
        guard let learningEngine = learningEngine else { return }

        do {
            // Get parser adaptations
            let adaptations = try await learningEngine.adaptParserParameters(for: name, documentType: .corporate)

            // Apply adaptations to extracted data (for future processing)
            _ = applyParserAdaptations(adaptations, to: earnings, text: text)
            _ = applyParserAdaptations(adaptations, to: deductions, text: text)

            // Apply confidence adjustments
            let dsopAdjustment = await learningEngine.getConfidenceAdjustment(for: "DSOP", documentType: .corporate)
            let taxAdjustment = await learningEngine.getConfidenceAdjustment(for: "IncomeTax", documentType: .corporate)

            if dsopAdjustment != 0.0 || taxAdjustment != 0.0 {
                print("[VisionPayslipParser] Applied learning adjustments: DSOP=\(dsopAdjustment), Tax=\(taxAdjustment)")
            }

        } catch {
            print("[VisionPayslipParser] Error applying learning adaptations: \(error)")
        }
    }

    /// Apply parser adaptations to extracted data
    private func applyParserAdaptations(_ adaptations: ParserAdaptation, to data: [String: Double], text: String) -> [String: Double] {
        var adaptedData = data

        for (fieldName, adaptation) in adaptations.adaptations {
            if let fieldAdaptation = adaptation as? FieldAdaptation {
                // Apply preferred patterns
                for pattern in fieldAdaptation.preferredPatterns {
                    if let amount = extractAmount(for: pattern, from: text) {
                        adaptedData[pattern] = amount
                        break
                    }
                }

                // Apply confidence adjustments
                if let existingAmount = adaptedData[fieldName] {
                    adaptedData[fieldName] = existingAmount * (1.0 + fieldAdaptation.confidenceAdjustment)
                }
            }
        }

        return adaptedData
    }

    /// Track parsing performance for learning system
    private func trackParsingPerformance(documentType: LiteRTDocumentFormatType, processingTime: TimeInterval, accuracy: ParsingConfidence) async {
        guard let performanceTracker = performanceTracker else { return }

        let metrics = ParserPerformanceMetrics(
            parserName: name,
            documentType: documentType,
            processingTime: processingTime,
            accuracy: Double(accuracy.rawValue),
            fieldsExtracted: 5, // Estimate fields extracted
            fieldsCorrect: Int(5.0 * Double(accuracy.rawValue)), // Estimate correct fields based on accuracy
            memoryUsage: 0, // Not tracked in this implementation
            cpuUsage: 0.0  // Not tracked in this implementation
        )

        do {
            try await performanceTracker.recordPerformance(metrics)
        } catch {
            print("[VisionPayslipParser] Error tracking performance: \(error)")
        }
    }
}
// MARK: - String Extension
extension String {
    /// Returns the first match of the pattern in the string
    func match(pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) else {
            return nil
        }
        
        if match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: self) {
            return String(self[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}