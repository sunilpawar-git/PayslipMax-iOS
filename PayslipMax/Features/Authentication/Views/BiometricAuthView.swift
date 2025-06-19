import SwiftUI
import LocalAuthentication

struct BiometricAuthView<Content: View>: View {
    @State private var isAuthenticated = false
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
            if isAuthenticated {
                content
            } else {
                authView
            }
        }
        .task {
            // More robust way to refresh biometric type when view appears
            biometricType = authService.getBiometricType()
            print("BiometricAuthView: Detected biometric type: \(biometricType.rawDisplayName)")
            
            // Check user preference before auto-authenticating
            let userDefaults = UserDefaults.standard
            let biometricEnabled = userDefaults.bool(forKey: "useBiometricAuth")
            
            print("BiometricAuthView: Biometric preference enabled: \(biometricEnabled)")
            
            // Auto-authenticate only if biometrics are available AND user has enabled it
            if biometricType != .none && biometricEnabled {
                authenticate()
            }
        }
        .onAppear {
            // Also refresh on appear for better reliability
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
                isAuthenticated = true
                showPINEntry = false
            })
        }
    }
    
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
    
    private var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.rectangle"
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

// Simple PIN entry view
struct PINEntryView: View {
    @State private var pin = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = DIContainer.shared.makeAuthViewModel()
    
    var onAuthenticated: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Your PIN")
                    .font(.title2)
                    .padding(.top)
                
                SecureField("PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Button {
                    verifyPIN()
                } label: {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Authenticate")
                    }
                }
                .padding()
                .frame(minWidth: 200, minHeight: 44)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(isProcessing)
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationBarTitle("PIN Authentication", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func verifyPIN() {
        guard !pin.isEmpty else {
            errorMessage = "Please enter your PIN"
            showError = true
            return
        }
        
        isProcessing = true
        showError = false
        
        // Update the viewModel's PIN and verify it
        viewModel.pinCode = pin
        
        Task {
            do {
                let isValid = try await viewModel.validatePIN()
                await MainActor.run {
                    isProcessing = false
                    if isValid {
                        onAuthenticated()
                    } else {
                        errorMessage = "Incorrect PIN. Please try again."
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

extension BiometricAuthService.BiometricType {
    var rawDisplayName: String {
        switch self {
        case .none:
            return "PIN"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        }
    }
} 