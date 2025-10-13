import SwiftUI

/// Displays parsing confidence score as a circular badge
/// Shows percentage (0-100%) with color coding
struct ConfidenceBadge: View {
    let confidence: Double // 0.0 to 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(confidenceColor)
                .frame(width: 8, height: 8)
            
            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(confidenceColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(confidenceColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(confidenceColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.9...1.0:
            return .green
        case 0.75..<0.9:
            return .yellow
        case 0.5..<0.75:
            return .orange
        default:
            return .red
        }
    }
}

/// Alternative design: Compact circle badge with just percentage
struct ConfidenceBadgeCompact: View {
    let confidence: Double // 0.0 to 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(confidenceColor.opacity(0.15))
                .frame(width: 44, height: 44)
            
            Circle()
                .stroke(confidenceColor, lineWidth: 2)
                .frame(width: 44, height: 44)
            
            Text("\(Int(confidence * 100))")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(confidenceColor)
        }
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.9...1.0:
            return .green
        case 0.75..<0.9:
            return .yellow
        case 0.5..<0.75:
            return .orange
        default:
            return .red
        }
    }
}

/// Shield-style verification badge (like Twitter/X verified badge)
/// More recognizable and trustworthy for confidence indication
struct ConfidenceBadgeShield: View {
    let confidence: Double // 0.0 to 1.0
    let showPercentage: Bool
    
    init(confidence: Double, showPercentage: Bool = true) {
        self.confidence = confidence
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                // Shield background
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(confidenceColor)
            }
            
            if showPercentage {
                Text("\(Int(confidence * 100))")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(confidenceColor)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(confidenceColor.opacity(0.12))
        )
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.9...1.0:
            return .green
        case 0.75..<0.9:
            return .yellow
        case 0.5..<0.75:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Preview
#Preview("Badge Variants") {
    VStack(spacing: 20) {
        Text("Full Badge")
            .font(.headline)
        
        HStack(spacing: 16) {
            ConfidenceBadge(confidence: 1.0)
            ConfidenceBadge(confidence: 0.85)
            ConfidenceBadge(confidence: 0.65)
            ConfidenceBadge(confidence: 0.3)
        }
        
        Divider()
        
        Text("Compact Circle Badge")
            .font(.headline)
        
        HStack(spacing: 16) {
            ConfidenceBadgeCompact(confidence: 1.0)
            ConfidenceBadgeCompact(confidence: 0.85)
            ConfidenceBadgeCompact(confidence: 0.65)
            ConfidenceBadgeCompact(confidence: 0.3)
        }
        
        Divider()
        
        Text("Shield Badge (NEW)")
            .font(.headline)
        
        VStack(spacing: 12) {
            // With percentage
            HStack(spacing: 16) {
                ConfidenceBadgeShield(confidence: 1.0)
                ConfidenceBadgeShield(confidence: 0.85)
                ConfidenceBadgeShield(confidence: 0.65)
                ConfidenceBadgeShield(confidence: 0.3)
            }
            
            // Without percentage (icon only)
            HStack(spacing: 16) {
                ConfidenceBadgeShield(confidence: 1.0, showPercentage: false)
                ConfidenceBadgeShield(confidence: 0.85, showPercentage: false)
                ConfidenceBadgeShield(confidence: 0.65, showPercentage: false)
                ConfidenceBadgeShield(confidence: 0.3, showPercentage: false)
            }
        }
    }
    .padding()
}

