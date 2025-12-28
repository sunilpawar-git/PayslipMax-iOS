#!/usr/bin/env swift

import Foundation

// Configuration
let ignoredDirectories = ["Backups", ".git", "build", ".cursor"]
let processFileExtensions = ["swift"]

/// The target standardized format for various documentation types
enum DocTemplate {
    /// Template for type documentation
    static let typeDoc = """
    /// [Type description]
    ///
    /// [Detailed description if needed]
    ///
    /// - Note: Thread safety information, usage guidance, or other important notes
    """
    
    /// Template for method documentation
    static let methodDoc = """
    /// [Method description]
    ///
    /// [Detailed description if needed]
    ///
    /// - Parameters:
    ///   - [paramName]: [Parameter description]
    /// - Returns: [Return value description]
    /// - Throws: [Description of errors that can be thrown]
    """
    
    /// Template for property documentation
    static let propertyDoc = """
    /// [Property description]
    ///
    /// [Additional details if needed]
    """
}

// ANSI color codes
let red = "\u{001B}[31m"
let green = "\u{001B}[32m"
let yellow = "\u{001B}[33m"
let cyan = "\u{001B}[36m"
let reset = "\u{001B}[0m"

// Get the target file or directory path
let targetPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath
var dryRun = CommandLine.arguments.contains("--dry-run")

print("Documentation Standardizer")
print("-------------------------")
if dryRun {
    print("\(yellow)DRY RUN MODE: No changes will be written\(reset)")
}
print("Target: \(targetPath)")

func isDirectory(path: String) -> Bool {
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
        return isDir.boolValue
    }
    return false
}

func shouldProcessFile(path: String) -> Bool {
    let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
    return processFileExtensions.contains(fileExtension)
}

func shouldIgnoreDirectory(path: String) -> Bool {
    return ignoredDirectories.contains { path.contains("/\($0)/") || path.contains("/\($0)") }
}

func processTypeMatch(match: NSTextCheckingResult, line: String, lines: [String], i: Int, newLines: inout [String], nsline: NSString) {
    if i > 0 && lines[i-1].contains("///") {
        newLines.append(line)
    } else {
        let typeName = nsline.substring(with: match.range(at: 3))
        let typeKind = nsline.substring(with: match.range(at: 2))
        let indentation = String(line.prefix(while: { $0 == " " }))
        print("\(yellow)Missing documentation for \(typeKind) \(typeName)\(reset)")
        let docLines = DocTemplate.typeDoc.split(separator: "\n").map { "\(indentation)\($0)" }
        for docLine in docLines {
            newLines.append(String(docLine))
        }
        newLines.append(line)
        print("\(green)Added type documentation template\(reset)")
    }
}

func processMethodMatch(match: NSTextCheckingResult, line: String, lines: [String], i: Int, newLines: inout [String], nsline: NSString) {
    if i > 0 && lines[i-1].contains("///") {
        newLines.append(line)
    } else {
        let methodName = nsline.substring(with: match.range(at: 2))
        let indentation = String(line.prefix(while: { $0 == " " }))
        print("\(yellow)Missing documentation for method \(methodName)\(reset)")
        let docLines = DocTemplate.methodDoc.split(separator: "\n").map { "\(indentation)\($0)" }
        for docLine in docLines {
            newLines.append(String(docLine))
        }
        newLines.append(line)
        print("\(green)Added method documentation template\(reset)")
    }
}

func processPropertyMatch(match: NSTextCheckingResult, line: String, lines: [String], i: Int, newLines: inout [String], nsline: NSString) {
    if i > 0 && lines[i-1].contains("///") {
        newLines.append(line)
    } else {
        let propertyName = nsline.substring(with: match.range(at: 3))
        let accessLevel = match.range(at: 1).location != NSNotFound ? nsline.substring(with: match.range(at: 1)) : "internal"
        let isImportantProperty = !accessLevel.contains("private") || 
            propertyName.contains("ID") || 
            propertyName.contains("Data") ||
            propertyName.contains("URL") ||
            propertyName.contains("Key")
        if isImportantProperty {
            let indentation = String(line.prefix(while: { $0 == " " }))
            print("\(yellow)Missing documentation for property \(propertyName)\(reset)")
            let docLines = DocTemplate.propertyDoc.split(separator: "\n").map { "\(indentation)\($0)" }
            for docLine in docLines {
                newLines.append(String(docLine))
            }
        }
        newLines.append(line)
    }
}

func processFile(path: String) {
    print("\nProcessing: \(path)")
    
    do {
        let content = try String(contentsOfFile: path)
        let lines = content.components(separatedBy: .newlines)
        var newLines = [String]()
        var i = 0
        
        // Detect types that need documentation
        let typePatternStr = "^\\s*(public|open|internal|fileprivate|private)?\\s*(class|struct|enum|protocol)\\s+([A-Za-z0-9_]+)"
        let typePattern = try NSRegularExpression(pattern: typePatternStr, options: [])
        let methodPatternStr = "^\\s*(public|open|internal|fileprivate|private)?\\s*func\\s+([A-Za-z0-9_]+)"
        let methodPattern = try NSRegularExpression(pattern: methodPatternStr, options: [])
        let propertyPatternStr = "^\\s*(public|open|internal|fileprivate|private)?\\s*(var|let)\\s+([A-Za-z0-9_]+)"
        let propertyPattern = try NSRegularExpression(pattern: propertyPatternStr, options: [])
        
        while i < lines.count {
            let line = lines[i]
            let nsline = line as NSString
            
            // Check if current line is a type, method, or property declaration
            if let match = typePattern.firstMatch(in: line, range: NSRange(location: 0, length: nsline.length)) {
                processTypeMatch(match: match, line: line, lines: lines, i: i, newLines: &newLines, nsline: nsline)
            } else if let match = methodPattern.firstMatch(in: line, range: NSRange(location: 0, length: nsline.length)) {
                processMethodMatch(match: match, line: line, lines: lines, i: i, newLines: &newLines, nsline: nsline)
            } else if let match = propertyPattern.firstMatch(in: line, range: NSRange(location: 0, length: nsline.length)) {
                processPropertyMatch(match: match, line: line, lines: lines, i: i, newLines: &newLines, nsline: nsline)
            } else {
                newLines.append(line)
            }
            
            i += 1
        }
        
        // Check for MARK organization
        let hasProperties = content.contains("// MARK: - Properties")
        let hasMethods = content.contains("// MARK: - Methods") || 
                         content.contains("// MARK: - Public Methods") || 
                         content.contains("// MARK: - Private Methods")
        let hasInitialization = content.contains("// MARK: - Initialization")
        
        if !(hasProperties && hasMethods && hasInitialization) && (content.contains("class ") || content.contains("struct ")) {
            print("\(yellow)Missing standard MARK sections\(reset)")
            print("\(cyan)Suggested sections:\(reset)")
            print("// MARK: - Properties")
            print("// MARK: - Initialization")
            print("// MARK: - Public Methods")
            print("// MARK: - Private Methods")
        }
        
        // Write changes if not in dry run mode
        let newContent = newLines.joined(separator: "\n")
        if !dryRun && newContent != content {
            try newContent.write(toFile: path, atomically: true, encoding: .utf8)
            print("\(green)Updated file with standardized documentation\(reset)")
        } else if newContent != content {
            print("\(yellow)Would update file (dry run)\(reset)")
        } else {
            print("No changes needed")
        }
    } catch {
        print("\(red)Error processing file: \(error)\(reset)")
    }
}

func processDirectory(path: String) {
    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil)
        
        for fileURL in fileURLs {
            let filePath = fileURL.path
            
            if shouldIgnoreDirectory(path: filePath) {
                continue
            }
            
            if isDirectory(path: filePath) {
                processDirectory(path: filePath)
            } else if shouldProcessFile(path: filePath) {
                processFile(path: filePath)
            }
        }
    } catch {
        print("\(red)Error reading directory: \(error)\(reset)")
    }
}

// Start processing
if isDirectory(path: targetPath) {
    processDirectory(path: targetPath)
} else if shouldProcessFile(path: targetPath) {
    processFile(path: targetPath)
} else {
    print("\(red)Error: Invalid target path or unsupported file type\(reset)")
}

print("\nDocumentation standardization complete!")
print("To apply changes to files, run without the --dry-run flag") 