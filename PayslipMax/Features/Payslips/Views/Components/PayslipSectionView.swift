import SwiftUI

struct PayslipSectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            content
                .padding()
                .background(FintechColors.backgroundGray)
                .cornerRadius(10)
                .shadow(color: FintechColors.shadow, radius: 5, x: 0, y: 2)
        }
    }
} 