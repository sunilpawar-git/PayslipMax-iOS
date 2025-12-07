import SwiftUI

/// Compact chip that toggles the X-Ray legend popover.
struct XRayLegendChip: View {
    @Binding var isShowingLegend: Bool

    var body: some View {
        Button {
            isShowingLegend.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .medium))
                Text("X-Ray legend")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(FintechColors.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(FintechColors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show X-Ray legend")
        .accessibilityHint("Opens a popover explaining colors and arrows")
        .popover(isPresented: $isShowingLegend, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            XRayLegendRow()
                .padding(14)
                .frame(maxWidth: 280, alignment: .leading)
                .presentationCompactAdaptation(.popover)
        }
    }
}

