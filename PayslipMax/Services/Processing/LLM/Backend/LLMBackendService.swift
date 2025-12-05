//
//  LLMBackendService.swift
//  PayslipMax
//
//  Created for Phase 3: Production Security
//  Handles secure communication with Firebase Cloud Functions
//

import Foundation
import FirebaseFunctions
import FirebaseAuth
import OSLog

/// Protocol for backend LLM service
protocol LLMBackendServiceProtocol {
    /// Parses payslip text using secure backend proxy
    /// - Parameter text: The redacted payslip text
    /// - Returns: The raw JSON response string from the LLM
    func parsePayslip(text: String) async throws -> String
}

/// Service to handle communication with Firebase Cloud Functions
final class LLMBackendService: LLMBackendServiceProtocol {

    // MARK: - Properties

    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "Backend")
    private lazy var functions = Functions.functions()

    // MARK: - Initialization

    init() {
        // Use local emulator if configured
        if let emulatorHost = ProcessInfo.processInfo.environment["FIREBASE_EMULATOR_HOST"] {
            functions.useEmulator(withHost: emulatorHost, port: 5001)
            logger.info("🔧 Using Firebase Functions emulator at \(emulatorHost):5001")
        }
    }

    // MARK: - LLMBackendServiceProtocol

    func parsePayslip(text: String) async throws -> String {
        // 1. Ensure user is authenticated
        guard Auth.auth().currentUser != nil else {
            logger.error("❌ User not authenticated")
            throw LLMError.authenticationRequired
        }

        logger.info("🚀 Calling Cloud Function: parseLLM")

        do {
            // 2. Call Cloud Function
            let callable = functions.httpsCallable("parseLLM")
            let result = try await callable.call(["prompt": text])

            // 3. Parse response
            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let resultText = data["result"] as? String else {
                logger.error("❌ Invalid response format from Cloud Function")
                throw LLMError.invalidResponse
            }

            // Log usage if available
            if let tokens = data["tokensUsed"] as? Int {
                logger.info("✅ Cloud Function success. Tokens used: \(tokens)")
            }

            return resultText

        } catch let error as NSError {
            logger.error("❌ Cloud Function error: \(error.localizedDescription)")

            // Map Firebase errors to domain errors
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                switch code {
                case .unauthenticated:
                    throw LLMError.authenticationRequired
                case .resourceExhausted:
                    throw LLMError.rateLimitExceeded
                case .unavailable:
                    throw LLMError.serviceUnavailable
                default:
                    throw LLMError.networkError(error)
                }
            }

            throw error
        }
    }
}
