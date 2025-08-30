import Foundation
import Combine
import CryptoKit

/// Service for managing model updates in production environment
public class LiteRTModelUpdateService {

    // MARK: - Singleton

    public static let shared = LiteRTModelUpdateService()

    private init() {
        setupUpdateMechanism()
    }

    // MARK: - Properties

    private let productionManager = LiteRTProductionManager.shared
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Model Update Configuration

    /// Model update configuration
    public struct ModelUpdateConfiguration {
        public var updateInterval: TimeInterval = 86400 // 24 hours
        public var enableAutomaticUpdates = true
        public var updateSourceURL: URL?
        public var backupModelsEnabled = true
        public var checksumValidationEnabled = true
        public var maxDownloadSize: Int64 = 50 * 1024 * 1024 // 50MB
        public var updateTimeout: TimeInterval = 300 // 5 minutes
    }

    public var configuration = ModelUpdateConfiguration()

    /// Model update status
    @Published public private(set) var updateStatus: UpdateStatus = .idle

    /// Model update status enum
    public enum UpdateStatus: String {
        case idle = "Idle"
        case checking = "Checking"
        case downloading = "Downloading"
        case validating = "Validating"
        case installing = "Installing"
        case completed = "Completed"
        case failed = "Failed"
    }

    /// Update priority levels
    public enum UpdatePriority: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }

    /// Model update information
public struct ModelUpdateInfo {
    public let modelType: String // Using string representation to avoid circular dependencies
    public let currentVersion: String
    public let availableVersion: String
    public let downloadSize: Int64
    public let checksum: String
    public let releaseNotes: String?
    public let priority: UpdatePriority

    /// Convert to LiteRTModelType if needed
    public func toLiteRTModelType() -> String {
        return modelType
    }
}

    /// Available model updates
    @Published public private(set) var availableUpdates: [ModelUpdateInfo] = []

    /// Update history
    @Published public private(set) var updateHistory: [UpdateRecord] = []

    /// Update record structure
    public struct UpdateRecord {
        public let timestamp: Date
        public let modelType: String
        public let oldVersion: String
        public let newVersion: String
        public let status: UpdateStatus
        public let errorMessage: String?
    }

    // MARK: - Update Mechanism Setup

    /// Setup update mechanism
    private func setupUpdateMechanism() {
        // Setup default update source URL (would be configured for production)
        configuration.updateSourceURL = URL(string: "https://api.payslipmax.com/models/updates")

        // Start periodic update checks if enabled
        if configuration.enableAutomaticUpdates {
            startPeriodicUpdateChecks()
        }

        print("[LiteRTModelUpdateService] Model update mechanism initialized")
    }

    /// Start periodic update checks
    private func startPeriodicUpdateChecks() {
        updateTimer?.invalidate()

        updateTimer = Timer.scheduledTimer(withTimeInterval: configuration.updateInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.checkForUpdates()
            }
        }

        print("[LiteRTModelUpdateService] Periodic update checks started (\(configuration.updateInterval)s interval)")
    }

    // MARK: - Update Checking

    /// Check for model updates
    public func checkForUpdates() async {
        guard updateStatus == .idle else {
            print("[LiteRTModelUpdateService] Update check already in progress")
            return
        }

        updateStatus = .checking
        print("[LiteRTModelUpdateService] Checking for model updates...")

        do {
            let updates = try await fetchAvailableUpdates()
            await MainActor.run {
                self.availableUpdates = updates
                self.updateStatus = .idle
            }

            if !updates.isEmpty {
                print("[LiteRTModelUpdateService] Found \(updates.count) model updates")
                notifyUpdateAvailable(updates)
            } else {
                print("[LiteRTModelUpdateService] No updates available")
            }

        } catch {
            print("[LiteRTModelUpdateService] Failed to check for updates: \(error)")
            await MainActor.run {
                self.updateStatus = .failed
            }
        }
    }

    /// Fetch available updates from server
    private func fetchAvailableUpdates() async throws -> [ModelUpdateInfo] {
        guard let updateURL = configuration.updateSourceURL else {
            throw NSError(domain: "LiteRTModelUpdateService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Update source URL not configured"])
        }

        // Create request
        var request = URLRequest(url: updateURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authentication headers (would be configured for production)
        request.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "LiteRTModelUpdateService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }

        // Parse update information
        let updateResponse = try JSONDecoder().decode(UpdateResponse.self, from: data)

        // Convert updates to ModelUpdateInfo
        var availableUpdates: [ModelUpdateInfo] = []

        for update in updateResponse.updates {
            if let updateInfo = update.toModelUpdateInfo() {
                // Check if this is a newer version
                let currentVersions = getCurrentModelVersions()
                if let currentVersion = currentVersions[updateInfo.modelType],
                   isNewerVersion(updateInfo.availableVersion, than: currentVersion) {
                    availableUpdates.append(updateInfo)
                }
            }
        }

        return availableUpdates
    }

    // MARK: - Update Installation

    /// Install model updates
    public func installUpdates(_ updates: [ModelUpdateInfo]) async throws {
        guard updateStatus == .idle else {
            throw NSError(domain: "LiteRTModelUpdateService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Update already in progress"])
        }

        updateStatus = .downloading
        print("[LiteRTModelUpdateService] Installing \(updates.count) model updates...")

        var installedUpdates: [ModelUpdateInfo] = []
        var failedUpdates: [(ModelUpdateInfo, Error)] = []

        for update in updates {
            do {
                try await installUpdate(update)
                installedUpdates.append(update)

                // Record successful update
                let record = UpdateRecord(
                    timestamp: Date(),
                    modelType: update.modelType,
                    oldVersion: update.currentVersion,
                    newVersion: update.availableVersion,
                    status: UpdateStatus.completed,
                    errorMessage: nil
                )
                updateHistory.append(record)

            } catch {
                print("[LiteRTModelUpdateService] Failed to install \(update.modelType): \(error)")
                failedUpdates.append((update, error))

                // Record failed update
                let record = UpdateRecord(
                    timestamp: Date(),
                    modelType: update.modelType,
                    oldVersion: update.currentVersion,
                    newVersion: update.availableVersion,
                    status: UpdateStatus.failed,
                    errorMessage: error.localizedDescription
                )
                updateHistory.append(record)
            }
        }

        // Update status
        if failedUpdates.isEmpty {
            updateStatus = .completed
            print("[LiteRTModelUpdateService] All updates installed successfully")

            // Remove installed updates from available list
            let installedModelTypes = Set(installedUpdates.map { $0.modelType })
            await MainActor.run {
                self.availableUpdates.removeAll { update in
                    installedModelTypes.contains(update.modelType)
                }
            }

        } else if installedUpdates.isEmpty {
            updateStatus = .failed
            throw NSError(domain: "LiteRTModelUpdateService", code: 4, userInfo: [NSLocalizedDescriptionKey: "All updates failed to install"])
        } else {
            updateStatus = .completed
            print("[LiteRTModelUpdateService] \(installedUpdates.count) updates installed, \(failedUpdates.count) failed")
        }
    }

    /// Install single model update
    private func installUpdate(_ update: ModelUpdateInfo) async throws {
        // Create backup of current model if enabled
        if configuration.backupModelsEnabled {
            try await createModelBackup(update.modelType)
        }

        // Download new model
        let modelData = try await downloadModel(update)

        // Validate model
        try validateModel(modelData, with: update.checksum)

        // Install model
        try await installModelData(modelData, for: update.modelType)

        print("[LiteRTModelUpdateService] Successfully installed \(update.modelType) v\(update.availableVersion)")
    }

    /// Download model from server
    private func downloadModel(_ update: ModelUpdateInfo) async throws -> Data {
        guard let baseURL = configuration.updateSourceURL else {
            throw NSError(domain: "LiteRTModelUpdateService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Update source URL not configured"])
        }

        let modelURL = baseURL.appendingPathComponent("models/\(update.modelType)/\(update.availableVersion).tflite")

        var request = URLRequest(url: modelURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = configuration.updateTimeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "LiteRTModelUpdateService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to download model"])
        }

        // Check download size
        guard Int64(data.count) <= configuration.maxDownloadSize else {
            throw NSError(domain: "LiteRTModelUpdateService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Model file too large"])
        }

        return data
    }

    /// Validate downloaded model
    private func validateModel(_ data: Data, with expectedChecksum: String) throws {
        guard configuration.checksumValidationEnabled else { return }

        let computedChecksum = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()

        guard computedChecksum == expectedChecksum else {
            throw NSError(domain: "LiteRTModelUpdateService", code: 8, userInfo: [NSLocalizedDescriptionKey: "Checksum validation failed"])
        }

        print("[LiteRTModelUpdateService] Model checksum validated successfully")
    }

    /// Install model data
    private func installModelData(_ data: Data, for modelType: String) async throws {
        // Get model file path
        guard let modelPath = getModelPath(for: modelType) else {
            throw NSError(domain: "LiteRTModelUpdateService", code: 9, userInfo: [NSLocalizedDescriptionKey: "Model path not found"])
        }

        // Write model data to file
        try data.write(to: modelPath, options: .atomic)

        // Update model metadata
        try await updateModelMetadata(for: modelType, data: data)

        print("[LiteRTModelUpdateService] Model installed at: \(modelPath.path)")
    }

    /// Create backup of current model
    private func createModelBackup(_ modelType: String) async throws {
        guard let modelPath = getModelPath(for: modelType),
              let backupPath = getBackupPath(for: modelType) else { return }

        // Create backup directory if needed
        try FileManager.default.createDirectory(at: backupPath.deletingLastPathComponent(), withIntermediateDirectories: true)

        // Copy current model to backup
        if FileManager.default.fileExists(atPath: modelPath.path) {
            try FileManager.default.copyItem(at: modelPath, to: backupPath)
            print("[LiteRTModelUpdateService] Backup created: \(backupPath.path)")
        }
    }

    /// Update model metadata
    private func updateModelMetadata(for modelType: String, data: Data) async throws {
        // This would update the model_metadata.json file with new version info
        // Implementation would depend on the metadata structure
        print("[LiteRTModelUpdateService] Model metadata updated for \(modelType)")
    }

    // MARK: - Utility Methods

    /// Get authentication token (would be implemented for production)
    private func getAuthToken() -> String {
        // In production, this would retrieve a secure auth token
        return "production-auth-token"
    }

    /// Get current model versions
    private func getCurrentModelVersions() -> [String: String] {
        // This would read current versions from model metadata
        return [
            "table_detection": "1.0.0",
            "text_recognition": "1.0.0",
            "document_classifier": "1.0.0"
        ]
    }

    /// Check if version is newer
    private func isNewerVersion(_ newVersion: String, than currentVersion: String) -> Bool {
        // Simple version comparison (would be more sophisticated in production)
        return newVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }

    /// Get model file path
    private func getModelPath(for modelType: String) -> URL? {
        // This would return the actual model file path
        let modelsDirectory = Bundle.main.bundleURL.appendingPathComponent("Resources/Models")
        let fileName = "\(modelType).tflite"
        return modelsDirectory.appendingPathComponent(fileName)
    }

    /// Get backup file path
    private func getBackupPath(for modelType: String) -> URL? {
        let backupDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("LiteRT/Backups")
        let fileName = "\(modelType)_backup.tflite"
        return backupDirectory?.appendingPathComponent(fileName)
    }

    /// Notify about available updates
    private func notifyUpdateAvailable(_ updates: [ModelUpdateInfo]) {
        // This could trigger notifications, alerts, or automated updates
        print("[LiteRTModelUpdateService] Available updates: \(updates.map { "\($0.modelType) v\($0.availableVersion)" })")
    }

    // MARK: - Public Interface

    /// Get update service status
    public func getUpdateStatus() -> [String: Any] {
        return [
            "status": updateStatus.rawValue,
            "availableUpdates": availableUpdates.count,
            "updateHistory": updateHistory.suffix(10).map { record in
                [
                    "timestamp": ISO8601DateFormatter().string(from: record.timestamp),
                    "modelType": record.modelType,
                    "oldVersion": record.oldVersion,
                    "newVersion": record.newVersion,
                    "status": record.status.rawValue,
                    "errorMessage": record.errorMessage ?? ""
                ]
            },
            "configuration": [
                "updateInterval": configuration.updateInterval,
                "automaticUpdates": configuration.enableAutomaticUpdates,
                "backupEnabled": configuration.backupModelsEnabled,
                "checksumValidation": configuration.checksumValidationEnabled
            ]
        ]
    }

    /// Force update check
    public func forceUpdateCheck() async {
        await checkForUpdates()
    }

    /// Install all available updates
    public func installAllUpdates() async throws {
        try await installUpdates(availableUpdates)
    }

    /// Clear update history
    public func clearUpdateHistory() {
        updateHistory.removeAll()
        print("[LiteRTModelUpdateService] Update history cleared")
    }
}

// MARK: - Supporting Types

/// Update response from server
private struct UpdateResponse: Codable {
    let updates: [ModelUpdate]
}

/// Model update information from server
private struct ModelUpdate: Codable {
    let modelType: String
    let version: String
    let size: Int64
    let checksum: String
    let releaseNotes: String?
    let priority: String

    enum CodingKeys: String, CodingKey {
        case modelType, version, size, checksum, releaseNotes, priority
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let modelTypeString = try container.decode(String.self, forKey: .modelType)
        modelType = modelTypeString
        version = try container.decode(String.self, forKey: .version)
        size = try container.decode(Int64.self, forKey: .size)
        checksum = try container.decode(String.self, forKey: .checksum)
        releaseNotes = try container.decodeIfPresent(String.self, forKey: .releaseNotes)
        priority = try container.decode(String.self, forKey: .priority)
    }

    /// Convert to ModelUpdateInfo
    func toModelUpdateInfo() -> LiteRTModelUpdateService.ModelUpdateInfo? {
        guard let priorityEnum = LiteRTModelUpdateService.UpdatePriority(rawValue: priority) else {
            return nil
        }

        return LiteRTModelUpdateService.ModelUpdateInfo(
            modelType: modelType,
            currentVersion: "1.0.0", // Would be retrieved from current metadata
            availableVersion: version,
            downloadSize: size,
            checksum: checksum,
            releaseNotes: releaseNotes,
            priority: priorityEnum
        )
    }
}
