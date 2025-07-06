#!/usr/bin/swift

import Foundation

struct TestCoverageAnalyzer {
    static func main() {
        print("🧪 PayslipMax Test Coverage Analysis")
        print("=" * 50)
        
        analyzeOverallCoverage()
        analyzeServiceCoverage()
        analyzeViewModelCoverage()
        analyzeFeatureCoverage()
        provideCoverageRecommendations()
    }
    
    static func analyzeOverallCoverage() {
        print("\n📊 Overall Project Statistics:")
        
        let sourceFiles = countSwiftFiles(in: "PayslipMax", excluding: ["Examples", "TestHelpers"])
        let testFiles = countSwiftFiles(in: "PayslipMaxTests")
        let uiTestFiles = countSwiftFiles(in: "PayslipMaxUITests")
        
        let testRatio = Double(testFiles) / Double(sourceFiles)
        
        print("• Source files: \(sourceFiles)")
        print("• Unit test files: \(testFiles)")
        print("• UI test files: \(uiTestFiles)")
        print("• Test-to-source ratio: \(String(format: "%.2f", testRatio)) (Target: 0.3+)")
        
        if testRatio < 0.25 {
            print("⚠️  Test coverage appears LOW - need more tests")
        } else if testRatio < 0.35 {
            print("⚡ Test coverage is MODERATE - room for improvement")
        } else {
            print("✅ Test coverage looks GOOD")
        }
    }
    
    static func analyzeServiceCoverage() {
        print("\n🔧 Services Coverage Analysis:")
        
        let serviceFiles = findFiles(pattern: "PayslipMax/Services/**/*.swift")
        let serviceTestFiles = findFiles(pattern: "PayslipMaxTests/Services/**/*.swift")
        
        print("• Service files: \(serviceFiles.count)")
        print("• Service test files: \(serviceTestFiles.count)")
        
        // Key services that should have comprehensive tests
        let criticalServices = [
            "PDFProcessingService",
            "PayslipParserService", 
            "PatternMatchingService",
            "DataServiceImpl",
            "EncryptionService",
            "SecurityService",
            "ExtractionService"
        ]
        
        print("\n🎯 Critical Services Test Status:")
        for service in criticalServices {
            let hasSourceFile = fileExists("PayslipMax/Services/\(service).swift") || 
                              findFiles(pattern: "PayslipMax/Services/**/*\(service)*.swift").count > 0
            let hasTestFile = findFiles(pattern: "PayslipMaxTests/**/*\(service)*Tests.swift").count > 0
            
            let status = hasTestFile ? "✅" : "❌"
            let sourceStatus = hasSourceFile ? "📁" : "❓"
            print("  \(status) \(sourceStatus) \(service)")
        }
    }
    
    static func analyzeViewModelCoverage() {
        print("\n🎭 ViewModels Coverage Analysis:")
        
        let viewModelFiles = findFiles(pattern: "PayslipMax/Features/**/ViewModels/*.swift")
        let viewModelTestFiles = findFiles(pattern: "PayslipMaxTests/ViewModels/*.swift")
        
        print("• ViewModel files: \(viewModelFiles.count)")
        print("• ViewModel test files: \(viewModelTestFiles.count)")
        
        let keyViewModels = [
            "HomeViewModel",
            "PayslipsViewModel", 
            "InsightsViewModel",
            "SettingsViewModel",
            "AuthViewModel"
        ]
        
        print("\n🎯 Key ViewModels Test Status:")
        for viewModel in keyViewModels {
            let hasTestFile = findFiles(pattern: "PayslipMaxTests/**/*\(viewModel)*Tests.swift").count > 0
            let status = hasTestFile ? "✅" : "❌"
            print("  \(status) \(viewModel)")
        }
    }
    
    static func analyzeFeatureCoverage() {
        print("\n🏗️ Features Coverage Analysis:")
        
        let features = ["Authentication", "Home", "Payslips", "Insights", "Settings", "WebUpload"]
        
        for feature in features {
            let featureFiles = findFiles(pattern: "PayslipMax/Features/\(feature)/**/*.swift")
            let featureTestFiles = findFiles(pattern: "PayslipMaxTests/Features/\(feature)/**/*.swift")
            
            let coverage = featureTestFiles.count > 0 ? "✅" : "❌"
            print("  \(coverage) \(feature): \(featureFiles.count) files, \(featureTestFiles.count) tests")
        }
    }
    
    static func provideCoverageRecommendations() {
        print("\n💡 Test Coverage Recommendations:")
        print("=" * 50)
        
        // High priority areas needing tests
        let missingCriticalTests = [
            ("Core Data Models", "PayslipItem, ContactInfo, Financial calculations"),
            ("PDF Processing Pipeline", "End-to-end processing, error scenarios"),
            ("Security & Encryption", "Biometric auth, data encryption/decryption"),
            ("Pattern Matching", "Military patterns, new format detection"),
            ("Integration Tests", "Service-to-service communication"),
            ("Edge Cases", "Malformed PDFs, network failures"),
            ("Performance Tests", "Large PDF processing, memory usage")
        ]
        
        print("\n🎯 High Priority Test Areas:")
        for (area, description) in missingCriticalTests {
            print("• \(area): \(description)")
        }
        
        print("\n🚀 Suggested Next Steps:")
        print("1. Add unit tests for core business logic in Services/")
        print("2. Create integration tests for PDF → PayslipItem pipeline")
        print("3. Add ViewModel tests for state management")
        print("4. Implement property-based tests for parsers")
        print("5. Add performance benchmarks for large documents")
        print("6. Create mock services for reliable testing")
        print("7. Add UI tests for critical user flows")
    }
    
    // Helper functions
    static func countSwiftFiles(in directory: String, excluding: [String] = []) -> Int {
        return findFiles(pattern: "\(directory)/**/*.swift", excluding: excluding).count
    }
    
    static func findFiles(pattern: String, excluding: [String] = []) -> [String] {
        // This is a simplified implementation
        // In real script, would use FileManager to recursively search
        return [] // Placeholder - would implement file system traversal
    }
    
    static func fileExists(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}

TestCoverageAnalyzer.main() 