import SwiftUI

// MARK: - Tip Category Filter

struct TipCategoryFilter: View {
    @Binding var selectedCategoryIndex: Int
    let onCategorySelected: ((Int) -> Void)?
    
    @State private var scrollProxy: Any? = nil
    @State private var animateSelection = false
    
    private let categories = [
        "All", "Getting Started", "Building Wealth", "Tax Smart", 
        "Safety First", "Future Planning", "Investor Mindset", "Market Insights"
    ]
    
    private let categoryIcons = [
        "list.bullet", "graduationcap", "chart.line.uptrend.xyaxis", "percent",
        "shield.checkered", "calendar.badge.clock", "brain", "flame"
    ]
    
    private let categoryColors: [Color] = [
        .gray, .green, .blue, .orange,
        .red, .indigo, .pink, .yellow
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            headerSection
            
            // Category Pills
            categoryScrollView
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Text("Categories")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if selectedCategoryIndex > 0 {
                Button(action: {
                    selectCategory(0)
                }) {
                    HStack(spacing: 4) {
                        Text("Clear")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedCategoryIndex)
    }
    
    // MARK: - Category Scroll View
    
    private var categoryScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories.indices, id: \.self) { index in
                        categoryPill(at: index)
                            .id(index)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
                         .onAppear {
                // Store proxy for potential use
            }
        }
    }
    
    // MARK: - Category Pills
    
    private func categoryPill(at index: Int) -> some View {
        Button(action: {
            selectCategory(index)
        }) {
            HStack(spacing: 8) {
                // Icon
                Image(systemName: categoryIcons[safe: index] ?? "list.bullet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(pillForegroundColor(for: index))
                    .scaleEffect(selectedCategoryIndex == index && animateSelection ? 1.2 : 1.0)
                
                // Text
                Text(categories[safe: index] ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(pillForegroundColor(for: index))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(pillBackground(for: index))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(pillBorderColor(for: index), lineWidth: pillBorderWidth(for: index))
            )
            .scaleEffect(selectedCategoryIndex == index ? 1.05 : 1.0)
            .shadow(
                color: selectedCategoryIndex == index ? categoryColors[safe: index]?.opacity(0.3) ?? Color.clear : Color.clear,
                radius: selectedCategoryIndex == index ? 8 : 0,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(CategoryPillButtonStyle())
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedCategoryIndex)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateSelection)
    }
    
    // MARK: - Styling Helpers
    
    private func pillBackground(for index: Int) -> some View {
        Group {
            if selectedCategoryIndex == index {
                RoundedRectangle(cornerRadius: 20)
                    .fill(categoryColors[safe: index]?.opacity(0.1) ?? Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        categoryColors[safe: index]?.opacity(0.1) ?? Color.clear,
                                        categoryColors[safe: index]?.opacity(0.05) ?? Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            }
        }
    }
    
    private func pillForegroundColor(for index: Int) -> Color {
        if selectedCategoryIndex == index {
            return categoryColors[safe: index] ?? .primary
        } else {
            return .secondary
        }
    }
    
    private func pillBorderColor(for index: Int) -> Color {
        if selectedCategoryIndex == index {
            return categoryColors[safe: index]?.opacity(0.3) ?? Color.clear
        } else {
            return Color.clear
        }
    }
    
    private func pillBorderWidth(for index: Int) -> CGFloat {
        selectedCategoryIndex == index ? 1 : 0
    }
    
    // MARK: - Methods
    
    private func selectCategory(_ index: Int) {
        // Animate selection
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            animateSelection = true
        }
        
        // Update selection
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            selectedCategoryIndex = index
        }
        
                 // Scroll to selected category if needed - simplified for now
        // TODO: Implement proper scroll positioning
        
        // Reset animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateSelection = false
            }
        }
        
        // Trigger callback
        onCategorySelected?(index)
        
                 // Haptic feedback - simplified for now
        // TODO: Add proper haptic feedback
    }
}

// MARK: - Custom Button Style

struct CategoryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Array Extension (if not already defined elsewhere)
// Note: This extension might already exist in the project

// MARK: - Preview

struct TipCategoryFilter_Previews: PreviewProvider {
    @State static var selectedIndex = 0
    
    static var previews: some View {
        VStack(spacing: 30) {
            // Default state
            TipCategoryFilter(
                selectedCategoryIndex: .constant(0),
                onCategorySelected: { index in
                    print("Selected category: \(index)")
                }
            )
            
            // Selected state
            TipCategoryFilter(
                selectedCategoryIndex: .constant(2),
                onCategorySelected: { index in
                    print("Selected category: \(index)")
                }
            )
            
            // Interactive preview
            VStack(spacing: 16) {
                Text("Interactive Filter")
                    .font(.headline)
                
                TipCategoryFilter(
                    selectedCategoryIndex: $selectedIndex,
                    onCategorySelected: { index in
                        selectedIndex = index
                    }
                )
                
                Text("Selected: \(selectedIndex)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 