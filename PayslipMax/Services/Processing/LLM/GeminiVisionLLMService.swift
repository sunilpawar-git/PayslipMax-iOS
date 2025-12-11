import Foundation
import OSLog
import UIKit

/// Vision Gemini service (image + text prompt).
final class GeminiVisionLLMService: LLMVisionServiceProtocol {
    let provider: LLMProvider = .gemini
    private let configuration: LLMConfiguration
    private let optimizationConfig: VisionLLMOptimizationConfig
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "GeminiVision")
    private let session: URLSession

    init(
        configuration: LLMConfiguration,
        optimizationConfig: VisionLLMOptimizationConfig = .default,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.optimizationConfig = optimizationConfig
        self.session = session
    }

    func validateConfiguration() -> Bool {
        return !configuration.apiKey.isEmpty
    }

    func send(imageData: Data, mimeType: String, request: LLMRequest) async throws -> LLMResponse {
        guard validateConfiguration() else {
            throw LLMError.invalidAPIKey
        }

        let model = configuration.model // vision-capable model
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(configuration.apiKey)"
        guard let url = URL(string: urlString) else {
            throw LLMError.invalidConfiguration
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build parts: image + prompt
        var parts: [GeminiVisionPart] = []

        // System prompt as leading text
        if let systemPrompt = request.systemPrompt {
            parts.append(GeminiVisionPart(text: "System Instruction: \(systemPrompt)\n\n"))
        }

        // Inline image (apply compression optimization)
        let optimizedImageData = optimizeImageData(imageData)
        let base64 = optimizedImageData.base64EncodedString()
        parts.append(GeminiVisionPart(inline_data: GeminiInlineData(mime_type: mimeType, data: base64)))

        // User prompt
        parts.append(GeminiVisionPart(text: request.prompt))

        let content = GeminiVisionContent(role: "user", parts: parts)

        // Note: Gemini 2.5-flash uses thinking mode which wastes tokens
        // We can't disable it via API, so we need to use a different model
        // or significantly increase maxOutputTokens to accommodate both thinking and output
        let body = GeminiVisionRequestBody(
            contents: [content],
            generationConfig: GeminiVisionGenerationConfig(
                temperature: optimizationConfig.temperature,
                maxOutputTokens: optimizationConfig.maxOutputTokens,
                responseMimeType: nil
            )
        )

        do {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw LLMError.invalidConfiguration
        }

        logger.info("Sending vision request to Gemini (model: \(model))")

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.networkError(URLError(.badServerResponse))
            }

            guard httpResponse.statusCode == 200 else {
                logger.error("Gemini Vision API Error: \(httpResponse.statusCode)")
                if let errorResponse = try? JSONDecoder().decode(GeminiVisionErrorResponse.self, from: data) {
                    throw LLMError.apiError(code: httpResponse.statusCode, message: errorResponse.error.message)
                }
                throw LLMError.apiError(code: httpResponse.statusCode, message: "Unknown error")
            }

            // Debug: Log raw API response
            logger.debug("Raw API response data length: \(data.count) bytes")
            if let rawJSON = String(data: data, encoding: .utf8) {
                logger.debug("Raw API response preview: \(rawJSON.prefix(1000))")
            }

            let geminiResponse = try JSONDecoder().decode(GeminiVisionResponse.self, from: data)

            guard let candidate = geminiResponse.candidates?.first else {
                throw LLMError.emptyResponse
            }

            // Concatenate all text parts (Gemini may split response across multiple parts)
            let textParts = candidate.content.parts.compactMap { $0.text }
            guard !textParts.isEmpty else {
                throw LLMError.emptyResponse
            }
            let fullText = textParts.joined()

            logger.debug("Vision response parts count: \(candidate.content.parts.count)")
            logger.debug("Text parts count: \(textParts.count)")
            logger.debug("Finish reason: \(candidate.finishReason ?? "unknown")")
            logger.debug("Full text length: \(fullText.count) chars")

            let usage = LLMUsage(
                promptTokens: geminiResponse.usageMetadata?.promptTokenCount ?? 0,
                completionTokens: geminiResponse.usageMetadata?.candidatesTokenCount ?? 0,
                totalTokens: geminiResponse.usageMetadata?.totalTokenCount ?? 0
            )

            logger.info("Received vision response from Gemini (tokens: \(usage.totalTokens))")

            return LLMResponse(content: fullText, usage: usage)

        } catch let error as LLMError {
            throw error
        } catch {
            logger.error("Network/Decoding error (vision): \(error.localizedDescription)")
            if error is DecodingError {
                throw LLMError.decodingError(error)
            }
            throw LLMError.networkError(error)
        }
    }

    // MARK: - Private Helpers

    /// Optimizes image data by applying JPEG compression
    /// - Parameter imageData: Original image data
    /// - Returns: Optimized (compressed) image data
    private func optimizeImageData(_ imageData: Data) -> Data {
        guard let image = UIImage(data: imageData) else {
            logger.warning("Could not create UIImage from data, using original")
            return imageData
        }

        guard let compressedData = image.jpegData(compressionQuality: optimizationConfig.imageCompressionQuality) else {
            logger.warning("Could not compress image, using original")
            return imageData
        }

        let originalSize = imageData.count
        let compressedSize = compressedData.count
        let savings = Double(originalSize - compressedSize) / Double(originalSize) * 100.0

        logger.info("Image compressed: \(originalSize) → \(compressedSize) bytes (\(String(format: "%.1f", savings))% reduction)")

        return compressedData
    }
}

// MARK: - Vision models
private struct GeminiVisionRequestBody: Encodable {
    let contents: [GeminiVisionContent]
    let generationConfig: GeminiVisionGenerationConfig?
}

private struct GeminiVisionContent: Encodable {
    let role: String
    let parts: [GeminiVisionPart]
}

private struct GeminiVisionPart: Codable {
    let text: String?
    let inline_data: GeminiInlineData?

    init(text: String) {
        self.text = text
        self.inline_data = nil
    }

    init(inline_data: GeminiInlineData) {
        self.text = nil
        self.inline_data = inline_data
    }
}

private struct GeminiInlineData: Codable {
    let mime_type: String
    let data: String
}

private struct GeminiVisionGenerationConfig: Encodable {
    let temperature: Double
    let maxOutputTokens: Int
    let responseMimeType: String?
}

private struct GeminiVisionResponse: Decodable {
    let candidates: [GeminiVisionCandidate]?
    let usageMetadata: GeminiVisionUsageMetadata?
}

private struct GeminiVisionCandidate: Decodable {
    let content: GeminiVisionContentResponse
    let finishReason: String?
}

private struct GeminiVisionContentResponse: Decodable {
    let parts: [GeminiVisionPart]
}

private struct GeminiVisionUsageMetadata: Decodable {
    let promptTokenCount: Int
    let candidatesTokenCount: Int
    let totalTokenCount: Int
}

private struct GeminiVisionErrorResponse: Decodable {
    let error: GeminiVisionErrorDetail
}

private struct GeminiVisionErrorDetail: Decodable {
    let code: Int
    let message: String
    let status: String
}
