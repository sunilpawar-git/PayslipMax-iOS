import SwiftUI
import PDFKit

/// View for managing extraction patterns
struct PatternManagementView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = PatternManagementViewModel()
    @State private var showingAddPatternSheet = false
    @State private var selectedPatternForEdit: PatternDefinition?
    @State private var searchText = ""
    @State private var selectedCategory: PatternCategory?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack {
                // Filter options
                filterBar
                
                // Pattern list
                List {
                    ForEach(filteredPatterns, id: \.key) { pattern in
                        PatternListItem(pattern: pattern)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPatternForEdit = pattern
                            }
                            .swipeActions {
                                // Only user-defined patterns can be deleted
                                if !pattern.isCore {
                                    Button(role: .destructive) {
                                        viewModel.deletePattern(pattern)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.patterns.isEmpty {
                        ContentUnavailableView(
                            "No Patterns",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Patterns help extract data from your payslips.")
                        )
                    } else if filteredPatterns.isEmpty {
                        ContentUnavailableView.search
                    }
                }
                .refreshable {
                    Task { await viewModel.loadPatterns() }
                }
            }
            .navigationTitle("Extraction Patterns")
            .searchable(text: $searchText, prompt: "Search patterns")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Section("Import/Export") {
                            Button {
                                viewModel.exportPatterns()
                            } label: {
                                Label("Export Patterns", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                viewModel.importPatterns()
                            } label: {
                                Label("Import Patterns", systemImage: "square.and.arrow.down")
                            }
                        }
                        
                        Section("Reset") {
                            Button(role: .destructive) {
                                viewModel.showResetConfirmation = true
                            } label: {
                                Label("Reset to Default", systemImage: "arrow.counterclockwise")
                            }
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPatternSheet = true
                    } label: {
                        Label("Add Pattern", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPatternSheet) {
                PatternEditView(isNewPattern: true)
            }
            .sheet(item: $selectedPatternForEdit) { pattern in
                PatternEditView(pattern: pattern, isNewPattern: false)
            }
            .alert("Reset to Default Patterns", isPresented: $viewModel.showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetToDefaultPatterns()
                }
            } message: {
                Text("This will remove all your custom patterns. This action cannot be undone.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .fileExporter(
                isPresented: $viewModel.isExporting,
                document: viewModel.exportedPatterns,
                contentType: .json,
                defaultFilename: "patterns"
            ) { result in
                switch result {
                case .success(let url):
                    viewModel.exportSuccessMessage = "Patterns exported to \(url.lastPathComponent)"
                    viewModel.showExportSuccess = true
                case .failure(let error):
                    viewModel.errorMessage = "Export failed: \(error.localizedDescription)"
                    viewModel.showError = true
                }
            }
            .fileImporter(
                isPresented: $viewModel.isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleImportResult(result)
            }
            .alert("Export Success", isPresented: $viewModel.showExportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.exportSuccessMessage)
            }
            .task { await viewModel.loadPatterns() }
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                categoryFilterButton(nil, "All")
                
                ForEach(PatternCategory.allCases, id: \.self) { category in
                    categoryFilterButton(category, category.displayName)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private func categoryFilterButton(_ category: PatternCategory?, _ title: String) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(selectedCategory == category ? Color.accentColor : Color.gray.opacity(0.2))
                )
                .foregroundColor(selectedCategory == category ? .white : .primary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredPatterns: [PatternDefinition] {
        viewModel.patterns.filter { pattern in
            let matchesSearch = searchText.isEmpty || 
                pattern.name.localizedCaseInsensitiveContains(searchText) ||
                pattern.key.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || pattern.category == selectedCategory
            
            return matchesSearch && matchesCategory
        }
    }
}

/// Individual list item for a pattern
struct PatternListItem: View {
    let pattern: PatternDefinition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pattern.name)
                    .font(.headline)
                
                Spacer()
                
                if pattern.isCore {
                    Text("System")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                        )
                } else {
                    Text("Custom")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.2))
                        )
                }
            }
            
            Text("Key: \(pattern.key)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Category: \(pattern.category.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Patterns: \(pattern.patterns.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
 
struct PatternManagementView_Previews: PreviewProvider {
    static var previews: some View {
        PatternManagementView()
    }
} 