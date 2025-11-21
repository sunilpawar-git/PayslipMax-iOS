//
//  GeminiLLMService.swift
//  PayslipMax
//
//  Implementation of LLMServiceProtocol for Google Gemini
//

import Foundation
import OSLog

/// Service for interacting with Google Gemini API
final class GeminiLLMService: LLMServiceProtocol {

    // MARK: - Properties

    let provider: LLMProvider = .gemini
    private let configuration: LLMConfiguration
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "Gemini")
    private let session: URLSession

    // MARK: - Initialization

    init(configuration: LLMConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    // MARK: - LLMServiceProtocol

    func validateConfiguration() -> Bool {
        return !configuration.apiKey.isEmpty
    }

    func send(_ request: LLMRequest) async throws -> LLMResponse {
        guard validateConfiguration() else {
            throw LLMError.invalidAPIKey
        }

        // Construct URL
        let model = configuration.model // e.g., "gemini-1.5-flash"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(configuration.apiKey)"
        guard let url = URL(string: urlString) else {
            throw LLMError.invalidConfiguration
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prepare content
        var parts: [GeminiPart] = []

        // Gemini handles system prompts differently (often just prepended or via system_instruction in beta)
        // For simplicity and compatibility, we'll prepend system prompt if present
        if let systemPrompt = request.systemPrompt {
            parts.append(GeminiPart(text: "System Instruction: \(systemPrompt)\n\n"))
        }
        parts.append(GeminiPart(text: request.prompt))

        let content = GeminiContent(role: "user", parts: parts)

        // Prepare body
        let body = GeminiRequestBody(
            contents: [content],
            generationConfig: GeminiGenerationConfig(
                response_mime_type: request.jsonMode ? "application/json" : "text/plain",
                temperature: configuration.temperature,
                maxOutputTokens: configuration.maxTokens
            )
        )

        do {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw LLMError.invalidConfiguration
        }

        logger.info("Sending request to Gemini (model: \(model))")

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.networkError(URLError(.badServerResponse))
            }

            guard httpResponse.statusCode == 200 else {
                logger.error("Gemini API Error: \(httpResponse.statusCode)")
                if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                    throw LLMError.apiError(code: httpResponse.statusCode, message: errorResponse.error.message)
                }
                throw LLMError.apiError(code: httpResponse.statusCode, message: "Unknown error")
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

            guard let candidate = geminiResponse.candidates?.first,
                  let text = candidate.content.parts.first?.text else {
                throw LLMError.emptyResponse
            }

            let usage = LLMUsage(
                promptTokens: geminiResponse.usageMetadata?.promptTokenCount ?? 0,
                completionTokens: geminiResponse.usageMetadata?.candidatesTokenCount ?? 0,
                totalTokens: geminiResponse.usageMetadata?.totalTokenCount ?? 0
            )

            logger.info("Received response from Gemini (tokens: \(usage.totalTokens))")

            return LLMResponse(content: text, usage: usage)

        } catch let error as LLMError {
            throw error
        } catch {
            logger.error("Network/Decoding error: \(error.localizedDescription)")
            if error is DecodingError {
                throw LLMError.decodingError(error)
            }
            throw LLMError.networkError(error)
        }
    }
}

// MARK: - Internal Models

private struct GeminiRequestBody: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
}

private struct GeminiContent: Encodable {
    let role: String
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiGenerationConfig: Encodable {
    let response_mime_type: String
    let temperature: Double
    let maxOutputTokens: Int
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
    let usageMetadata: GeminiUsageMetadata?
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContentResponse
}

private struct GeminiContentResponse: Decodable {
    let parts: [GeminiPart]
}

private struct GeminiUsageMetadata: Decodable {
    let promptTokenCount: Int
    let candidatesTokenCount: Int
    let totalTokenCount: Int
}

private struct GeminiErrorResponse: Decodable {
    let error: GeminiErrorDetail
}

private struct GeminiErrorDetail: Decodable {
    let code: Int
    let message: String
    let status: String
}
