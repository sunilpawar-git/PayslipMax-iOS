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
    static let isDebug = true
    static let llmEnabledByDefault = true
    static let rateLimitEnabled = false
    static let maxCallsPerYear = 999999
    static let logLevel: LogLevel = .verbose
    static let useBackendProxy = false
    static let offlineModeDefault = false
    #else
    static let isDebug = false
    static let llmEnabledByDefault = false
    static let rateLimitEnabled = true
    static let maxCallsPerYear = 50
    static let logLevel: LogLevel = .info
    static let useBackendProxy = true
    static let offlineModeDefault = false
    #endif

    /// Logging levels for the application
    enum LogLevel {
        case verbose
        case info
        case warning
        case error
    }
}
