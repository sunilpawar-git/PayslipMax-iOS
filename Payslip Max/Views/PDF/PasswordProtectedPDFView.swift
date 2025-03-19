import SwiftUI
import PDFKit

/// View for handling password-protected PDFs.
struct PasswordProtectedPDFView: View {
    // MARK: - Properties
    
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isPasswordFieldFocused: Bool
    
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    /// The data of the PDF to unlock.
    let pdfData: Data
    
    /// Called when the PDF has been unlocked successfully.
    let onUnlock: (Data) -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.doc.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
            
            Text("Password Protected PDF")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This PDF is password protected. Please enter the password to unlock it.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ZStack {
                    TextField("Enter password", text: $password)
                        .textContentType(.password)
                        .keyboardType(.asciiCapable)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($isPasswordFieldFocused)
                        .onSubmit {
                            Task {
                                await unlockPDF()
                            }
                        }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await unlockPDF()
                    }
                }) {
                    Text("Unlock PDF")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isLoading)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal)
            
            if isLoading {
                ProgressView("Unlocking...")
                    .padding()
            }
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPasswordFieldFocused = true
            }
        }
    }
    
    @MainActor
    private func unlockPDF() async {
        if password.isEmpty {
            errorMessage = "Password cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Log attempt to unlock the PDF
        print("PasswordProtectedPDFView: Attempting to unlock PDF with password: \(password.prefix(1))***")
        
        // Get the PDF service from DIContainer
        let pdfService = DIContainer.shared.makePDFService()
        
        do {
            // Try to unlock the PDF using the service
            let unlockedData = try await pdfService.unlockPDF(pdfData, password: password)
            
            // Notify that we've successfully unlocked the PDF
            onUnlock(unlockedData)
            presentationMode.wrappedValue.dismiss()
        } catch PDFServiceError.incorrectPassword {
            errorMessage = "Incorrect password. Please try again."
        } catch PDFServiceError.unsupportedEncryptionMethod {
            errorMessage = "This PDF uses an unsupported encryption method."
        } catch {
            print("PasswordProtectedPDFView: Error unlocking PDF: \(error)")
            errorMessage = "An error occurred while unlocking the PDF. Please try again."
        }
        
        isLoading = false
    }
    
    private func createMilitaryPDFFormat(pdfData: Data, password: String) throws -> Data {
        // Create a special format that wraps the password with the data
        // Format: "MILPDF:" + 4 bytes for password length + password + original PDF data
        
        let marker = "MILPDF:"
        guard let markerData = marker.data(using: .utf8),
              let passwordData = password.data(using: .utf8) else {
            throw PDFServiceError.unableToProcessPDF
        }
        
        let passwordLength = UInt32(passwordData.count)
        var lengthBytes = Data(count: 4)
        lengthBytes.withUnsafeMutableBytes { 
            $0.storeBytes(of: passwordLength, as: UInt32.self)
        }
        
        var combinedData = Data()
        combinedData.append(markerData)
        combinedData.append(lengthBytes)
        combinedData.append(passwordData)
        combinedData.append(pdfData)
        
        return combinedData
    }
} 