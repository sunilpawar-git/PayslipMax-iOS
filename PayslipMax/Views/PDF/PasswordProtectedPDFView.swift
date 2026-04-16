import SwiftUI
import PDFKit

/// View for handling password-protected PDFs.
/// Layout-only — all logic lives in PasswordProtectedPDFViewModel.
struct PasswordProtectedPDFView: View {

    // MARK: - Properties

    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isPasswordFieldFocused: Bool
    @StateObject private var viewModel: PasswordProtectedPDFViewModel

    // MARK: - Init

    /// Accepts a pre-built ViewModel — keeps the View DI-free.
    /// Build the ViewModel using HomeViewModel.makePasswordProtectedPDFViewModel(for:onUnlock:).
    init(viewModel: PasswordProtectedPDFViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

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

            Text(viewModel.isLikelyMilitaryPDF
                ? "This appears to be a military PCDA PDF. Please enter your service number or PCDA-issued password."
                : "This PDF is password protected. Please enter the password to unlock it.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            if viewModel.isLikelyMilitaryPDF {
                militaryHintSection
            }

            passwordFieldSection

            buttonSection

            if viewModel.isLoading {
                ProgressView("Unlocking...")
                    .padding()
            }
        }
        .padding()
        .onAppear {
            viewModel.checkIfMilitaryPDF()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPasswordFieldFocused = true
            }
        }
    }

    // MARK: - Subviews

    private var militaryHintSection: some View {
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

    private var passwordFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("Enter password", text: $viewModel.password)
                .textContentType(.password)
                .keyboardType(.asciiCapable)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($isPasswordFieldFocused)
                .onSubmit {
                    Task { await viewModel.unlockPDF() }
                }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }

    private var buttonSection: some View {
        VStack(spacing: 12) {
            Button(action: { Task { await viewModel.unlockPDF() } }) {
                Text("Unlock PDF")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isLoading)

            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal)
    }
}
