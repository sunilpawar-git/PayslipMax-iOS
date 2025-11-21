//
//  OpenAILLMService.swift
//  PayslipMax
//
//  Implementation of LLMServiceProtocol for OpenAI
//

import Foundation
import OSLog

/// Service for interacting with OpenAI API
final class OpenAILLMService: LLMServiceProtocol {

    // MARK: - Properties

    let provider: LLMProvider = .openai
    private let configuration: LLMConfiguration
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "OpenAI")
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

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prepare messages
        var messages: [OpenAIMessage] = []
        if let systemPrompt = request.systemPrompt {
            messages.append(OpenAIMessage(role: "system", content: systemPrompt))
        }
        messages.append(OpenAIMessage(role: "user", content: request.prompt))

        // Prepare body
        let body = OpenAIRequestBody(
            model: configuration.model,
            messages: messages,
            temperature: configuration.temperature,
            max_tokens: configuration.maxTokens,
            response_format: request.jsonMode ? OpenAIResponseFormat(type: "json_object") : nil
        )

        do {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw LLMError.invalidConfiguration // Should not happen
        }

        logger.info("Sending request to OpenAI (model: \(self.configuration.model))")

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMError.networkError(URLError(.badServerResponse))
            }

            guard httpResponse.statusCode == 200 else {
                logger.error("OpenAI API Error: \(httpResponse.statusCode)")

                // Try to parse error message
                if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    throw LLMError.apiError(code: httpResponse.statusCode, message: errorResponse.error.message)
                }

                throw LLMError.apiError(code: httpResponse.statusCode, message: "Unknown error")
            }

            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

            guard let choice = openAIResponse.choices.first else {
                throw LLMError.emptyResponse
            }

            let usage = LLMUsage(
                promptTokens: openAIResponse.usage?.prompt_tokens ?? 0,
                completionTokens: openAIResponse.usage?.completion_tokens ?? 0,
                totalTokens: openAIResponse.usage?.total_tokens ?? 0
            )

            logger.info("Received response from OpenAI (tokens: \(usage.totalTokens))")

            return LLMResponse(content: choice.message.content, usage: usage)

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

private struct OpenAIRequestBody: Encodable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let max_tokens: Int
    let response_format: OpenAIResponseFormat?
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

private struct OpenAIResponseFormat: Encodable {
    let type: String
}

private struct OpenAIResponse: Decodable {
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

private struct OpenAIChoice: Decodable {
    let message: OpenAIMessage
}

private struct OpenAIUsage: Decodable {
    let prompt_tokens: Int
    let completion_tokens: Int
    let total_tokens: Int
}

private struct OpenAIErrorResponse: Decodable {
    let error: OpenAIErrorDetail
}

private struct OpenAIErrorDetail: Decodable {
    let message: String
    let type: String
    let code: String?
}
