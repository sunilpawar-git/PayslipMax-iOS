import SwiftUI

// MARK: - World-Class Investment Tips View

struct InvestmentTipsView: View {
    @State private var selectedCategory: TipCategory = .beginner
    @State private var tips: [InvestmentTip] = InvestmentTip.worldClassSampleTips
    @State private var isExpanded = false
    @State private var searchText = ""
    @State private var showingTipDetail = false
    @State private var selectedTip: InvestmentTip?
    @State private var userReactions: [UUID: TipReaction] = [:]
    @State private var bookmarkedTips: Set<UUID> = []
    @State private var tipSteak = 7 // User's current learning streak
    
    var filteredTips: [InvestmentTip] {
        tips.filter { tip in
            let matchesCategory = selectedCategory == .beginner || tip.category == selectedCategory
            let matchesSearch = searchText.isEmpty || 
                tip.title.localizedCaseInsensitiveContains(searchText) ||
                tip.shortDescription.localizedCaseInsensitiveContains(searchText) ||
                tip.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with streak and search
            headerSection
            
            // Category filter
            categoryFilterSection
            
            // Tips content
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(filteredTips.indices, id: \.self) { index in
                        let tip = filteredTips[index]
                        
                        WorldClassTipCard(
                            tip: tip,
                            userReaction: userReactions[tip.id],
                            isBookmarked: bookmarkedTips.contains(tip.id),
                            onReaction: { reaction in
                                handleReaction(tip: tip, reaction: reaction)
                            },
                            onBookmark: {
                                handleBookmark(tip: tip)
                            },
                            onTap: {
                                selectedTip = tip
                                showingTipDetail = true
                            }
                        )
                        .padding(.horizontal, 16)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: filteredTips.count)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 100) // Safe area padding
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingTipDetail) {
            if let tip = selectedTip {
                TipDetailView(tip: tip)
            }
        }
        .onAppear {
            // Animate tips in on appear
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                isExpanded = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("💡 Investment Tips")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Grow your wealth with expert insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Streak badge
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .scaleEffect(tipSteak > 5 ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true), value: tipSteak)
                    
                    Text("\(tipSteak)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search tips...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Category Filter Section
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TipCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Actions
    
    private func handleReaction(tip: InvestmentTip, reaction: TipReaction) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if userReactions[tip.id] == reaction {
                userReactions[tip.id] = nil
            } else {
                userReactions[tip.id] = reaction
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func handleBookmark(tip: InvestmentTip) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if bookmarkedTips.contains(tip.id) {
                bookmarkedTips.remove(tip.id)
            } else {
                bookmarkedTips.insert(tip.id)
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - World-Class Tip Card

struct WorldClassTipCard: View {
    let tip: InvestmentTip
    let userReaction: TipReaction?
    let isBookmarked: Bool
    let onReaction: (TipReaction) -> Void
    let onBookmark: () -> Void
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with category and difficulty
            HStack {
                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: tip.category.icon)
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text(tip.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(tip.category.color)
                .clipShape(Capsule())
                
                Spacer()
                
                // Difficulty and trending indicators
                HStack(spacing: 8) {
                    if tip.isTrending {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Trending")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    if tip.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("Premium")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            
            // Title and description
            VStack(alignment: .leading, spacing: 8) {
                Text(tip.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(tip.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Metadata row
            HStack {
                // Read time
                Label(tip.formattedReadTime, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Rating
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(index < Int(tip.rating) ? .yellow : .gray.opacity(0.3))
                    }
                    
                    Text(String(format: "%.1f", tip.rating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // View count
                if tip.viewCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.caption)
                        Text("\(tip.viewCount)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // Action buttons
            HStack(spacing: 16) {
                // Reactions
                HStack(spacing: 12) {
                    ForEach([TipReaction.helpful, .love, .insightful], id: \.self) { reaction in
                        Button(action: { onReaction(reaction) }) {
                            HStack(spacing: 4) {
                                Text(reaction.emoji)
                                    .font(.system(size: 16))
                                
                                if userReaction == reaction {
                                    Text(reaction.title)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(reaction.color)
                                }
                            }
                            .scaleEffect(userReaction == reaction ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: userReaction == reaction)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
                
                // Bookmark button
                Button(action: onBookmark) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isBookmarked ? .blue : .secondary)
                        .scaleEffect(isBookmarked ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isBookmarked)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let category: TipCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? category.color : Color(.systemGray6))
            .clipShape(Capsule())
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tip Detail View

struct TipDetailView: View {
    let tip: InvestmentTip
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tip.category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(tip.category.color)
                                
                                Text(tip.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: tip.knowledgeImpact.icon)
                                        .font(.caption)
                                        .foregroundColor(tip.knowledgeImpact.color)
                                    
                                    Text(tip.knowledgeImpact.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(tip.knowledgeImpact.color)
                                }
                                
                                Text(tip.formattedReadTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Content
                    Text(tip.fullContent)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundColor(.primary)
                    
                    // Action items
                    if !tip.actionItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("🎯 Take Action")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            ForEach(tip.actionItems, id: \.id) { actionItem in
                                ActionItemRow(actionItem: actionItem)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // Tags
                    if !tip.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            TagCloud(tags: tip.tags)
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ActionItemRow: View {
    let actionItem: InvestmentActionItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: actionItem.actionType.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(actionItem.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(actionItem.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TagCloud: View {
    let tags: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80), spacing: 8)
        ], spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Preview

struct InvestmentTipsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InvestmentTipsView()
        }
    }
}
