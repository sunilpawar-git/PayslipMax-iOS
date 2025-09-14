import Foundation
import Combine

/// Setup and binding logic for HomeViewModel
/// Contains coordinator initialization and property binding setup
extension HomeViewModel {

    // MARK: - Coordinator Setup

    /// Sets up completion handlers between coordinators
    func setupCoordinatorHandlers() {
        setupPDFCoordinatorHandlers()
        setupManualEntryCoordinatorHandlers()
        setupDataCoordinatorHandlers()
        setupNotificationCoordinatorHandlers()
    }

    private func setupPDFCoordinatorHandlers() {
        pdfCoordinator.setCompletionHandlers(
            onSuccess: { [weak self] payslipItem in
                Task { @MainActor in
                    do {
                        try await self?.dataCoordinator.savePayslipAndReload(payslipItem)
                        self?.navigationCoordinator.navigateToPayslipDetail(for: payslipItem)

                        // Reset password state if applicable
                        if self?.showPasswordEntryView == true {
                            self?.passwordHandler.resetPasswordState()
                        }
                    } catch {
                        self?.errorHandler.handleError(error)
                    }
                }
            },
            onFailure: { [weak self] error in
                self?.errorHandler.handlePDFError(error)
            }
        )
    }

    private func setupManualEntryCoordinatorHandlers() {
        manualEntryCoordinator.setCompletionHandlers(
            onSuccess: { [weak self] payslipItem in
                Task { @MainActor in
                    do {
                        try await self?.dataCoordinator.savePayslipAndReload(payslipItem)
                        self?.navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
                    } catch {
                        self?.errorHandler.handleError(error)
                    }
                }
            },
            onFailure: { [weak self] error in
                self?.errorHandler.handleError(error)
            }
        )
    }

    private func setupDataCoordinatorHandlers() {
        dataCoordinator.setCompletionHandlers(
            onSuccess: { [weak self] in
                guard self != nil else { return }
                // Only log in non-test environments to reduce test verbosity
                if !ProcessInfo.isRunningInTestEnvironment {
                    print("HomeViewModel: Data loading completed successfully")
                }
            },
            onFailure: { [weak self] (error: Error) in
                self?.errorHandler.handleError(error)
            }
        )
    }

    private func setupNotificationCoordinatorHandlers() {
        notificationCoordinator.setCompletionHandlers(
            onPayslipDeleted: { [weak self] payslipId in
                Task { @MainActor in
                    await self?.dataCoordinator.removePayslipFromList(payslipId)
                }
            },
            onPayslipUpdated: { [weak self] in
                Task { @MainActor in
                    await self?.dataCoordinator.refreshData()
                }
            },
            onPayslipsRefresh: { [weak self] in
                Task { @MainActor in
                    await self?.dataCoordinator.refreshData()
                }
            },
            onPayslipsForcedRefresh: { [weak self] in
                Task { @MainActor in
                    await self?.dataCoordinator.forcedRefresh()
                }
            }
        )
    }

    // MARK: - Property Bindings

    /// Binds the password handler's published properties to our own
    func bindPasswordHandlerProperties() {
        passwordHandler.$showPasswordEntryView
            .assign(to: \HomeViewModel.showPasswordEntryView, on: self)
            .store(in: &cancellables)

        passwordHandler.$currentPasswordProtectedPDFData
            .assign(to: \HomeViewModel.currentPasswordProtectedPDFData, on: self)
            .store(in: &cancellables)

        passwordHandler.$currentPDFPassword
            .assign(to: \HomeViewModel.currentPDFPassword, on: self)
            .store(in: &cancellables)
    }

    /// Binds the error handler's published properties to our own
    func bindErrorHandlerProperties() {
        errorHandler.$error
            .assign(to: \HomeViewModel.error, on: self)
            .store(in: &cancellables)

        errorHandler.$errorMessage
            .assign(to: \HomeViewModel.errorMessage, on: self)
            .store(in: &cancellables)

        errorHandler.$errorType
            .assign(to: \HomeViewModel.errorType, on: self)
            .store(in: &cancellables)
    }

    /// Binds the data coordinator's published properties to our own
    func bindDataCoordinatorProperties() {
        dataCoordinator.$recentPayslips
            .assign(to: \HomeViewModel.recentPayslips, on: self)
            .store(in: &cancellables)

        dataCoordinator.$payslipData
            .assign(to: \HomeViewModel.payslipData, on: self)
            .store(in: &cancellables)
    }
}
