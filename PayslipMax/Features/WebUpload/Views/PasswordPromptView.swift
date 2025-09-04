import SwiftUI

/// Password prompt view for protected PDFs
struct PasswordPromptView: View {
    let fileName: String
    @Binding var password: String
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isPasswordFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("This PDF is password protected")
                    .font(.headline)
                
                Text("Enter the password for \(fileName)")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .focused($isPasswordFocused)
                    .onSubmit {
                        if !password.isEmpty {
                            submitAndDismiss()
                        }
                    }
                
                Button(action: submitAndDismiss) {
                    Text("Submit")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty)
                
                Spacer()
            }
            .padding(.top, 30)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Small delay before focusing to prevent constraint conflicts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isPasswordFocused = true
                }
            }
        }
        // Use intrinsicSize to avoid layout constraint warnings
        .intrinsicContentSize()
    }
    
    // Helper function to dismiss the sheet after submitting
    private func submitAndDismiss() {
        if !password.isEmpty {
            dismiss()
            // Small delay to ensure dismiss completes before processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onSubmit()
            }
        }
    }
}

// Extension to help with intrinsic content size
extension View {
    func intrinsicContentSize() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Preview
#if DEBUG
struct PasswordPromptView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordPromptView(
            fileName: "sample-payslip.pdf",
            password: .constant(""),
            onSubmit: {},
            onCancel: {}
        )
    }
}
#endif
