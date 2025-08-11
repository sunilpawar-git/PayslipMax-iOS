import Foundation

extension ParserTelemetry {
    /// Create anonymized aggregate suitable for diagnostics export.
    static func toAggregate(_ telemetry: [ParserTelemetry]) -> ParseTelemetryAggregate {
        guard !telemetry.isEmpty else {
            return ParseTelemetryAggregate(
                attempts: 0,
                successRate: 0,
                averageProcessingTimeSec: 0,
                fastestParserName: nil,
                fastestParserTimeSec: nil,
                mostReliableParserName: nil,
                mostReliableParserSuccessRate: nil
            )
        }

        let attempts = telemetry.count
        let successCount = telemetry.filter { $0.success }.count
        let successRate = Double(successCount) / Double(attempts)
        let average = telemetry.map { $0.processingTime }.reduce(0, +) / Double(attempts)

        let fastest = telemetry.min(by: { $0.processingTime < $1.processingTime })

        let grouped = Dictionary(grouping: telemetry, by: { $0.parserName })
        let reliability: (String, Double)? = grouped.map { (name, arr) in
            let sr = Double(arr.filter { $0.success }.count) / Double(arr.count)
            return (name, sr)
        }.max(by: { $0.1 < $1.1 })

        return ParseTelemetryAggregate(
            attempts: attempts,
            successRate: successRate,
            averageProcessingTimeSec: average,
            fastestParserName: fastest?.parserName,
            fastestParserTimeSec: fastest?.processingTime,
            mostReliableParserName: reliability?.0,
            mostReliableParserSuccessRate: reliability?.1
        )
    }
}


