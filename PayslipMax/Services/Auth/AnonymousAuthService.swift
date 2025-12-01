//
//  AnonymousAuthService.swift
//  PayslipMax
//
//  Created for Phase 3.3: Firebase Anonymous Authentication
//  Handles anonymous authentication for Firebase Cloud Functions
//

import Foundation
import FirebaseAuth
import OSLog

/// Handles anonymous authentication for Firebase
final class AnonymousAuthService {
    private let logger = os.Logger(subsystem: "com.payslipmax.auth", category: "Anonymous")

    /// Ensures user is authenticated anonymously
    /// - Returns: True if authenticated successfully
    func ensureAuthenticated() async throws -> Bool {
        // Check if already authenticated
        if Auth.auth().currentUser != nil {
            logger.info("✅ User already authenticated: \(Auth.auth().currentUser?.uid ?? "unknown")")
            return true
        }

        // Sign in anonymously
        logger.info("🔐 Signing in anonymously...")
        do {
            let result = try await Auth.auth().signInAnonymously()
            logger.info("✅ Anonymous sign-in successful. UID: \(result.user.uid)")
            return true
        } catch {
            logger.error("❌ Anonymous sign-in failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Sign out current user
    func signOut() throws {
        try Auth.auth().signOut()
        logger.info("🚪 User signed out")
    }

    /// Get current user ID
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    /// Check if user is authenticated
    var isAuthenticated: Bool {
        Auth.auth().currentUser != nil
    }
}
