import Foundation
import SwiftUI

/// Support utilities and convenience properties for HomeViewModel
/// Contains computed properties and helper methods
extension HomeViewModel {

    // MARK: - Loading State Properties

    /// Whether the view model is loading data
    var isLoading: Bool {
        dataCoordinator.isLoading || pdfCoordinator.isProcessing || manualEntryCoordinator.isProcessing
    }

    /// Whether the view model is uploading a payslip
    var isUploading: Bool {
        pdfCoordinator.isUploading
    }

    /// Whether we're currently processing an unlocked PDF
    var isProcessingUnlocked: Bool {
        pdfCoordinator.isProcessingUnlocked
    }

    // MARK: - Data Properties

    /// The data for the currently unlocked PDF
    var unlockedPDFData: Data? {
        pdfCoordinator.unlockedPDFData
    }

    // MARK: - Manual Entry Properties

    /// Flag indicating whether to show the manual entry form
    var showManualEntryForm: Bool {
        manualEntryCoordinator.showManualEntryForm
    }

    /// Binding for the manual entry form state
    var showManualEntryFormBinding: Binding<Bool> {
        Binding(
            get: {
                let currentState = self.manualEntryCoordinator.showManualEntryForm
                print("[HomeViewModel] showManualEntryFormBinding GET: \(currentState)")
                return currentState
            },
            set: { newValue in
                print("[HomeViewModel] showManualEntryFormBinding SET: \(newValue)")
                if newValue {
                    print("[HomeViewModel] Binding triggered showManualEntry()")
                    self.manualEntryCoordinator.showManualEntry()
                } else {
                    print("[HomeViewModel] Binding triggered hideManualEntry()")
                    self.manualEntryCoordinator.hideManualEntry()
                }
            }
        )
    }
}
