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
                enableToggleRow
                if viewModel.isLLMEnabled {
                    FintechDivider()
                    providerPickerRow
                    FintechDivider()
                    usageStatsSection
                    FintechDivider()
                    backupModeToggleRow
                    FintechDivider()
                    privacyInfoButton
                }
            }
        }
        .sheet(isPresented: $viewModel.showPrivacyInfo) {
            LLMPrivacyInfoView()
        }
    }

    private var enableToggleRow: some View {
        HStack(spacing: 12) {
            settingsIcon("sparkles", color: FintechColors.chartSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(LLMStrings.enableTitle).font(.body).fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                Text(LLMStrings.enableSubtitle).font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $viewModel.isLLMEnabled)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var providerPickerRow: some View {
        HStack(spacing: 16) {
            settingsIcon("cloud.fill", color: FintechColors.primaryBlue)
            Text(LLMStrings.providerTitle).font(.body).fontWeight(.medium)
                .foregroundColor(FintechColors.textPrimary)
            Spacer()
            Picker("Provider", selection: $viewModel.selectedProvider) {
                Text("Google Gemini").tag(LLMProvider.gemini)
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var usageStatsSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                settingsIcon("chart.bar.fill", color: FintechColors.successGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Usage Status").font(.body).fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                    Text("\(viewModel.callsThisYear)/\(viewModel.maxCallsPerYear) uses this year")
                        .font(.caption).foregroundColor(FintechColors.textSecondary)
                }
                Spacer()
                Button(action: { Task { await viewModel.refreshUsageStats() } }) {
                    Image(systemName: "arrow.clockwise").font(.caption)
                        .foregroundColor(FintechColors.primaryBlue)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            usageProgressBar
        }
    }

    private var usageProgressBar: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 6).cornerRadius(3)
                    Rectangle()
                        .fill(viewModel.remainingCallsYearly > 0 ? FintechColors.successGreen : FintechColors.dangerRed)
                        .frame(
                            width: min(
                                geometry.size.width * (Double(viewModel.callsThisYear) / Double(viewModel.maxCallsPerYear)),
                                geometry.size.width
                            ),
                            height: 6
                        )
                        .cornerRadius(3)
                }
            }
            .frame(height: 6).padding(.horizontal, 16).padding(.bottom, 16)
            if viewModel.remainingCallsYearly == 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.caption)
                    Text("Yearly limit reached. Using regex fallback.").font(.caption)
                }
                .foregroundColor(FintechColors.warningAmber).padding(.bottom, 12)
            }
        }
    }

    private var backupModeToggleRow: some View {
        HStack(spacing: 12) {
            settingsIcon("arrow.triangle.2.circlepath", color: FintechColors.warningAmber)
            VStack(alignment: .leading, spacing: 2) {
                Text(LLMStrings.backupModeTitle).font(.body).fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                Text(LLMStrings.backupModeSubtitle).font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $viewModel.useAsBackupOnly)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var privacyInfoButton: some View {
        Button(action: { viewModel.showPrivacyInfo = true }) {
            HStack(spacing: 12) {
                settingsIcon("shield.fill", color: FintechColors.primaryBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LLMStrings.privacyTitle).font(.body).fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                    Text(LLMStrings.privacySubtitle).font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func settingsIcon(_ systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)).frame(width: 32, height: 32)
            Image(systemName: systemName).font(.system(size: 16, weight: .medium)).foregroundColor(color)
        }
    }

    // MARK: - Computed Properties

    // No computed properties needed for now
}

#Preview {
    LLMSettingsView(viewModel: DIContainer.shared.makeLLMSettingsViewModel())
}
