# Ideal Navigation Architecture for PayslipMax

## Current Problem: Technical Debt
- 4 navigation systems competing
- Environment object confusion
- Developer friction on every new screen
- Bug-prone navigation state management

## Proposed Solution: Single Unified Coordinator

### Core Principles
1. **Single Source of Truth**: One NavigationCoordinator class
2. **SwiftUI-Native**: Leverage NavigationStack + TabView properly  
3. **Simple State**: Minimal @Published properties
4. **Type-Safe**: Single destination enum
5. **Testable**: Clear interfaces and mock support

### Architecture

```swift
// Single Destination Enum (merge current dual enums)
enum Destination: Identifiable, Hashable {
    // Tab roots
    case homeTab, payslipsTab, insightsTab, settingsTab
    
    // Push destinations
    case payslipDetail(id: UUID)
    case webUploads
    
    // Modal destinations  
    case addPayslip, scanner, privacyPolicy, pdfPreview(PDFDocument)
}

// Single Navigation Coordinator
@MainActor
class NavigationCoordinator: ObservableObject {
    // Tab state
    @Published var selectedTab: Int = 0
    
    // Navigation stacks (one per tab)
    @Published var homeStack = NavigationPath()
    @Published var payslipsStack = NavigationPath()
    @Published var insightsStack = NavigationPath()
    @Published var settingsStack = NavigationPath()
    
    // Modal state
    @Published var sheet: Destination?
    @Published var fullScreenCover: Destination?
    
    // Current stack (computed)
    var currentStack: Binding<NavigationPath> {
        switch selectedTab {
        case 0: return $homeStack
        case 1: return $payslipsStack  
        case 2: return $insightsStack
        case 3: return $settingsStack
        default: return $homeStack
        }
    }
    
    // MARK: - Navigation Methods
    func navigate(to destination: Destination) {
        currentStack.wrappedValue.append(destination)
    }
    
    func switchTab(to index: Int, destination: Destination? = nil) {
        selectedTab = index
        if let dest = destination { navigate(to: dest) }
    }
    
    func presentSheet(_ destination: Destination) {
        sheet = destination
    }
    
    func presentFullScreen(_ destination: Destination) {
        fullScreenCover = destination
    }
    
    // MARK: - Deep Link Support
    func handle(deepLink url: URL) -> Bool {
        // Parse URL and navigate appropriately
        // Single place for all deep link logic
    }
}
```

### View Structure

```swift
// Main App View (simplified)
struct MainAppView: View {
    @StateObject private var coordinator = NavigationCoordinator()
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ForEach(0..<4, id: \.self) { tabIndex in
                NavigationStack(path: coordinator.currentStack) {
                    tabRootView(for: tabIndex)
                        .navigationDestination(for: Destination.self) { destination in
                            ViewFactory.makeView(for: destination)
                        }
                }
                .tabItem { tabItem(for: tabIndex) }
                .tag(tabIndex)
            }
        }
        .sheet(item: $coordinator.sheet) { destination in
            ViewFactory.makeModalView(for: destination) {
                coordinator.dismissSheet()
            }
        }
        .fullScreenCover(item: $coordinator.fullScreenCover) { destination in
            ViewFactory.makeModalView(for: destination) {
                coordinator.dismissFullScreen()
            }
        }
        .environmentObject(coordinator)
        .onOpenURL { url in
            _ = coordinator.handle(deepLink: url)
        }
    }
}
```

### Benefits
1. **Single Environment Object**: Every view gets `@EnvironmentObject var coordinator: NavigationCoordinator`
2. **Type Safety**: Compiler catches navigation errors
3. **Testability**: Mock coordinator for tests
4. **Performance**: Single state object, efficient updates
5. **Maintainability**: One place to change navigation logic
6. **Deep Links**: Centralized URL handling
7. **SwiftUI Native**: Works with SwiftUI's navigation system, not against it

### Migration Strategy
1. **Phase 1**: Implement new NavigationCoordinator alongside existing systems
2. **Phase 2**: Migrate one feature at a time to new coordinator
3. **Phase 3**: Remove old navigation systems (AppCoordinator, NavRouter, etc.)
4. **Phase 4**: Clean up converters and bridge code

### Testing Strategy
```swift
class MockNavigationCoordinator: NavigationCoordinator {
    var lastNavigation: Destination?
    var lastTabSwitch: Int?
    
    override func navigate(to destination: Destination) {
        lastNavigation = destination
        super.navigate(to: destination)
    }
    
    override func switchTab(to index: Int, destination: Destination? = nil) {
        lastTabSwitch = index
        super.switchTab(to: index, destination: destination)
    }
}
```

## Implementation Priority

### High Priority (Fix Immediately)
1. Settings navigation confusion (causing privacy policy bug)
2. Environment object chain breaks in nested NavigationViews

### Medium Priority (Next Sprint)  
1. Unify destination enums
2. Create single NavigationCoordinator
3. Migrate Settings tab to new system

### Low Priority (Future Cleanup)
1. Remove old navigation systems
2. Update all views to use new coordinator
3. Clean up bridge code and converters

## Developer Guidelines

### DO
- Use single `@EnvironmentObject var coordinator: NavigationCoordinator`
- Navigate with `coordinator.navigate(to: .destination)`
- Present modals with `coordinator.presentSheet(.destination)`

### DON'T  
- Create NavigationView inside views (use NavigationStack at app level)
- Mix navigation systems in same feature
- Store navigation state in ViewModels

### Code Review Checklist
- [ ] Uses NavigationCoordinator for navigation
- [ ] No NavigationView creation in child views
- [ ] Proper environment object usage
- [ ] Navigation state not duplicated in ViewModels 