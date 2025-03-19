import SwiftUI
import LocalAuthentication

struct BiometricAuthView<Content: View>: View {
    @State private var isAuthenticated = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var biometricType: BiometricAuthService.BiometricType = .none
    
    private let authService: BiometricAuthService
    private let content: Content
    
    init(content: @escaping () -> Content) {
        self.content = content()
        self.authService = DIContainer.shared.biometricAuthService
    }
    
    var body: some View {
        Group {
            if isAuthenticated {
                content
            } else {
                authView
            }
        }
        .onAppear {
            biometricType = authService.getBiometricType()
            authenticate()
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("Try Again") {
                authenticate()
            }
            
            Button("Use Password") {
                // TODO: Implement password fallback
                // For now, just allow access
                isAuthenticated = true
            }
        } message: {
            Text(errorMessage ?? "An error occurred during authentication")
        }
    }
    
    private var authView: some View {
        VStack(spacing: 20) {
            // App Logo
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 70))
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)
            
            Text("Payslip Max")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Secure access required")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer().frame(height: 40)
            
            Button {
                authenticate()
            } label: {
                HStack {
                    Image(systemName: biometricIcon)
                    Text("Authenticate with \(biometricType.description)")
                }
                .frame(minWidth: 220, minHeight: 55)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    private var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock"
        }
    }
    
    private func authenticate() {
        authService.authenticate { success, error in
            if success {
                withAnimation {
                    isAuthenticated = true
                }
            } else if let error = error {
                errorMessage = error
                showError = true
            }
        }
    }
} 