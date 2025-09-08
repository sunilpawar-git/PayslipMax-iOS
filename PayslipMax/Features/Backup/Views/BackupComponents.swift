import SwiftUI

// MARK: - Backup Components Module

/**
 This file serves as the main orchestration point for all backup-related UI components.
 All components have been extracted into focused, single-responsibility modules to maintain
 the 300-line architectural constraint while ensuring MVVM compliance and SOLID principles.

 Components are organized as follows:
 - BackupCardComponents: Card-based UI elements for backup actions
 - BackupInfoComponents: Information display components
 - QRScannerComponents: QR code scanning functionality
 - BackupProgressComponents: Progress indicators and success animations
 - BackupStatsComponents: Statistics display and data models

 This modular approach ensures:
 - Single Responsibility Principle compliance
 - Improved testability and maintainability
 - Clean separation of concerns
 - Adherence to MVVM architecture
 - Dependency injection support
 */

// Re-export all backup components for convenience
// Note: Using local imports instead of module imports for proper compilation
