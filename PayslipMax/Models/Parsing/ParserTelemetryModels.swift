import Foundation
import PDFKit
import Darwin  // For memory tracking

// MARK: - Telemetry Models

/// Collects telemetry data for parser performance
struct ParserTelemetry: Codable {
    /// Name of the parser being measured.
    let parserName: String
    /// Time taken for the parsing process.
    let processingTime: TimeInterval
    /// Confidence level achieved by the parser.
    let confidence: ParsingConfidence
    /// Indicates if the parsing was successful.
    let success: Bool
    /// Timestamp when the telemetry was recorded.
    let timestamp: Date
    /// Memory usage recorded during parsing (resident set size).
    let memoryUsage: Int64? // In bytes

    // Additional parser-specific metrics
    /// Number of key items successfully extracted.
    let extractedItemCount: Int
    /// Length of the text processed by the parser.
    let textLength: Int
    /// Error message, if parsing failed.
    let errorMessage: String?

    /// Initializes parser telemetry data.
    /// - Parameters:
    ///   - parserName: Name of the parser.
    ///   - processingTime: Time taken for parsing.
    ///   - confidence: Confidence level achieved.
    ///   - success: Whether parsing was successful.
    ///   - extractedItemCount: Number of items extracted.
    ///   - textLength: Length of the text processed.
    ///   - errorMessage: Error message if parsing failed.
    init(
        parserName: String,
        processingTime: TimeInterval,
        confidence: ParsingConfidence = .low,
        success: Bool,
        extractedItemCount: Int = 0,
        textLength: Int = 0,
        errorMessage: String? = nil
    ) {
        self.parserName = parserName
        self.processingTime = processingTime
        self.confidence = confidence
        self.success = success
        self.timestamp = Date()
        self.extractedItemCount = extractedItemCount
        self.textLength = textLength
        self.errorMessage = errorMessage

        // Get memory usage if available
        self.memoryUsage = ParserTelemetry.getMemoryUsage()
    }

    /// Retrieves the current memory usage (resident set size) of the task.
    /// - Returns: Memory usage in bytes, or nil if it cannot be determined.
    private static func getMemoryUsage() -> Int64? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : nil
    }

    /// Logs the collected telemetry data to the console.
    func logTelemetry() {
        print("[Telemetry] Parser: \(parserName)")
        print("[Telemetry] Time: \(String(format: "%.3f", processingTime))s")
        print("[Telemetry] Success: \(success)")
        if success {
            print("[Telemetry] Confidence: \(confidence)")
        }
        print("[Telemetry] Items extracted: \(extractedItemCount)")
        print("[Telemetry] Text length: \(textLength)")
        if let memory = memoryUsage {
            print("[Telemetry] Memory usage: \(ByteCountFormatter.string(fromByteCount: memory, countStyle: .memory))")
        }
        if let error = errorMessage {
            print("[Telemetry] Error: \(error)")
        }
    }

    /// Aggregates and logs telemetry data from multiple parsing attempts.
    /// Calculates and prints overall success rate, average processing time, fastest parser, and most reliable parser.
    /// - Parameter telemetryData: An array of `ParserTelemetry` objects to aggregate.
    static func aggregateAndLogTelemetry(telemetryData: [ParserTelemetry]) {
        print("[Telemetry] ===== AGGREGATE PARSER PERFORMANCE =====")

        // Overall success rate
        let successCount = telemetryData.filter { $0.success }.count
        let totalCount = telemetryData.count
        let successRate = Double(successCount) / Double(totalCount)
        print("[Telemetry] Success rate: \(String(format: "%.1f", successRate * 100))% (\(successCount)/\(totalCount))")

        // Average processing time
        let avgTime = telemetryData.map { $0.processingTime }.reduce(0, +) / Double(totalCount)
        print("[Telemetry] Average processing time: \(String(format: "%.3f", avgTime))s")

        // Fastest parser
        if let fastest = telemetryData.min(by: { $0.processingTime < $1.processingTime }) {
            print("[Telemetry] Fastest parser: \(fastest.parserName) (\(String(format: "%.3f", fastest.processingTime))s)")
        }

        // Most reliable parser
        let parserSuccessRates = Dictionary(grouping: telemetryData, by: { $0.parserName })
            .mapValues { parsers in
                let successes = parsers.filter { $0.success }.count
                return Double(successes) / Double(parsers.count)
            }

        if let mostReliable = parserSuccessRates.max(by: { $0.value < $1.value }) {
            print("[Telemetry] Most reliable parser: \(mostReliable.key) (\(String(format: "%.1f", mostReliable.value * 100))%)")
        }

        print("[Telemetry] =======================================")
    }
}
