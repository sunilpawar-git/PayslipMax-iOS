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
    @State private var isLikelyMilitaryPDF: Bool = false
    @State private var attemptCount: Int = 0
    
    /// The data of the PDF to unlock.
    let pdfData: Data
    
    /// Called when the PDF has been unlocked successfully.
    let onUnlock: (Data, String) -> Void
    
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
            
            Text(isLikelyMilitaryPDF 
                ? "This appears to be a military PCDA PDF. Please enter your service number or PCDA-issued password."
                : "This PDF is password protected. Please enter the password to unlock it.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Military PDF hint
            if isLikelyMilitaryPDF {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Common PCDA PDF passwords:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("• Your service number")
                    Text("• Your service number with @")
                    Text("• \"PCDA\" (all caps)")
                    Text("• Military ID (uppercase)")
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
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
            // Check if this is likely a military PDF based on file metadata
            checkIfMilitaryPDF()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPasswordFieldFocused = true
            }
        }
    }
    
    private func checkIfMilitaryPDF() {
        if let pdfDocument = PDFDocument(data: pdfData) {
            // Check document attributes
            if let attributes = pdfDocument.documentAttributes {
                if let creator = attributes[PDFDocumentAttribute.creatorAttribute] as? String,
                   creator.contains("PCDA") || creator.contains("Defence") {
                    isLikelyMilitaryPDF = true
                    return
                }
                
                if let title = attributes[PDFDocumentAttribute.titleAttribute] as? String,
                   title.contains("Defence") || title.contains("Army") || title.contains("Military") {
                    isLikelyMilitaryPDF = true
                    return
                }
            }
            
            // If we have file name information and it contains military keywords
            if let filename = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String {
                if filename.contains("PCDA") || filename.contains("PAY") || 
                   filename.contains("Army") || filename.contains("ARMY") {
                    isLikelyMilitaryPDF = true
                    return
                }
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
        attemptCount += 1
        
        // Log attempt to unlock the PDF
        print("PasswordProtectedPDFView: Attempting to unlock PDF with password: \(password.prefix(1))***")
        
        // Get the PDF service and PCDA handler from DIContainer
        let pdfService = DIContainer.shared.makePDFService()
        let pcdaHandler = DIContainer.shared.makePCDAPayslipHandler()
        
        // Try specialized handling for military PDFs if detected
        if isLikelyMilitaryPDF {
            print("PasswordProtectedPDFView: Using specialized military PDF handling")
            let (unlockedData, successfulPassword) = await pcdaHandler.unlockPDF(data: pdfData, basePassword: password)
            
            if let unlockedData = unlockedData, let successPassword = successfulPassword {
                print("PasswordProtectedPDFView: Military PDF unlocked with password variant")
                onUnlock(unlockedData, successPassword)
                presentationMode.wrappedValue.dismiss()
                return
            }
        }
        
        // If military-specific handling didn't work or it's not a military PDF, try the standard approach
        do {
            // Try to unlock the PDF using the service
            let unlockedData = try await pdfService.unlockPDF(data: pdfData, password: password)
            
            // Notify that we've successfully unlocked the PDF
            onUnlock(unlockedData, password)
            presentationMode.wrappedValue.dismiss()
        } catch PDFServiceError.incorrectPassword {
            if attemptCount >= 2 && !isLikelyMilitaryPDF {
                // After multiple failed attempts, suggest it might be a military PDF
                isLikelyMilitaryPDF = true
                errorMessage = "Incorrect password. This might be a military PDF - try your service number or PCDA password."
            } else if isLikelyMilitaryPDF {
                errorMessage = "Incorrect password. Try your service number or a PCDA-specific password."
            } else {
                errorMessage = "Incorrect password. Please try again."
            }
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