import SwiftUI
import Foundation

// MARK: - Tip Interaction Panel

struct TipInteractionPanel: View {
    let tipId: UUID
    @Binding var isFavorited: Bool
    @Binding var userReaction: TipReaction?
    let reactions: [TipReaction: Int]
    let quickActions: [QuickAction]
    let onReactionTapped: ((TipReaction) -> Void)?
    let onFavoriteToggled: (() -> Void)?
    let onQuickActionTapped: ((QuickAction) -> Void)?
    let onShareTapped: (() -> Void)?
    
    @State private var showingReactions = false
    @State private var animateReaction = false
    @State private var selectedQuickAction: QuickAction?
    
    var body: some View {
        VStack(spacing: 16) {
            // Reaction Section
            reactionSection
            
            // Divider
            if !quickActions.isEmpty {
                Divider()
                    .opacity(0.5)
            }
            
            // Quick Actions Section
            if !quickActions.isEmpty {
                quickActionsSection
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Reaction Section
    
    private var reactionSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Was this helpful?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Favorite Button
                favoriteButton
            }
            
            // Reaction Buttons
            reactionButtons
            
            // Reaction Stats (if any reactions exist)
            if !reactions.isEmpty && reactions.values.contains(where: { $0 > 0 }) {
                reactionStats
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Quick Actions")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Share Button
                shareButton
            }
            
            // Action Buttons Grid
            actionButtonsGrid
        }
    }
    
    // MARK: - UI Components
    
    private var favoriteButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                onFavoriteToggled?()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isFavorited ? .red : .gray)
                    .scaleEffect(isFavorited ? 1.1 : 1.0)
                
                Text(isFavorited ? "Saved" : "Save")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isFavorited ? .red : .gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isFavorited ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
            .clipShape(Capsule())
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFavorited)
    }
    
    private var shareButton: some View {
        Button(action: {
            onShareTapped?()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Share")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    private var reactionButtons: some View {
        HStack(spacing: 20) {
            ForEach([TipReaction.helpful, .love, .insightful], id: \.self) { reaction in
                reactionButton(for: reaction)
            }
            
            Spacer()
        }
    }
    
    private func reactionButton(for reaction: TipReaction) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateReaction = true
                let newReaction = userReaction == reaction ? nil : reaction
                userReaction = newReaction
                onReactionTapped?(reaction)
            }
            
            // Reset animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animateReaction = false
                }
            }
        }) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: reaction.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(userReaction == reaction ? reaction.activeColor : .gray)
                    
                    Text(reaction.emoji)
                        .font(.system(size: 16))
                }
                .scaleEffect(userReaction == reaction ? (animateReaction ? 1.3 : 1.15) : 1.0)
                
                Text(reaction.description)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(userReaction == reaction ? reaction.activeColor : .gray)
                
                // Reaction count
                if let count = reactions[reaction], count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: userReaction)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateReaction)
    }
    
    private var reactionStats: some View {
        HStack(spacing: 16) {
            ForEach(reactions.sorted(by: { $0.value > $1.value }), id: \.key) { reaction, count in
                if count > 0 {
                    HStack(spacing: 4) {
                        Text(reaction.emoji)
                            .font(.caption)
                        
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    private var actionButtonsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(quickActions.count, 3)), spacing: 12) {
            ForEach(quickActions.prefix(6), id: \.id) { action in
                quickActionButton(for: action)
            }
        }
    }
    
    private func quickActionButton(for action: QuickAction) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedQuickAction = action
            }
            
            onQuickActionTapped?(action)
            
            // Reset selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                selectedQuickAction = nil
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: action.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                    .scaleEffect(selectedQuickAction?.id == action.id ? 1.2 : 1.0)
                
                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedQuickAction?.id == action.id ? Color.blue.opacity(0.15) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedQuickAction?.id == action.id ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedQuickAction?.id)
    }
}

// MARK: - Supporting Models

// Note: TipReaction enum is now defined in SharedTypes.swift

struct QuickAction: Identifiable, Codable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let actionType: ActionType
    
    enum ActionType: String, Codable {
        case calculate, remind, bookmark, share, learn, track
    }
    
    static let defaultActions = [
        QuickAction(title: "Calculate", description: "Use related calculator", iconName: "function", actionType: .calculate),
        QuickAction(title: "Remind Me", description: "Set a reminder", iconName: "bell", actionType: .remind),
        QuickAction(title: "Learn More", description: "Get detailed info", iconName: "book", actionType: .learn)
    ]
}

// MARK: - Preview

struct TipInteractionPanel_Previews: PreviewProvider {
    @State static var isFavorited = false
    @State static var userReaction: TipReaction? = nil
    
    static var previews: some View {
        VStack(spacing: 20) {
            // Default state
            TipInteractionPanel(
                tipId: UUID(),
                isFavorited: .constant(false),
                userReaction: .constant(nil),
                reactions: [.helpful: 12, .love: 5, .insightful: 8],
                quickActions: QuickAction.defaultActions,
                onReactionTapped: { reaction in print("Reaction: \(reaction)") },
                onFavoriteToggled: { print("Favorite toggled") },
                onQuickActionTapped: { action in print("Action: \(action.title)") },
                onShareTapped: { print("Share tapped") }
            )
            
            // Interactive preview
            TipInteractionPanel(
                tipId: UUID(),
                isFavorited: $isFavorited,
                userReaction: $userReaction,
                reactions: [.helpful: 5, .love: 2, .insightful: 3],
                quickActions: QuickAction.defaultActions,
                onReactionTapped: { reaction in 
                    userReaction = userReaction == reaction ? nil : reaction
                },
                onFavoriteToggled: { 
                    isFavorited.toggle()
                },
                onQuickActionTapped: { action in print("Action: \(action.title)") },
                onShareTapped: { print("Share tapped") }
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 