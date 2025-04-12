import Foundation
import PDFKit

/// A modular implementation of the PDF extractor that breaks the extraction process into discrete stages
class ModularPDFExtractor: PDFExtractorProtocol {
    
    private let patternRepository: PatternRepositoryProtocol
    
    init(patternRepository: PatternRepositoryProtocol) {
        self.patternRepository = patternRepository
    }
    
    /// Extracts payslip data from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract data from
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from pdfDocument: PDFDocument) -> PayslipItem? {
        guard let pdfData = pdfDocument.dataRepresentation() else {
            print("ModularPDFExtractor: Failed to get PDF data representation")
            return nil
        }
        
        // Use a synchronous approach here since the function is not async
        var result: PayslipItem? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            do {
                result = try await extractData(from: pdfDocument, pdfData: pdfData)
                semaphore.signal()
            } catch {
                print("ModularPDFExtractor: Error extracting payslip data - \(error.localizedDescription)")
                semaphore.signal()
            }
        }
        
        // Wait for result (with timeout to prevent deadlock)
        _ = semaphore.wait(timeout: .now() + 30)
        return result
    }
    
    /// Extracts payslip data from extracted text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: A PayslipItem if extraction is successful, nil otherwise
    func extractPayslipData(from text: String) -> PayslipItem? {
        // This implementation is a simplified version as we don't have the original PDF data
        print("ModularPDFExtractor: Attempting to extract data from text only")
        
        // Create a dummy PDF document to satisfy the protocol
        let dummyPDF = PDFDocument()
        let dummyPage = PDFPage(image: UIImage())
        if let page = dummyPage {
            dummyPDF.insert(page, at: 0)
        }
        
        // Get all patterns from the repository (need to handle async in a sync function)
        var patterns: [PatternDefinition] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            patterns = await patternRepository.getAllPatterns()
            semaphore.signal()
        }
        
        // Wait with timeout
        _ = semaphore.wait(timeout: .now() + 10)
        
        if patterns.isEmpty {
            print("ModularPDFExtractor: Error - No patterns loaded")
            return nil
        }
        
        // Create a dictionary to store the extracted values
        var data: [String: String] = [:]
        
        // Group patterns by category
        let patternsByCategory = Dictionary(
            grouping: patterns,
            by: { $0.category }
        )
        
        // Process each category of patterns
        for (category, patternsInCategory) in patternsByCategory {
            print("ModularPDFExtractor: Processing category: \(category.rawValue)")
            
            // Sort patterns by priority (using a simple method, not the SortComparator which is causing issues)
            let sortedPatterns = patternsInCategory.sorted(by: { 
                getPatternPriority($0) > getPatternPriority($1)
            })
            
            // Try each pattern until a value is found
            for pattern in sortedPatterns {
                let key = pattern.key
                
                if let value = findValue(for: pattern, in: text) {
                    print("ModularPDFExtractor: Found value for \(key): \(value)")
                    data[key] = value
                    break
                }
            }
        }
        
        // Extract required fields with default values
        let month = data["month"] ?? ""
        let yearString = data["year"] ?? ""
        let name = data["name"] ?? ""
        let accountNumber = data["account_number"] ?? ""
        let panNumber = data["pan_number"] ?? ""
        
        // Convert year to integer if needed
        let year = Int(yearString) ?? Calendar.current.component(.year, from: Date())
        
        // Extract and convert numeric values
        let credits = extractDouble(from: data["credits"] ?? "0")
        let debits = extractDouble(from: data["debits"] ?? "0")
        let tax = extractDouble(from: data["tax"] ?? "0")
        let dsop = extractDouble(from: data["dsop"] ?? "0")
        
        // Validate essential data
        if month.isEmpty || yearString.isEmpty || credits == 0 {
            print("ModularPDFExtractor: Insufficient data extracted from text")
            return nil
        }
        
        // Create a dummy PDF data for the payslip
        let dummyData = Data()
        
        // Create the payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: dummyData
        )
        
        return payslip
    }
    
    /// Extracts text from a PDF document
    /// - Parameter pdfDocument: The PDF document to extract text from
    /// - Returns: The extracted text
    func extractText(from pdfDocument: PDFDocument) -> String {
        return extractTextFromPDF(pdfDocument) ?? ""
    }
    
    /// Gets the available parsers
    /// - Returns: Array of parser names
    func getAvailableParsers() -> [String] {
        return ["ModularParser"]
    }
    
    /// Extract data from a PDF document and return a PayslipItem
    func extractData(from pdfDocument: PDFDocument, pdfData: Data) async throws -> PayslipItem {
        // Log PDF details for debugging
        logPdfDetails(pdfDocument)
        
        // Extract text from the PDF document
        guard let pdfText = extractTextFromPDF(pdfDocument) else {
            print("ModularPDFExtractor: Failed to extract text from PDF")
            throw ModularExtractionError.pdfTextExtractionFailed
        }
        
        print("ModularPDFExtractor: Extracted \(pdfText.count) characters from PDF")
        
        // Stage 1: Get all patterns from the repository
        let patterns = await patternRepository.getAllPatterns()
        print("ModularPDFExtractor: Loaded \(patterns.count) patterns")
        
        // Stage 2: Process patterns against the PDF text
        // Create a dictionary to store the extracted values
        var data: [String: String] = [:]
        
        // Group patterns by category
        let patternsByCategory = Dictionary(
            grouping: patterns,
            by: { $0.category }
        )
        
        print("ModularPDFExtractor: Processing patterns by category")
        // Process each category of patterns
        for (category, patternsInCategory) in patternsByCategory {
            print("ModularPDFExtractor: Processing category: \(category.rawValue)")
            
            // Sort patterns by priority
            let sortedPatterns = patternsInCategory.sorted(by: { 
                getPatternPriority($0) > getPatternPriority($1)
            })
            
            // Try each pattern until a value is found
            for pattern in sortedPatterns {
                let key = pattern.key
                
                if let value = findValue(for: pattern, in: pdfText) {
                    print("ModularPDFExtractor: Found value for \(key): \(value)")
                    data[key] = value
                    break
                }
            }
        }
        
        // Stage 3: Create a PayslipItem from the extracted data
        print("ModularPDFExtractor: Creating PayslipItem from extracted data")
        
        // Extract required fields with default values
        let month = data["month"] ?? ""
        let yearString = data["year"] ?? ""
        let name = data["name"] ?? ""
        let accountNumber = data["account_number"] ?? ""
        let panNumber = data["pan_number"] ?? ""
        
        // Convert year to integer if needed
        let year = Int(yearString) ?? Calendar.current.component(.year, from: Date())
        
        // Extract and convert numeric values
        let credits = extractDouble(from: data["credits"] ?? "0")
        let debits = extractDouble(from: data["debits"] ?? "0")
        let tax = extractDouble(from: data["tax"] ?? "0")
        let dsop = extractDouble(from: data["dsop"] ?? "0")
        
        // Validate essential data
        if month.isEmpty || yearString.isEmpty || credits == 0 {
            print("ModularPDFExtractor: Insufficient data extracted")
            throw ModularExtractionError.insufficientData
        }
        
        // Extract earnings and deductions if available
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Add entries with "earning_" or "deduction_" prefix
        for (key, value) in data {
            if key.starts(with: "earning_") {
                let amount = extractDouble(from: value)
                let earningName = String(key.dropFirst("earning_".count))
                earnings[earningName] = amount
            } else if key.starts(with: "deduction_") {
                let amount = extractDouble(from: value)
                let deductionName = String(key.dropFirst("deduction_".count))
                deductions[deductionName] = amount
            }
        }
        
        // If no detailed earnings, add a total
        if earnings.isEmpty && credits > 0 {
            earnings["Total Earnings"] = credits
        }
        
        // If no detailed deductions, add defaults
        if deductions.isEmpty && (debits > 0 || tax > 0 || dsop > 0) {
            if tax > 0 {
                deductions["Tax"] = tax
            }
            if dsop > 0 {
                deductions["DSOP"] = dsop
            }
            if debits > 0 && debits > (tax + dsop) {
                deductions["Other Deductions"] = debits - (tax + dsop)
            }
        }
        
        // Create the payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: pdfData
        )
        
        // Set earnings and deductions
        payslip.earnings = earnings
        payslip.deductions = deductions
        
        print("ModularPDFExtractor: Successfully created PayslipItem")
        return payslip
    }
    
    /// Helper method to get pattern priority
    private func getPatternPriority(_ pattern: PatternDefinition) -> Int {
        // Return the priority of the first pattern, or a default value
        return pattern.patterns.first?.priority ?? 0
    }
    
    /// Extract text from a PDF document
    private func extractTextFromPDF(_ pdfDocument: PDFDocument) -> String? {
        var allText = ""
        
        // Iterate through all pages
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i),
               let pageText = page.string {
                allText += pageText + "\n"
            }
        }
        
        return allText.isEmpty ? nil : allText
    }
    
    /// Find a value using a pattern definition
    private func findValue(for patternDef: PatternDefinition, in text: String) -> String? {
        // Try each pattern in the definition until a match is found
        for pattern in patternDef.patterns {
            if let value = applyPattern(pattern, to: text) {
                return value
            }
        }
        return nil
    }
    
    /// Apply a pattern to extract a value from text
    private func applyPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Preprocess text
        var processedText = text
        for step in pattern.preprocessing {
            processedText = applyPreprocessing(step, to: processedText)
        }
        
        // Apply the pattern based on type
        var result: String? = nil
        
        switch pattern.type {
        case .regex:
            result = applyRegexPattern(pattern, to: processedText)
        case .keyword:
            result = applyKeywordPattern(pattern, to: processedText)
        case .positionBased:
            result = applyPositionBasedPattern(pattern, to: processedText)
        }
        
        // Postprocess the result
        if let extractedValue = result {
            var processedValue = extractedValue
            for step in pattern.postprocessing {
                processedValue = applyPostprocessing(step, to: processedValue)
            }
            return processedValue
        }
        
        return result
    }
    
    /// Apply a regex pattern to extract a value
    private func applyRegexPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        let regexPattern = pattern.pattern
        
        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            // Get the first match with at least one capture group
            if let match = matches.first, match.numberOfRanges > 1 {
                let range = match.range(at: 1) // First capture group
                if range.location != NSNotFound {
                    return nsString.substring(with: range)
                } else if match.numberOfRanges > 0 {
                    // If no capture group, return the entire match
                    return nsString.substring(with: match.range)
                }
            }
        } catch {
            print("ModularPDFExtractor: Regex error - \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Apply a keyword pattern to extract a value
    private func applyKeywordPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Parse the pattern to extract keyword and context
        let components = pattern.pattern.split(separator: "|").map(String.init)
        guard components.count > 0 else { return nil }
        
        let keyword = components.count > 1 ? components[1] : components[0]
        let contextBefore = components.count > 2 ? components[0] : nil
        let contextAfter = components.count > 2 ? components[2] : nil
        
        // Split text into lines
        let lines = text.components(separatedBy: .newlines)
        
        // Find lines containing the keyword
        for line in lines {
            if line.contains(keyword) {
                // Check context if needed
                if let beforeCtx = contextBefore, !line.contains(beforeCtx) {
                    continue
                }
                if let afterCtx = contextAfter, !line.contains(afterCtx) {
                    continue
                }
                
                // Extract the value after the keyword
                if let range = line.range(of: keyword), range.upperBound < line.endIndex {
                    let afterText = String(line[range.upperBound...])
                    return afterText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
            }
        }
        
        return nil
    }
    
    /// Apply a position-based pattern to extract a value
    private func applyPositionBasedPattern(_ pattern: ExtractorPattern, to text: String) -> String? {
        // Parse the position info from the pattern
        let posInfoComponents = pattern.pattern.split(separator: ",").map(String.init)
        
        var lineOffset = 0
        var startPos: Int? = nil
        var endPos: Int? = nil
        
        for component in posInfoComponents {
            if component.starts(with: "lineOffset:") {
                lineOffset = Int(component.dropFirst("lineOffset:".count)) ?? 0
            } else if component.starts(with: "start:") {
                startPos = Int(component.dropFirst("start:".count))
            } else if component.starts(with: "end:") {
                endPos = Int(component.dropFirst("end:".count))
            }
        }
        
        // Split text into lines
        let lines = text.components(separatedBy: .newlines)
        
        // Find the relevant line based on offset
        for (i, _) in lines.enumerated() {
            if i + lineOffset < lines.count && i + lineOffset >= 0 {
                let targetLine = lines[i + lineOffset]
                
                // Extract substring if positions are provided
                if let start = startPos, let end = endPos, 
                   start < targetLine.count, end <= targetLine.count, start <= end {
                    let startIndex = targetLine.index(targetLine.startIndex, offsetBy: start)
                    let endIndex = targetLine.index(targetLine.startIndex, offsetBy: end)
                    return String(targetLine[startIndex..<endIndex])
                } else {
                    return targetLine.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
            }
        }
        
        return nil
    }
    
    /// Preprocess text before pattern matching
    private func applyPreprocessing(_ step: ExtractorPattern.PreprocessingStep, to text: String) -> String {
        switch step {
        case .normalizeNewlines:
            return text.replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
        case .normalizeCase:
            return text.lowercased()
        case .removeWhitespace:
            return text.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        case .normalizeSpaces:
            return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        case .trimLines:
            return text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .joined(separator: "\n")
        }
    }
    
    /// Postprocess extracted value
    private func applyPostprocessing(_ step: ExtractorPattern.PostprocessingStep, to value: String) -> String {
        switch step {
        case .trim:
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .formatAsCurrency:
            if let amount = Double(value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                return formatter.string(from: NSNumber(value: amount)) ?? value
            }
            return value
        case .removeNonNumeric:
            return value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        case .uppercase:
            return value.uppercased()
        case .lowercase:
            return value.lowercased()
        }
    }
    
    /// Extract a Double value from a string
    private func extractDouble(from string: String) -> Double {
        // Remove currency symbols, commas, spaces
        let cleaned = string.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleaned) ?? 0.0
    }
    
    /// Log details about the PDF document
    private func logPdfDetails(_ pdfDocument: PDFDocument) {
        let pdfData = pdfDocument.dataRepresentation()
        print("ModularPDFExtractor: PDF data size: \(pdfData?.count ?? 0) bytes")
        print("ModularPDFExtractor: PDF has \(pdfDocument.pageCount) pages")
        
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                let pageRect = page.bounds(for: .mediaBox)
                print("ModularPDFExtractor: Page \(i+1) size: \(pageRect.size.width) x \(pageRect.size.height)")
                
                if let text = page.string, !text.isEmpty {
                    print("ModularPDFExtractor: Page \(i+1) has \(text.count) characters of text")
                } else {
                    print("ModularPDFExtractor: Page \(i+1) has no text content")
                }
            }
        }
    }
}

/// Custom error types for PDF extraction
enum ModularExtractionError: Error {
    case invalidPdf
    case pdfTextExtractionFailed
    case patternMatchingFailed
    case insufficientData
}