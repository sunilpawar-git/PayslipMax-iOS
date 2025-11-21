//
//  MockLLMService.swift
//  PayslipMaxTests
//
//  Mock implementation of LLMServiceProtocol for testing
//

import Foundation
@testable import PayslipMax

class MockLLMService: LLMServiceProtocol {
    var provider: LLMProvider = .mock

    var shouldFail: Bool = false
    var mockResponse: String = ""
    var lastRequest: LLMRequest?

    func send(_ request: LLMRequest) async throws -> LLMResponse {
        lastRequest = request

        if shouldFail {
            throw LLMError.apiError(code: 500, message: "Mock error")
        }

        return LLMResponse(
            content: mockResponse,
            usage: LLMUsage(promptTokens: 10, completionTokens: 10, totalTokens: 20)
        )
    }

    func validateConfiguration() -> Bool {
        return true
    }
}
