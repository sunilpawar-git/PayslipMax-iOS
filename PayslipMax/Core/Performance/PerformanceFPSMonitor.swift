//
//  PerformanceFPSMonitor.swift
//  PayslipMax
//
//  Created on 2025-01-09
//  Handles FPS monitoring and calculation
//

import Foundation
import QuartzCore
import Combine

/// Monitors and calculates frames per second performance metrics
final class PerformanceFPSMonitor: FPSMonitorProtocol {
    // MARK: - Published Properties

    /// Current frames per second
    @Published private(set) var currentFPS: Double = 0

    /// Average frames per second
    @Published private(set) var averageFPS: Double = 0

    /// Publisher for FPS updates
    var fpsPublisher: AnyPublisher<Double, Never> {
        $currentFPS.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    /// Frame timing data
    private var frameTimestamps: [TimeInterval] = []

    /// Maximum number of frame timestamps to keep
    private let maxFrameSamples = 60

    /// Display link for frame timing
    private var displayLink: CADisplayLink?

    /// Frame counter for fps calculation
    private var frameCount = 0

    /// Last timestamp for fps calculation
    private var lastTimestamp: CFTimeInterval = 0

    /// Whether monitoring is active
    private var isMonitoring = false

    // MARK: - Initialization

    init() {
        // Initialization handled in startMonitoring
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public API

    /// Starts FPS monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }

        setupDisplayLink()
        isMonitoring = true
    }

    /// Stops FPS monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }

        displayLink?.invalidate()
        displayLink = nil
        isMonitoring = false
    }

    /// Resets FPS metrics
    func resetMetrics() {
        frameTimestamps.removeAll()
        currentFPS = 0
        averageFPS = 0
        frameCount = 0
        lastTimestamp = 0
    }

    // MARK: - Private Methods

    /// Sets up display link for frame timing
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink?.add(to: .current, forMode: .common)
    }

    /// Handles display link firing
    @objc private func displayLinkFired() {
        let timestamp = CACurrentMediaTime()
        frameTimestamps.append(timestamp)

        // Keep only recent frames
        if frameTimestamps.count > maxFrameSamples {
            frameTimestamps.removeFirst(frameTimestamps.count - maxFrameSamples)
        }

        // Calculate FPS
        calculateFPS()
    }

    /// Calculates frames per second
    private func calculateFPS() {
        guard frameTimestamps.count >= 2 else { return }

        let count = Double(frameTimestamps.count)
        let timeInterval = frameTimestamps.last! - frameTimestamps.first!

        if timeInterval > 0 {
            currentFPS = (count - 1) / timeInterval

            // Update average FPS with slight weight toward recent values
            if averageFPS == 0 {
                averageFPS = currentFPS
            } else {
                averageFPS = averageFPS * 0.95 + currentFPS * 0.05
            }
        }
    }
}
