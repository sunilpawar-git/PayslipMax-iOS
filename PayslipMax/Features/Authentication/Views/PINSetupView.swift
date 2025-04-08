import SwiftUI

struct PINSetupView: View {
    @StateObject private var viewModel = DIContainer.shared.makeAuthViewModel()
    @Binding var isPresented: Bool
    @FocusState private var isPINFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Enter your 4-digit PIN")
                    .font(.headline)
                
                // PIN Entry Field
                SecureField("PIN", text: $viewModel.pinCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .focused($isPINFieldFocused)
                    .frame(width: 200)
                    .onChange(of: viewModel.pinCode) { oldValue, newValue in
                        if newValue.count > 4 {
                            viewModel.pinCode = String(newValue.prefix(4))
                        }
                    }
                
                // PIN Keypad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        PINButton(number: "\(number)") {
                            if viewModel.pinCode.count < 4 {
                                viewModel.pinCode += "\(number)"
                            }
                        }
                    }
                    
                    PINButton(number: "⌫") {
                        if !viewModel.pinCode.isEmpty {
                            viewModel.pinCode.removeLast()
                        }
                    }
                    
                    PINButton(number: "0") {
                        if viewModel.pinCode.count < 4 {
                            viewModel.pinCode += "0"
                        }
                    }
                    
                    PINButton(number: "✓") {
                        Task {
                            do {
                                let success = try await viewModel.validatePIN()
                                if success {
                                    isPresented = false
                                }
                            } catch {
                                // Error handling is already done in the viewModel
                            }
                        }
                    }
                }
                .padding()
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .padding()
            .navigationTitle("PIN Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
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

// MARK: - Supporting Views
private struct PINButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(Color(.systemBackground))
                .cornerRadius(30)
                .shadow(radius: 2)
        }
    }
}

#Preview {
    PINSetupView(isPresented: .constant(true))
} 