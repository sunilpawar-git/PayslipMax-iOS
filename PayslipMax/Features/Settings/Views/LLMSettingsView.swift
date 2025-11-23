//
//  LLMSettingsView.swift
//  PayslipMax
//
//  Settings view for AI-powered payslip parsing
//

import SwiftUI

struct LLMSettingsView: View {
    @StateObject private var viewModel: LLMSettingsViewModel

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
                            Text("Google Gemini").tag(LLMProvider.gemini)
                            // OpenAI removed - using Gemini only
                            // Anthropic not yet supported
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    FintechDivider()

                    // Usage Stats
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(FintechColors.successGreen.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(FintechColors.successGreen)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Usage Status")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(FintechColors.textPrimary)
                                Text("\(viewModel.callsThisYear)/\(viewModel.maxCallsPerYear) uses this year")
                                    .font(.caption)
                                    .foregroundColor(FintechColors.textSecondary)
                            }

                            Spacer()

                            // Refresh button
                            Button(action: {
                                Task { await viewModel.refreshUsageStats() }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundColor(FintechColors.primaryBlue)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 6)
                                    .cornerRadius(3)

                                Rectangle()
                                    .fill(viewModel.remainingCallsYearly > 0 ? FintechColors.successGreen : FintechColors.dangerRed)
                                    .frame(width: min(geometry.size.width * (Double(viewModel.callsThisYear) / Double(viewModel.maxCallsPerYear)), geometry.size.width), height: 6)
                                    .cornerRadius(3)
                            }
                        }
                        .frame(height: 6)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                        if viewModel.remainingCallsYearly == 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                Text("Yearly limit reached. Using regex fallback.")
                                    .font(.caption)
                            }
                            .foregroundColor(FintechColors.warningAmber)
                            .padding(.bottom, 12)
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

    // No computed properties needed for now
}

#Preview {
    LLMSettingsView(viewModel: DIContainer.shared.makeLLMSettingsViewModel())
}
