import Foundation
import SwiftUI
import Combine

/// Coordinates all notification handling for HomeViewModel
/// Follows single responsibility principle by handling only payslip lifecycle notifications
@MainActor
class NotificationCoordinator: ObservableObject {
    // MARK: - Private Properties

    /// Completion handlers for notification events
    private var onPayslipDeleted: ((UUID) -> Void)?
    private var onPayslipUpdated: (() -> Void)?
    private var onPayslipsRefresh: (() -> Void)?
    private var onPayslipsForcedRefresh: (() -> Void)?

    // MARK: - Initialization

    init() {
        setupNotificationHandlers()
    }

    deinit {
        // Clean up notification observers
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// Sets completion handlers for notification events
    func setCompletionHandlers(
        onPayslipDeleted: @escaping (UUID) -> Void,
        onPayslipUpdated: @escaping () -> Void,
        onPayslipsRefresh: @escaping () -> Void,
        onPayslipsForcedRefresh: @escaping () -> Void
    ) {
        self.onPayslipDeleted = onPayslipDeleted
        self.onPayslipUpdated = onPayslipUpdated
        self.onPayslipsRefresh = onPayslipsRefresh
        self.onPayslipsForcedRefresh = onPayslipsForcedRefresh
    }

    // MARK: - Private Methods

    /// Sets up notification handlers for payslip events
    private func setupNotificationHandlers() {
        // Listen for payslip deleted events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipDeleted(_:)),
            name: .payslipDeleted,
            object: nil
        )

        // Listen for payslip updated events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipUpdated(_:)),
            name: .payslipUpdated,
            object: nil
        )

        // Listen for general refresh events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipsRefresh),
            name: .payslipsRefresh,
            object: nil
        )

        // Listen for forced refresh events (more aggressive refresh)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipsForcedRefresh),
            name: .payslipsForcedRefresh,
            object: nil
        )
    }

    /// Handles payslip deleted notification
    @objc private func handlePayslipDeleted(_ notification: Notification) {
        guard let payslipId = notification.userInfo?["payslipId"] as? UUID else { return }

        // Only log in non-test environments to reduce test verbosity
        if !ProcessInfo.isRunningInTestEnvironment {
            print("NotificationCoordinator: Handling payslip deleted notification for ID: \(payslipId)")
        }
        onPayslipDeleted?(payslipId)
    }

    /// Handles payslip updated notification
    @objc private func handlePayslipUpdated(_ notification: Notification) {
        if !ProcessInfo.isRunningInTestEnvironment {
            print("NotificationCoordinator: Handling payslip updated notification")
        }
        onPayslipUpdated?()
    }

    /// Handles general refresh notification
    @objc private func handlePayslipsRefresh() {
        if !ProcessInfo.isRunningInTestEnvironment {
            print("NotificationCoordinator: Handling payslips refresh notification")
        }
        onPayslipsRefresh?()
    }

    /// Handles forced refresh notification (more aggressive than regular refresh)
    @objc private func handlePayslipsForcedRefresh() {
        if !ProcessInfo.isRunningInTestEnvironment {
            print("NotificationCoordinator: Handling payslips forced refresh notification")
        }
        onPayslipsForcedRefresh?()
    }
}
