import Foundation

/// Configuration for Vision LLM optimization to reduce API costs
struct VisionLLMOptimizationConfig: Sendable {

    // MARK: - Properties

    /// JPEG compression quality for image data (0.0 - 1.0)
    /// Lower values reduce input token count but may affect quality
    let imageCompressionQuality: CGFloat

    /// Maximum number of output tokens allowed
    /// Lower values reduce output costs for typical payslip parsing
    let maxOutputTokens: Int

    /// Temperature for LLM generation (0.0 = deterministic)
    let temperature: Double

    // MARK: - Constants

    private enum Constants {
        /// Default compression quality (75%) - higher quality for better table reading
        /// Previously 0.6 but caused value misalignment issues on dense tables
        static let defaultCompressionQuality: CGFloat = 0.75

        /// Default max output tokens for payslip parsing
        /// Set to 8500 based on successful JCO/OR payslip parsing in manual testing
        /// (Maintains original capacity for complex tabulated data)
        static let defaultMaxOutputTokens = 8500

        /// Default temperature for deterministic output
        static let defaultTemperature = 0.0
    }

    // MARK: - Initialization

    /// Creates an optimization config with custom parameters
    /// - Parameters:
    ///   - imageCompressionQuality: JPEG compression quality (0.0-1.0)
    ///   - maxOutputTokens: Maximum output tokens
    ///   - temperature: LLM temperature (0.0 = deterministic)
    init(
        imageCompressionQuality: CGFloat,
        maxOutputTokens: Int,
        temperature: Double
    ) {
        self.imageCompressionQuality = imageCompressionQuality
        self.maxOutputTokens = maxOutputTokens
        self.temperature = temperature
    }

    // MARK: - Default Configuration

    /// Default optimization configuration
    /// - Image compression: 0.75 (higher quality for table parsing)
    /// - Max output tokens: 8500 (supports complex JCO/OR payslips)
    /// - Temperature: 0.0 (deterministic output)
    static let `default` = VisionLLMOptimizationConfig(
        imageCompressionQuality: Constants.defaultCompressionQuality,
        maxOutputTokens: Constants.defaultMaxOutputTokens,
        temperature: Constants.defaultTemperature
    )
}
