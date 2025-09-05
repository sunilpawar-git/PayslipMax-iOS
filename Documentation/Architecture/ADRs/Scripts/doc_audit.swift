#!/usr/bin/env swift

import Foundation

// Configuration
let ignoredDirectories = ["Backups", ".git", "build", ".cursor"]
let analyzeFileExtensions = ["swift"]

// Documentation check patterns
let publicAPIPattern = try! NSRegularExpression(pattern: "(public|open)\\s+(class|struct|enum|protocol|func|var|let)\\s+\\w+", options: [])
let documentationPattern = try! NSRegularExpression(pattern: "///.*", options: [])

// Results tracking
struct FileDocStats {
    let filePath: String
    let totalPublicAPIs: Int
    let documentedAPIs: Int
    let missingDocPaths: [String]
    
    var documentationPercentage: Double {
        if totalPublicAPIs == 0 { return 100.0 }
        return Double(documentedAPIs) / Double(totalPublicAPIs) * 100.0
    }
}

// Get the current directory or the provided path
let currentDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath
var allStats: [FileDocStats] = []
var totalPublicAPIs = 0
var totalDocumentedAPIs = 0

// ANSI color codes
let red = "\u{001B}[31m"
let green = "\u{001B}[32m"
let yellow = "\u{001B}[33m"
let reset = "\u{001B}[0m"

func analyzeFile(at path: String) -> FileDocStats {
    do {
        let content = try String(contentsOfFile: path)
        let lines = content.components(separatedBy: .newlines)
        var publicAPIPaths: [String] = []
        var documentedPaths: [String] = []
        
        for (index, line) in lines.enumerated() {
            if let match = publicAPIPattern.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
                let apiPath = "\(path):\(index+1): \(line.trimmingCharacters(in: .whitespaces))"
                publicAPIPaths.append(apiPath)
                
                // Check if the line is preceded by documentation
                if index > 0 {
                    let previousLine = lines[index-1]
                    if documentationPattern.firstMatch(in: previousLine, range: NSRange(location: 0, length: previousLine.utf16.count)) != nil {
                        documentedPaths.append(apiPath)
                    }
                }
            }
        }
        
        let missingDocPaths = publicAPIPaths.filter { !documentedPaths.contains($0) }
        
        return FileDocStats(
            filePath: path,
            totalPublicAPIs: publicAPIPaths.count,
            documentedAPIs: documentedPaths.count,
            missingDocPaths: missingDocPaths
        )
    } catch {
        print("Error reading file at \(path): \(error)")
        return FileDocStats(filePath: path, totalPublicAPIs: 0, documentedAPIs: 0, missingDocPaths: [])
    }
}

func processDirectory(_ directoryPath: String) {
    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directoryPath), includingPropertiesForKeys: nil)
        
        for fileURL in fileURLs {
            let path = fileURL.path
            let lastComponent = fileURL.lastPathComponent
            
            // Skip ignored directories
            if ignoredDirectories.contains(where: { path.contains("/\($0)/") || path.contains("/\($0)") }) {
                continue
            }
            
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    processDirectory(path)
                } else if analyzeFileExtensions.contains(fileURL.pathExtension) {
                    let stats = analyzeFile(at: path)
                    allStats.append(stats)
                    totalPublicAPIs += stats.totalPublicAPIs
                    totalDocumentedAPIs += stats.documentedAPIs
                }
            }
        }
    } catch {
        print("Error processing directory at \(directoryPath): \(error)")
    }
}

// Run the analysis
print("Analyzing Swift files for documentation in \(currentDirectory)...")
processDirectory(currentDirectory)

// Sort files by documentation percentage (ascending)
allStats.sort { $0.documentationPercentage < $1.documentationPercentage }

// Print summary report
print("\n📊 Documentation Coverage Report")
print("==============================")
print("Total Public APIs: \(totalPublicAPIs)")
print("Total Documented APIs: \(totalDocumentedAPIs)")

let overallPercentage = totalPublicAPIs > 0 ? Double(totalDocumentedAPIs) / Double(totalPublicAPIs) * 100.0 : 100.0
let percentageColor = overallPercentage < 50 ? red : (overallPercentage < 80 ? yellow : green)
print("Overall Documentation Coverage: \(percentageColor)\(String(format: "%.1f", overallPercentage))%\(reset)")

// Print files with missing documentation
print("\n🔍 Files Needing Documentation Attention:")
print("=======================================")

let filesToShow = allStats.filter { $0.totalPublicAPIs > 0 && $0.documentedAPIs < $0.totalPublicAPIs }
for stats in filesToShow.prefix(10) {
    let percentageColor = stats.documentationPercentage < 50 ? red : (stats.documentationPercentage < 80 ? yellow : green)
    print("\(stats.filePath): \(percentageColor)\(String(format: "%.1f", stats.documentationPercentage))%\(reset) (\(stats.documentedAPIs)/\(stats.totalPublicAPIs))")
    
    // Print up to 3 missing documentation paths per file
    for path in stats.missingDocPaths.prefix(3) {
        print("  - Missing: \(path)")
    }
    
    if stats.missingDocPaths.count > 3 {
        print("  - ... and \(stats.missingDocPaths.count - 3) more")
    }
}

if filesToShow.count > 10 {
    print("\n... and \(filesToShow.count - 10) more files with missing documentation")
}

// Print recommendations
print("\n💡 Recommendations:")
print("=================")
print("1. Start by documenting files with the lowest documentation coverage.")
print("2. Focus on core protocols and public APIs first.")
print("3. Use the standardized documentation format from our style guide.")
print("4. Run this script regularly to track progress.")

let targetDate = Date().addingTimeInterval(3 * 24 * 60 * 60) // 3 days from now
let dateFormatter = DateFormatter()
dateFormatter.dateStyle = .medium
print("\nTarget completion date: \(dateFormatter.string(from: targetDate))") 