import SwiftUI

// MARK: - Settings Components Library

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textSecondary)
                .padding(.horizontal)
            
            content
                .fintechCardStyle()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                        .accessibilityIdentifier("settings_row_title_\(title)")
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                    }
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
        .accessibilityIdentifier("settings_row_button_\(title)")
    }
}

struct ToggleSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    let onChange: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Content - Fixed text wrapping and truncation
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .multilineTextAlignment(.leading)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 8)
            
            Toggle("", isOn: $isOn)
                .onChange(of: isOn) { oldValue, newValue in
                    onChange(newValue)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Content
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(FintechColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(FintechColors.textSecondary)
        }
        .padding()
    }
}

struct FintechDivider: View {
    var body: some View {
        Rectangle()
            .fill(FintechColors.divider)
            .frame(height: 1)
            .padding(.horizontal)
    }
}

#Preview {
    VStack {
        SettingsSection(title: "TEST SECTION") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "gear",
                    iconColor: .blue,
                    title: "Test Setting",
                    subtitle: "This is a test",
                    action: {}
                )
                
                FintechDivider()
                
                SettingsInfoRow(
                    icon: "info.circle",
                    iconColor: .gray,
                    title: "Version",
                    value: "1.0.0"
                )
            }
        }
    }
    .padding()
} 