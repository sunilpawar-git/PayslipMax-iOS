//
//  BuildConfiguration.swift
//  PayslipMax
//
//  Created for Phase 2: Development Infrastructure
//  Centralizes build-time configuration for Debug vs Release environments
//

import Foundation

/// Centralized configuration based on build environment (Debug vs Release)
enum BuildConfiguration {

    #if DEBUG
    /// Whether the app is running in Debug mode
    static let isDebug = true

    /// Whether LLM features should be enabled by default
    /// In Debug: Enabled for easier testing
    static let llmEnabledByDefault = true

    /// Whether rate limiting should be enforced
    /// In Debug: Disabled to allow unrestricted testing
    static let rateLimitEnabled = false

    /// Maximum LLM calls allowed per year
    /// In Debug: Effectively unlimited
    static let maxCallsPerYear = 999999

    /// Default logging level
    static let logLevel: LogLevel = .verbose

    /// Whether to use backend proxy for LLM calls
    /// In Debug: False (use direct API for faster iteration)
    static let useBackendProxy = false

    #else
    /// Whether the app is running in Debug mode
    static let isDebug = false

    /// Whether LLM features should be enabled by default
    /// In Release: Disabled (requires user opt-in)
    static let llmEnabledByDefault = false

    /// Whether rate limiting should be enforced
    /// In Release: Enabled to control costs
    static let rateLimitEnabled = true

    /// Maximum LLM calls allowed per year
    /// In Release: Strict limit
    static let maxCallsPerYear = 50

    /// Default logging level
    static let logLevel: LogLevel = .info

    /// Whether to use backend proxy for LLM calls
    /// In Release: True (secure proxy required)
    static let useBackendProxy = true  // Backend proxy for production
    #endif

    /// Logging levels for the application
    enum LogLevel {
        case verbose
        case info
        case warning
        case error
    }
}
