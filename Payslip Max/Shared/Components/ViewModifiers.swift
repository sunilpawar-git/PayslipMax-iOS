import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
    }
}

struct MilitaryStyle: ViewModifier {
    let rank: String
    
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .rounded))
            .foregroundColor(rankColor)
    }
    
    private var rankColor: Color {
        switch rank.lowercased() {
        case "colonel": return .red
        case "major": return .blue
        default: return .primary
        }
    }
}

struct ProcessingOverlayModifier: ViewModifier {
    let isProcessing: Bool
    let progress: Double
    
    func body(content: Content) -> some View {
        content.overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.3)
                    VStack {
                        ProgressView("Processing Payslip...")
                        ProgressView(value: progress)
                            .padding()
                    }
                    .frame(width: 200, height: 100)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .ignoresSafeArea()
            }
        }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func militaryStyle(rank: String) -> some View {
        modifier(MilitaryStyle(rank: rank))
    }
    
    func withProcessingOverlay(isProcessing: Bool, progress: Double) -> some View {
        modifier(ProcessingOverlayModifier(isProcessing: isProcessing, progress: progress))
    }
} 