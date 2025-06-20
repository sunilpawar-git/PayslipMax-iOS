import SwiftUI

struct PreferencesSettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showingBiometricSetup = false
    
    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        SettingsSection(title: "PREFERENCES") {
            VStack(spacing: 0) {
                // Custom biometric authentication row - optimized layout
                HStack(spacing: 12) {
                    // Icon background
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FintechColors.successGreen.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "faceid")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FintechColors.successGreen)
                    }
                    
                    // Simplified title
                    Text("Face/Touch ID")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.useBiometricAuth)
                        .onChange(of: viewModel.useBiometricAuth) { _, newValue in
                            viewModel.updateBiometricPreference(enabled: newValue)
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                
                FintechDivider()
                
                // Theme Picker Row - Inline dropdown instead of sheet
                HStack(spacing: 16) {
                    // Icon background
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FintechColors.chartSecondary.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FintechColors.chartSecondary)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Theme")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(FintechColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Inline Theme Picker
                    Picker("Theme", selection: $viewModel.appTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: viewModel.appTheme) { oldValue, newValue in
                        // Theme is automatically applied via ThemeManager
                        viewModel.updateAppearancePreference(theme: newValue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .sheet(isPresented: $showingBiometricSetup) {
            BiometricSetupView()
        }
    }
}

struct BiometricSetupView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = DIContainer.shared.makeSecurityViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "faceid")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Enable Biometric Authentication")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Use Face ID or Touch ID to quickly and securely access your payslip data.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Enable") {
                    Task {
                        await viewModel.authenticate()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Biometric Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PreferencesSettingsView(viewModel: DIContainer.shared.makeSettingsViewModel())
}