//
//  ViewPerformanceExtensions.swift
//  PayslipMax
//
//  Created on 2025-01-09
//  SwiftUI View extensions for performance tracking
//

import SwiftUI

// MARK: - Performance Tracking Extensions

extension View {
    /// Tracks render time for this view
    /// - Parameter name: The name of the view to track
    /// - Returns: A modified view with performance tracking
    func trackRenderTime(name: String) -> some View {
        let startTime = CFAbsoluteTimeGetCurrent()
        return self.onAppear {
            let renderTime = CFAbsoluteTimeGetCurrent() - startTime
            // Note: In the refactored architecture, this would use dependency injection
            // For now, we'll use a simple approach that can be updated later
            PerformanceMetrics.shared.recordTimeToFirstRender(for: name, timeInterval: renderTime)
        }
        .onChange(of: 0) { _, _ in
            // This never triggers, but forces SwiftUI to evaluate the view
        }
    }

    /// Tracks redraws of this view
    /// - Parameter name: The name of the view to track
    /// - Returns: A modified view with redraw tracking
    func trackRedraws(name: String) -> some View {
        return self.modifier(RedrawTracker(viewName: name))
    }
}

/// Tracks view redraws
struct RedrawTracker: ViewModifier {
    let viewName: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Note: In the refactored architecture, this would use dependency injection
                PerformanceMetrics.shared.recordViewRedraw(for: viewName)
            }
            .id(UUID()) // Forces a new identity each time, capturing redraws
    }
}
