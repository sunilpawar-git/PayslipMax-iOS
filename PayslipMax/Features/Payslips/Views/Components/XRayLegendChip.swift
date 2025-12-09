import SwiftUI

/// Compact chip that toggles the X-Ray legend popover.
struct XRayLegendChip: View {
    @Binding var isShowingLegend: Bool
    @Binding var anchor: CGRect

    var body: some View {
        Button {
            isShowingLegend.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(FintechColors.textPrimary)
                .padding(8) // hit target without visible chrome
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show X-Ray legend")
        .accessibilityHint("Opens a popover explaining colors and arrows")
    }
}

