import SwiftUI

/// Helper views and styles for the GamificationIntegrationView
/// This file contains reusable UI components and styles extracted for better organization
/// Each helper follows SOLID principles and maintains clean separation of concerns

// MARK: - Compact Button Styles

/// Primary button style for compact quiz action buttons
struct CompactPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(FintechColors.primaryBlue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button style for compact quiz action buttons
struct CompactSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(FintechColors.primaryBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(FintechColors.primaryBlue.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
