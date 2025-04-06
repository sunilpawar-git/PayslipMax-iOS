import SwiftUI
import Foundation

// Removed the duplicate AppTheme enum
// We'll use the one from SettingsViewModel

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTheme: AppTheme
    @State private var tempSelection: AppTheme
    
    init(selectedTheme: Binding<AppTheme>) {
        self._selectedTheme = selectedTheme
        self._tempSelection = State(initialValue: selectedTheme.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(AppTheme.allCases) { theme in
                    HStack {
                        Image(systemName: theme.systemImage)
                            .font(.title3)
                            .frame(width: 30)
                            .foregroundColor(themeColor(for: theme))
                        
                        Text(theme.rawValue)
                            .padding(.leading, 8)
                        
                        Spacer()
                        
                        if tempSelection == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tempSelection = theme
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("App Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedTheme = tempSelection
                        applyTheme(tempSelection)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
    
    private func themeColor(for theme: AppTheme) -> Color {
        switch theme {
        case .system:
            return .primary
        case .light:
            return .yellow
        case .dark:
            return .indigo
        }
    }
    
    private func applyTheme(_ theme: AppTheme) {
        // In a real app, this would apply the theme to the app
        // Here, we're relying on the AppStorage to do that automatically
        // You could add additional theme-related logic here if needed
    }
}

struct ThemePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ThemePickerView(selectedTheme: .constant(.system))
    }
} 