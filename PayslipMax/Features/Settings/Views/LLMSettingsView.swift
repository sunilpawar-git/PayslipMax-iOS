//
//  LLMSettingsView.swift
//  PayslipMax
//
//  Settings view for AI-powered payslip parsing
//

import SwiftUI

struct LLMSettingsView: View {
    @StateObject private var viewModel: LLMSettingsViewModel
    @State private var showAPIKeyField = false

    init(viewModel: LLMSettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        SettingsSection(title: LLMStrings.settingsTitle) {
            VStack(spacing: 0) {
                // Enable LLM Toggle
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FintechColors.chartSecondary.opacity(0.15))
                            .frame(width: 32, height: 32)

                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FintechColors.chartSecondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LLMStrings.enableTitle)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(FintechColors.textPrimary)
                        Text(LLMStrings.enableSubtitle)
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.isLLMEnabled)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if viewModel.isLLMEnabled {
                    FintechDivider()

                    // Provider Selection
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(FintechColors.primaryBlue.opacity(0.15))
                                .frame(width: 32, height: 32)

                            Image(systemName: "cloud.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(FintechColors.primaryBlue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LLMStrings.providerTitle)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(FintechColors.textPrimary)
                        }

                        Spacer()

                        Picker("Provider", selection: $viewModel.selectedProvider) {
                            Text("OpenAI").tag(LLMProvider.openai)
                            Text("Google Gemini").tag(LLMProvider.gemini)
                            // Anthropic not yet supported
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    FintechDivider()

                    // API Key Entry
                    VStack(spacing: 0) {
                        Button(action: {
                            withAnimation {
                                showAPIKeyField.toggle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(FintechColors.successGreen.opacity(0.15))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "key.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(FintechColors.successGreen)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LLMStrings.apiKeyTitle)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(FintechColors.textPrimary)
                                    Text(apiKeyStatusText)
                                        .font(.caption)
                                        .foregroundColor(apiKeyStatusColor)
                                }

                                Spacer()

                                Image(systemName: showAPIKeyField ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(FintechColors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if showAPIKeyField {
                            VStack(alignment: .leading, spacing: 12) {
                                SecureField(String(format: LLMStrings.apiKeyPlaceholder, viewModel.selectedProvider.rawValue), text: $viewModel.apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)

                                if let message = viewModel.validationMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                        Text(message)
                                            .font(.caption)
                                    }
                                    .foregroundColor(FintechColors.dangerRed)
                                }

                                Button(action: {
                                    Task {
                                        if viewModel.validateAPIKey() {
                                            await viewModel.saveSettings()
                                            withAnimation {
                                                showAPIKeyField = false
                                            }
                                        }
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isSaving {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Text(LLMStrings.saveAPIKey)
                                                .fontWeight(.medium)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(FintechColors.primaryBlue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .disabled(viewModel.apiKey.isEmpty || viewModel.isSaving)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(FintechColors.appBackground)
                        }
                    }

                    FintechDivider()

                    // Backup Mode Toggle
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(FintechColors.warningAmber.opacity(0.15))
                                .frame(width: 32, height: 32)

                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(FintechColors.warningAmber)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LLMStrings.backupModeTitle)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(FintechColors.textPrimary)
                            Text(LLMStrings.backupModeSubtitle)
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                        }

                        Spacer()

                        Toggle("", isOn: $viewModel.useAsBackupOnly)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    FintechDivider()

                    // Privacy Info
                    Button(action: {
                        viewModel.showPrivacyInfo = true
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(FintechColors.primaryBlue.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "shield.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(FintechColors.primaryBlue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(LLMStrings.privacyTitle)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(FintechColors.textPrimary)
                                Text(LLMStrings.privacySubtitle)
                                    .font(.caption)
                                    .foregroundColor(FintechColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .sheet(isPresented: $viewModel.showPrivacyInfo) {
            LLMPrivacyInfoView()
        }
    }

    // MARK: - Computed Properties

    private var apiKeyStatusText: String {
        if viewModel.apiKey.isEmpty {
            return LLMStrings.notConfigured
        } else {
            return LLMStrings.configured
        }
    }

    private var apiKeyStatusColor: Color {
        viewModel.apiKey.isEmpty ? FintechColors.dangerRed : FintechColors.successGreen
    }
}

#Preview {
    LLMSettingsView(viewModel: DIContainer.shared.makeLLMSettingsViewModel())
}
