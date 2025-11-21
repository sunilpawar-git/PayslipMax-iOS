//
//  LLMServiceProtocol.swift
//  PayslipMax
//
//  Protocol for LLM service implementations
//

import Foundation

/// Protocol defining the contract for LLM services
public protocol LLMServiceProtocol {
    /// The provider type of this service
    var provider: LLMProvider { get }

    /// Sends a request to the LLM and returns the response
    /// - Parameter request: The request containing prompt and options
    /// - Returns: The response from the LLM
    /// - Throws: LLMError if the request fails
    func send(_ request: LLMRequest) async throws -> LLMResponse

    /// Validates the configuration (e.g., check if API key is present)
    /// - Returns: True if valid
    func validateConfiguration() -> Bool
}
