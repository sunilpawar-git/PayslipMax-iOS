import SwiftUI
import LocalAuthentication

/// Enhanced BiometricAuthView that includes splash screen with financial quotes
/// Follows single responsibility: Authentication + Splash transition
struct EnhancedBiometricAuthView<Content: View>: View {
    @State private var authenticationState: AuthenticationState = .unauthenticated
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var biometricType: BiometricAuthService.BiometricType = .none
    @State private var showPINEntry = false
    
    private let authService: BiometricAuthService
    private let content: Content
    
    init(content: @escaping () -> Content) {
        self.content = content()
        self.authService = DIContainer.shared.biometricAuthService
        self._biometricType = State(initialValue: DIContainer.shared.biometricAuthService.getBiometricType())
    }
    
    var body: some View {
        Group {
            switch authenticationState {
            case .unauthenticated:
                authView
            case .authenticatedShowingSplash:
                SplashScreenView {
                    authenticationState = .splashComplete
                }
            case .splashComplete:
                content
            }
        }
        .task {
            biometricType = authService.getBiometricType()
            
            let userDefaults = UserDefaults.standard
            let biometricEnabled = userDefaults.bool(forKey: "useBiometricAuth")
            
            // Auto-authenticate if biometrics available and enabled
            if biometricType != .none && biometricEnabled {
                authenticate()
            }
        }
        .onAppear {
            biometricType = authService.getBiometricType()
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("Try Again") {
                authenticate()
            }
            Button("Use PIN") {
                showPINEntry = true
            }
        } message: {
            Text(errorMessage ?? "An error occurred during authentication")
        }
        .sheet(isPresented: $showPINEntry) {
            PINEntryView(onAuthenticated: {
                authenticationState = .authenticatedShowingSplash
                showPINEntry = false
            })
        }
    }
    
    // MARK: - Auth View
    
    private var authView: some View {
        VStack(spacing: 20) {
            // App Logo
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 70))
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)
            
            Text("PayslipMax")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Secure access required")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer().frame(height: 40)
            
            // Biometric auth button
            Button {
                if biometricType == .none {
                    showPINEntry = true
                } else {
                    authenticate()
                }
            } label: {
                HStack {
                    Image(systemName: biometricIcon)
                    if biometricType == .none {
                        Text("Enter PIN")
                    } else {
                        Text("Authenticate with \(biometricType.rawDisplayName)")
                    }
                }
                .frame(minWidth: 220, minHeight: 55)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            if biometricType != .none {
                Button("Use PIN Instead") {
                    showPINEntry = true
                }
                .padding(.top, 12)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Helper Properties & Methods
    
    private var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.rectangle"
        }
    }
    
    private func authenticate() {
        authService.authenticate { success, error in
            if success {
                withAnimation {
                    authenticationState = .authenticatedShowingSplash
                }
            } else if let error = error {
                errorMessage = error
                showError = true
            }
        }
    }
}

// MARK: - Authentication State

private enum AuthenticationState {
    case unauthenticated
    case authenticatedShowingSplash
    case splashComplete
}

// Note: PINEntryView is already defined in BiometricAuthView.swift 