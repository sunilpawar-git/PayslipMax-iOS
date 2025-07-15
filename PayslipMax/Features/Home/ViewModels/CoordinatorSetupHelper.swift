import Foundation
import SwiftUI
import Combine

/// Helper class to setup coordinator relationships and handlers
/// Extracted to keep HomeViewModelCoordinator under 300 lines
@MainActor
class CoordinatorSetupHelper {
    
    /// Sets up completion handlers between coordinators
    static func setupCoordinatorHandlers(
        pdfCoordinator: PDFProcessingCoordinator,
        dataCoordinator: DataLoadingCoordinator,
        manualEntryCoordinator: ManualEntryCoordinator,
        notificationCoordinator: NotificationCoordinator,
        navigationCoordinator: HomeNavigationCoordinator,
        passwordHandler: PasswordProtectedPDFHandler,
        errorHandler: ErrorHandler
    ) {
        // PDF processing completion handlers
        pdfCoordinator.setCompletionHandlers(
            onSuccess: { payslipItem in
                Task { @MainActor in
                    do {
                        try await dataCoordinator.savePayslipAndReload(payslipItem)
                        navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
                        
                        // Reset password state if applicable
                        if passwordHandler.showPasswordEntryView {
                            passwordHandler.resetPasswordState()
                        }
                    } catch {
                        errorHandler.handleError(error)
                    }
                }
            },
            onFailure: { error in
                errorHandler.handlePDFError(error)
            }
        )
        
        // Manual entry processing completion handlers
        manualEntryCoordinator.setCompletionHandlers(
            onSuccess: { payslipItem in
                Task { @MainActor in
                    do {
                        try await dataCoordinator.savePayslipAndReload(payslipItem)
                        navigationCoordinator.navigateToPayslipDetail(for: payslipItem)
                    } catch {
                        errorHandler.handleError(error)
                    }
                }
            },
            onFailure: { error in
                errorHandler.handleError(error)
            }
        )
        
        // Data loading completion handlers
        dataCoordinator.setCompletionHandlers(
            onSuccess: {
                print("CoordinatorSetupHelper: Data loading completed successfully")
            },
            onFailure: { error in
                errorHandler.handleError(error)
            }
        )
        
        // Notification handling setup
        notificationCoordinator.setCompletionHandlers(
            onPayslipDeleted: { payslipId in
                Task { @MainActor in
                    await dataCoordinator.removePayslipFromList(payslipId)
                }
            },
            onPayslipUpdated: {
                Task { @MainActor in
                    await dataCoordinator.refreshData()
                }
            },
            onPayslipsRefresh: {
                Task { @MainActor in
                    await dataCoordinator.refreshData()
                }
            },
            onPayslipsForcedRefresh: {
                Task { @MainActor in
                    await dataCoordinator.forcedRefresh()
                }
            }
        )
    }
    
    /// Sets up property bindings for a coordinator
    static func setupPropertyBindings(
        coordinator: HomeViewModel,
        passwordHandler: PasswordProtectedPDFHandler,
        errorHandler: ErrorHandler,
        cancellables: inout Set<AnyCancellable>
    ) {
        // Bind password handler properties
        passwordHandler.$showPasswordEntryView
            .assign(to: \.showPasswordEntryView, on: coordinator)
            .store(in: &cancellables)
        
        passwordHandler.$currentPasswordProtectedPDFData
            .assign(to: \.currentPasswordProtectedPDFData, on: coordinator)
            .store(in: &cancellables)
        
        passwordHandler.$currentPDFPassword
            .assign(to: \.currentPDFPassword, on: coordinator)
            .store(in: &cancellables)
        
        // Bind error handler properties
        errorHandler.$error
            .assign(to: \.error, on: coordinator)
            .store(in: &cancellables)
        
        errorHandler.$errorMessage
            .assign(to: \.errorMessage, on: coordinator)
            .store(in: &cancellables)
        
        errorHandler.$errorType
            .assign(to: \.errorType, on: coordinator)
            .store(in: &cancellables)
    }
} 