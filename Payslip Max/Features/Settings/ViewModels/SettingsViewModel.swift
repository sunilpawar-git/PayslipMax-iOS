import SwiftUI
import LocalAuthentication
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var useBiometrics: Bool {
        didSet {
            UserDefaults.standard.set(useBiometrics, forKey: "useBiometrics")
        }
    }
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        }
    }
    
    // MARK: - Properties
    private let securityService: SecurityServiceProtocol
    private let dataService: DataServiceProtocol
    
    // MARK: - Initialization
    init(securityService: SecurityServiceProtocol? = nil, dataService: DataServiceProtocol? = nil) {
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        
        // Load saved preferences
        self.useBiometrics = UserDefaults.standard.bool(forKey: "useBiometrics")
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    // MARK: - Public Methods
    func exportData() async throws {
        do {
            isLoading = true
            defer { isLoading = false }
            
            _ = try await dataService.fetch(PayslipItem.self)
            // Export implementation
        } catch {
            self.error = error
            throw error
        }
    }
    
    func backupData() async throws {
        do {
            isLoading = true
            defer { isLoading = false }
            
            _ = try await dataService.fetch(PayslipItem.self)
            // Backup implementation
        } catch {
            self.error = error
            throw error
        }
    }
    
    func resetPIN() async throws {
        isLoading = true
        
        do {
            // Actual PIN reset implementation
            let authenticated = try await securityService.authenticate()
            guard authenticated else {
                throw SecurityError.authenticationFailed
            }
            
            // Additional PIN reset logic here
            // TODO: Implement PIN reset
            
        } catch {
            self.error = error
            isLoading = false
            throw error
        }
        
        isLoading = false
    }
    
    func rateApp() {
        guard let url = URL(string: "itms-apps://apple.com/app/id\(AppConstants.appStoreId)") else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Private Types
    private enum SecurityError: LocalizedError {
        case authenticationFailed
        
        var errorDescription: String? {
            switch self {
            case .authenticationFailed:
                return "Authentication failed. Please try again."
            }
        }
    }
} 