//
//  XRayShieldIndicator.swift
//  PayslipMax
//
//  Created by Claude Code on 12/6/24.
//

import SwiftUI

/// Shield badge indicator showing X-Ray feature status
/// - Green shield: Feature is ON
/// - Red shield: Feature is OFF
struct XRayShieldIndicator: View {
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("X-Ray")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? FintechColors.successGreen : FintechColors.dangerRed)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isEnabled ? "X-Ray feature enabled" : "X-Ray feature disabled")
        .accessibilityHint("Tap to toggle X-Ray salary comparison feature")
    }
}

// MARK: - Previews
#Preview("Enabled State") {
    XRayShieldIndicator(isEnabled: true) {
        print("Shield tapped - Enabled")
    }
    .padding()
}

#Preview("Disabled State") {
    XRayShieldIndicator(isEnabled: false) {
        print("Shield tapped - Disabled")
    }
    .padding()
}

#Preview("Both States - Light Mode") {
    VStack(spacing: 20) {
        XRayShieldIndicator(isEnabled: true) {}
        XRayShieldIndicator(isEnabled: false) {}
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Both States - Dark Mode") {
    VStack(spacing: 20) {
        XRayShieldIndicator(isEnabled: true) {}
        XRayShieldIndicator(isEnabled: false) {}
    }
    .padding()
    .preferredColorScheme(.dark)
}
