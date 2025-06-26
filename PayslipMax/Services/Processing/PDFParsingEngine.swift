import Foundation
import PDFKit

/// Core parsing engine that runs parsers and collects results
final class PDFParsingEngine {
    
    // MARK: - Types
    
    struct ParsingResult {
        let payslipItem: PayslipItem?
        let confidence: ParsingConfidence
        let parserName: String
        let processingTime: TimeInterval
    }
    
    // MARK: - Parsing Methods
    
    /// Parses a PDF document using multiple parsers and returns the best result
    /// - Parameters:
    ///   - pdfDocument: The PDF document to parse
    ///   - fullText: The extracted text from the document
    ///   - parserSelector: The parser selector to use
    /// - Returns: The best parsing result, or nil if all parsers failed
    func parseWithMultipleParsers(
        pdfDocument: PDFDocument,
        fullText: String,
        parserSelector: PDFParserSelector
    ) async throws -> ParsingResult? {
        
        // Check if the PDF is empty
        guard pdfDocument.pageCount > 0 else {
            print("[PDFParsingEngine] PDF document is empty")
            return nil
        }
        
        var bestResult: PayslipItem? = nil
        var bestConfidence: ParsingConfidence = .low
        var bestParserName: String = ""
        var bestProcessingTime: TimeInterval = 0
        var parsingResults: [(parser: PayslipParser, result: PayslipItem?, time: TimeInterval)] = []
        var telemetryCollection: [ParserTelemetry] = []
        
        let availableParsers = parserSelector.getAllParsers()
        print("[PDFParsingEngine] Starting PDF parsing with \(availableParsers.count) available parsers")
        
        // Try to get a specialized parser for this document
        let selectedParser = parserSelector.selectBestParser(for: fullText)
        let parsersToTry: [PayslipParser]
        
        if let selectedParser = selectedParser {
            print("[PDFParsingEngine] Selected specialized parser: \(selectedParser.name)")
            parsersToTry = [selectedParser] // Try only the specialized parser first
        } else {
            print("[PDFParsingEngine] No specialized parser found, trying all parsers")
            parsersToTry = availableParsers // Try all parsers
        }
        
        // Try each parser and select the best result
        for parser in parsersToTry {
            print("[PDFParsingEngine] Attempting to parse with \(parser.name)")
            let startTime = Date()
            
            if let result = try await parser.parsePayslip(pdfDocument: pdfDocument) {
                let processingTime = Date().timeIntervalSince(startTime)
                let confidence = parser.evaluateConfidence(for: result)
                
                print("[PDFParsingEngine] Parser \(parser.name) succeeded with confidence: \(confidence) in \(String(format: "%.2f", processingTime)) seconds")
                
                parsingResults.append((parser: parser, result: result, time: processingTime))
                
                // Update best result if this one has higher confidence
                if bestResult == nil || confidence > bestConfidence {
                    print("[PDFParsingEngine] New best result from \(parser.name) with confidence \(confidence)")
                    bestResult = result
                    bestConfidence = confidence
                    bestParserName = parser.name
                    bestProcessingTime = processingTime
                }
                
                // Collect telemetry data
                telemetryCollection.append(createTelemetry(
                    parser: parser,
                    result: result,
                    processingTime: processingTime,
                    success: true
                ))
            } else {
                let processingTime = Date().timeIntervalSince(startTime)
                print("[PDFParsingEngine] Parser \(parser.name) failed in \(String(format: "%.2f", processingTime)) seconds")
                
                telemetryCollection.append(createTelemetry(
                    parser: parser,
                    result: nil,
                    processingTime: processingTime,
                    success: false
                ))
            }
        }
        
        // If the specialized parser failed but we have other parsers available, try them too
        if bestResult == nil && selectedParser != nil && availableParsers.count > 1 {
            print("[PDFParsingEngine] Specialized parser failed, trying other parsers")
            
            // Try remaining parsers
            let remainingParsers = availableParsers.filter { $0.name != selectedParser!.name }
            for parser in remainingParsers {
                print("[PDFParsingEngine] Attempting to parse with fallback parser \(parser.name)")
                let startTime = Date()
                
                if let result = try await parser.parsePayslip(pdfDocument: pdfDocument) {
                    let processingTime = Date().timeIntervalSince(startTime)
                    let confidence = parser.evaluateConfidence(for: result)
                    
                    print("[PDFParsingEngine] Fallback parser \(parser.name) succeeded with confidence: \(confidence) in \(String(format: "%.2f", processingTime)) seconds")
                    
                    parsingResults.append((parser: parser, result: result, time: processingTime))
                    
                    // Update best result if this one has higher confidence
                    if bestResult == nil || confidence > bestConfidence {
                        print("[PDFParsingEngine] New best result from fallback parser \(parser.name) with confidence \(confidence)")
                        bestResult = result
                        bestConfidence = confidence
                        bestParserName = parser.name
                        bestProcessingTime = processingTime
                    }
                    
                    // Collect telemetry data
                    telemetryCollection.append(createTelemetry(
                        parser: parser,
                        result: result,
                        processingTime: processingTime,
                        success: true
                    ))
                } else {
                    let processingTime = Date().timeIntervalSince(startTime)
                    print("[PDFParsingEngine] Fallback parser \(parser.name) failed in \(String(format: "%.2f", processingTime)) seconds")
                    
                    telemetryCollection.append(createTelemetry(
                        parser: parser,
                        result: nil,
                        processingTime: processingTime,
                        success: false
                    ))
                }
            }
        }
        
        // Log parsing summary
        logParsingSummary(parsingResults: parsingResults, telemetryCollection: telemetryCollection)
        
        // Return best result if found
        if let result = bestResult {
            return ParsingResult(
                payslipItem: result,
                confidence: bestConfidence,
                parserName: bestParserName,
                processingTime: bestProcessingTime
            )
        }
        
        return nil
    }
    
    /// Parses a PDF document using a specific parser
    /// - Parameters:
    ///   - pdfDocument: The PDF document to parse
    ///   - parserName: The name of the parser to use
    ///   - parserSelector: The parser selector to use
    /// - Returns: The parsing result, or nil if the parser failed or was not found
    func parseWithSpecificParser(
        pdfDocument: PDFDocument,
        parserName: String,
        parserSelector: PDFParserSelector
    ) async throws -> PayslipItem? {
        guard let parser = parserSelector.getParser(named: parserName) else {
            print("[PDFParsingEngine] Parser '\(parserName)' not found")
            return nil
        }
        
        let startTime = Date()
        let result = try await parser.parsePayslip(pdfDocument: pdfDocument)
        let endTime = Date()
        
        if let payslipItem = result {
            print("[PDFParsingEngine] Parser \(parserName) succeeded in \(endTime.timeIntervalSince(startTime)) seconds")
            return payslipItem
        } else {
            print("[PDFParsingEngine] Parser \(parserName) failed in \(endTime.timeIntervalSince(startTime)) seconds")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func createTelemetry(
        parser: PayslipParser,
        result: PayslipItem?,
        processingTime: TimeInterval,
        success: Bool
    ) -> ParserTelemetry {
        let confidence: ParsingConfidence = success ? parser.evaluateConfidence(for: result!) : .low
        
        // Calculate extracted item counts
        let extractedItemCount: Int
        let textLength: Int
        
        if let payslip = result {
            extractedItemCount = payslip.earnings.count + payslip.deductions.count
            textLength = "\(payslip.month) \(payslip.year) \(payslip.credits) \(payslip.debits)".count
        } else {
            extractedItemCount = 0
            textLength = 0
        }
        
        return ParserTelemetry(
            parserName: parser.name,
            processingTime: processingTime,
            confidence: confidence,
            success: success,
            extractedItemCount: extractedItemCount,
            textLength: textLength
        )
    }
    
    /// Logs detailed information about the parsing process
    private func logParsingSummary(
        parsingResults: [(parser: PayslipParser, result: PayslipItem?, time: TimeInterval)],
        telemetryCollection: [ParserTelemetry]
    ) {
        print("[PDFParsingEngine] PDF Parsing Summary:")
        print("[PDFParsingEngine] ===========================")
        print("[PDFParsingEngine] Total parsers attempted: \(parsingResults.count)")
        
        let successfulResults = parsingResults.filter { $0.result != nil }
        print("[PDFParsingEngine] Successful parsers: \(successfulResults.count)")
        
        if !successfulResults.isEmpty {
            print("[PDFParsingEngine] Successful parsers details:")
            for (parser, result, time) in successfulResults {
                if let result = result {
                    let confidence = evaluateParsingConfidence(result)
                    print("[PDFParsingEngine] - \(parser.name): Confidence: \(confidence), Time: \(String(format: "%.3f", time))s")
                    print("[PDFParsingEngine]   Credits: \(result.credits), Debits: \(result.debits), Name: \(result.name)")
                    print("[PDFParsingEngine]   Month: \(result.month), Year: \(result.year)")
                    print("[PDFParsingEngine]   Earnings items: \(result.earnings.count), Deductions items: \(result.deductions.count)")
                }
            }
        }
        
        let failedResults = parsingResults.filter { $0.result == nil }
        if !failedResults.isEmpty {
            print("[PDFParsingEngine] Failed parsers details:")
            for (parser, _, time) in failedResults {
                print("[PDFParsingEngine] - \(parser.name): Failed, Time: \(String(format: "%.3f", time))s")
            }
        }
        
        print("[PDFParsingEngine] ===========================")
        
        // Log aggregate telemetry
        if !telemetryCollection.isEmpty {
            ParserTelemetry.aggregateAndLogTelemetry(telemetryData: telemetryCollection)
        }
    }
    
    /// Evaluates the confidence level of a parsing result
    private func evaluateParsingConfidence(_ payslip: PayslipItem) -> ParsingConfidence {
        var score = 0
        
        // Check for required fields
        if !payslip.name.isEmpty && payslip.name != "Unknown" { score += 2 }
        if !payslip.month.isEmpty && payslip.month != "Unknown" { score += 2 }
        if payslip.year > 2000 { score += 2 }
        
        // Check financial data
        if payslip.credits > 0 { score += 2 }
        if payslip.debits > 0 { score += 2 }
        if payslip.dsop > 0 { score += 1 }
        if payslip.tax > 0 { score += 1 }
        
        // Check additional fields
        if !payslip.accountNumber.isEmpty && payslip.accountNumber != "Unknown" { score += 1 }
        if !payslip.panNumber.isEmpty && payslip.panNumber != "Unknown" { score += 1 }
        
        // Check earnings and deductions
        if !payslip.earnings.isEmpty { score += 2 }
        if !payslip.deductions.isEmpty { score += 2 }
        
        // Determine confidence level based on score
        if score >= 12 {
            return .high
        } else if score >= 6 {
            return .medium
        } else {
            return .low
        }
    }
} 