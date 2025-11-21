//
//  LLMPrivacyInfoView.swift
//  PayslipMax
//
//  Privacy information sheet for LLM settings
//

import SwiftUI

struct LLMPrivacyInfoView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LLMStrings.privacyTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(FintechColors.textPrimary)

                        Text(LLMStrings.privacySubtitle)
                            .font(.body)
                            .foregroundColor(FintechColors.textSecondary)
                    }
                    .padding(.top, 8)

                    FintechDivider()

                    // What is sent
                    PrivacySection(
                        icon: "arrow.up.doc.fill",
                        iconColor: FintechColors.primaryBlue,
                        title: LLMStrings.whatIsSentTitle,
                        content: "• Anonymized payslip text\n• Layout structure information\n• No personal identifiers (Name, PAN, etc.) are sent"
                    )

                    // What is NOT sent
                    PrivacySection(
                        icon: "lock.shield.fill",
                        iconColor: FintechColors.successGreen,
                        title: LLMStrings.whatIsNotSentTitle,
                        content: "• Original PDF files\n• Your name, address, or contact info\n• Bank account numbers (masked locally)\n• PAN or Tax IDs (masked locally)"
                    )

                    // How it works
                    PrivacySection(
                        icon: "gearshape.2.fill",
                        iconColor: FintechColors.chartSecondary,
                        title: LLMStrings.howItWorksTitle,
                        content: "1. Your device extracts text from the PDF.\n2. A local algorithm identifies and removes PII.\n3. Only the anonymized text is sent to the AI provider.\n4. The AI returns structured data (Net Pay, Gross Pay, etc.)."
                    )

                    FintechDivider()

                    // Provider Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LLMStrings.providerPrivacyTitle)
                            .font(.headline)
                            .foregroundColor(FintechColors.textPrimary)

                        Text(LLMStrings.providerPrivacyBody)
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 8) {
                            PrivacyLink(title: "OpenAI Privacy Policy", url: "https://openai.com/privacy")
                            PrivacyLink(title: "Google AI Privacy Policy", url: "https://policies.google.com/privacy")
                        }
                    }

                    // Security Note
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "key.icloud.fill")
                            .font(.system(size: 20))
                            .foregroundColor(FintechColors.warningAmber)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(LLMStrings.apiKeySecurityTitle)
                                .font(.headline)
                                .foregroundColor(FintechColors.textPrimary)

                            Text(LLMStrings.apiKeySecurityBody)
                                .font(.caption)
                                .foregroundColor(FintechColors.textSecondary)
                        }
                    }
                    .padding()
                    .background(FintechColors.warningAmber.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(20)
            }
            .background(FintechColors.appBackground)
            .navigationTitle(LLMStrings.privacySheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PrivacySection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)

                Text(content)
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
        }
    }
}

struct PrivacyLink: View {
    let title: String
    let url: String

    var body: some View {
        if let linkUrl = URL(string: url) {
            Link(destination: linkUrl) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.primaryBlue)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(FintechColors.primaryBlue)
                }
                .padding(12)
                .background(FintechColors.secondaryBackground)
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    LLMPrivacyInfoView()
}
