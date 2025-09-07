//
//  PerformanceReporter.swift
//  PayslipMax
//
//  Created on 2025-01-09
//  Handles performance reporting and metrics formatting
//

import Foundation

/// Generates performance reports and manages view tracking metrics
final class PerformanceReporter: PerformanceReporterProtocol {
    // MARK: - Private Properties

    /// Time to first render metrics
    private var timeToFirstRender: [String: TimeInterval] = [:]

    /// View redraw counts
    private var viewRedrawCounts: [String: Int] = [:]

    // MARK: - Initialization

    init() {
        // Default initialization
    }

    // MARK: - Public API

    /// Generates detailed performance report
    func generatePerformanceReport() -> String {
        var report = "Performance Report\n"
        report += "=================\n\n"

        // This method would need access to current metrics from monitors
        // In the coordinator pattern, this will be handled by the coordinator
        report += "Note: This is a placeholder for detailed reporting.\n"
        report += "Use the coordinator for comprehensive reports.\n"

        return report
    }

    /// Gets concise performance report
    func getConcisePerformanceReport() -> String {
        var report = "Performance Report\n"
        report += "================\n"

        if !timeToFirstRender.isEmpty {
            report += "\nTime to First Render:\n"
            for (view, time) in timeToFirstRender.sorted(by: { $0.key < $1.key }) {
                report += "- \(view): \(String(format: "%.2f", time * 1000)) ms\n"
            }
        }

        if !viewRedrawCounts.isEmpty {
            report += "\nView Redraw Counts:\n"
            for (view, count) in viewRedrawCounts.sorted(by: { $0.value > $1.value }) {
                report += "- \(view): \(count) redraws\n"
            }
        }

        return report
    }

    /// Formats memory size to human-readable string
    func formatMemory(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    /// Records time to first render for a view
    func recordTimeToFirstRender(for viewName: String, timeInterval: TimeInterval) {
        timeToFirstRender[viewName] = timeInterval
    }

    /// Records view redraw
    func recordViewRedraw(for viewName: String) {
        viewRedrawCounts[viewName, default: 0] += 1
    }

    /// Gets time to first render metrics
    func getTimeToFirstRender() -> [String: TimeInterval] {
        return timeToFirstRender
    }

    /// Gets view redraw counts
    func getViewRedrawCounts() -> [String: Int] {
        return viewRedrawCounts
    }

    /// Resets all reporting metrics
    func resetMetrics() {
        timeToFirstRender.removeAll()
        viewRedrawCounts.removeAll()
    }

    // MARK: - Helper Methods

    /// Generates a detailed report with monitor data
    func generateDetailedReport(
        currentFPS: Double,
        averageFPS: Double,
        currentMemory: UInt64,
        averageMemory: UInt64,
        peakMemory: UInt64,
        currentCPU: Double,
        averageCPU: Double
    ) -> String {
        let currentMemoryFormatted = formatMemory(currentMemory)
        let averageMemoryFormatted = formatMemory(averageMemory)
        let peakMemoryFormatted = formatMemory(peakMemory)

        var report = "Performance Report\n"
        report += "=================\n\n"

        report += "Memory Usage:\n"
        report += "  Current: \(currentMemoryFormatted)\n"
        report += "  Average: \(averageMemoryFormatted)\n"
        report += "  Peak: \(peakMemoryFormatted)\n\n"

        report += "CPU Usage:\n"
        report += "  Current: \(String(format: "%.1f", currentCPU))%\n"
        report += "  Average: \(String(format: "%.1f", averageCPU))%\n\n"

        report += "UI Performance:\n"
        report += "  FPS: \(String(format: "%.1f", currentFPS))\n"
        report += "  Average FPS: \(String(format: "%.1f", averageFPS))\n"

        // Add view tracking data
        if !timeToFirstRender.isEmpty {
            report += "\n\nTime to First Render:\n"
            for (view, time) in timeToFirstRender.sorted(by: { $0.key < $1.key }) {
                report += "  \(view): \(String(format: "%.2f", time * 1000)) ms\n"
            }
        }

        if !viewRedrawCounts.isEmpty {
            report += "\nView Redraw Counts:\n"
            for (view, count) in viewRedrawCounts.sorted(by: { $0.value > $1.value }) {
                report += "  \(view): \(count) redraws\n"
            }
        }

        return report
    }
}
