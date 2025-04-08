import SwiftUI

/// A view that displays a countdown to the next payslip
struct PayslipCountdownView: View {
    @State private var daysRemaining: Int = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 26)
                
                Text("Days till Next Payslip")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            Spacer(minLength: 32)
            
            Text("\(daysRemaining) Days")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.5, blue: 1.0),
                            Color(red: 0.3, green: 0.6, blue: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            updateDaysRemaining()
        }
    }
    
    private func updateDaysRemaining() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the current month's last day
        guard let lastDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: now))),
              let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: lastDayOfMonth) else {
            return
        }
        
        // Calculate days remaining
        if let days = calendar.dateComponents([.day], from: now, to: lastDay).day {
            daysRemaining = max(days + 1, 0) // Add 1 to include the current day
        }
        
        // Set up a timer to update daily
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in // 86400 seconds = 24 hours
            updateDaysRemaining()
        }
    }
}

#Preview {
    PayslipCountdownView()
} 