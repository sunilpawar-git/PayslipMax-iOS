import SwiftUI
import LocalAuthentication

/// A view that handles the initial login process, offering options for biometric or PIN authentication.
/// It interacts with `AuthViewModel` to manage the authentication state and process.
struct LoginView: View {
    /// The view model responsible for authentication logic and state.
    @StateObject private var viewModel = DIContainer.shared.makeAuthViewModel()
    /// Controls the presentation of the PIN setup sheet.
    @State private var showingPINSetup = false
    
    /// The body of the login view, arranging UI elements.
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo and Welcome Text
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Welcome to PayslipMax")
                        .font(.title)
                        .bold()
                    
                    Text("Secure access to your payslips")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Biometric Login Button
                Button {
                    Task {
                        await viewModel.authenticate()
                    }
                } label: {
                    HStack {
                        Image(systemName: "faceid")
                        Text("Login with Face ID")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // PIN Login Option
                Button {
                    showingPINSetup = true
                } label: {
                    Text("Use PIN Instead")
                        .foregroundColor(.blue)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .padding()
            .sheet(isPresented: $showingPINSetup) {
                PINSetupView(isPresented: $showingPINSetup)
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    LoginView()
} 