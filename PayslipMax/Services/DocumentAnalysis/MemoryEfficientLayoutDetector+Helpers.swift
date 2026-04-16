import Foundation
import PDFKit

// MARK: - Private Helper Methods

extension MemoryEfficientLayoutDetector {

    /// Check if a line has consistent spacing (memory-optimized)
    func hasConsistentSpacing(_ line: String) -> Bool {
        let truncatedLine = String(line.prefix(150))
        var spaceGroups: [Int] = []
        var currentSpaceCount = 0
        var inSpace = false
        
        for char in truncatedLine {
            if char == " " {
                if !inSpace {
                    inSpace = true
                    currentSpaceCount = 1
                } else {
                    currentSpaceCount += 1
                }
            } else {
                if inSpace {
                    inSpace = false
                    spaceGroups.append(currentSpaceCount)
                    currentSpaceCount = 0
                }
            }
        }
        
        if spaceGroups.count >= 2 && spaceGroups.count <= 15 {
            let uniqueGroups = Set(spaceGroups)
            return Double(uniqueGroups.count) / Double(spaceGroups.count) <= 0.5
        }
        
        return false
    }

    /// Estimate column count with memory optimization
    func estimateColumnCount(from text: String, pageWidth: CGFloat) -> Int {
        let lines = text.components(separatedBy: .newlines)
        
        let maxLinesToAnalyze = min(30, lines.count)
        let sampleLines = Array(lines.prefix(maxLinesToAnalyze))
        
        var lineLengths: [Int] = []
        
        for line in sampleLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                lineLengths.append(trimmed.count)
            }
        }
        
        guard !lineLengths.isEmpty else { return 1 }
        
        lineLengths.sort()
        
        let median = lineLengths[lineLengths.count / 2]
        let thresholdValue = Double(median) * 0.6
        let shortLines = lineLengths.filter { Double($0) < thresholdValue }.count
        let longLines = lineLengths.filter { Double($0) > thresholdValue }.count
        
        if shortLines > lineLengths.count / 3 && longLines > lineLengths.count / 3 {
            return 2
        }
        
        if pageWidth > 800 {
            return 2
        }
        
        return 1
    }

    /// Generate cache key for layout analysis
    func generateLayoutCacheKey(document: PDFDocument, pageIndices: [Int]) -> String {
        let documentKey = document.documentURL?.lastPathComponent ?? "unknown"
        let pageKey = pageIndices.map(String.init).joined(separator: ",")
        return "\(documentKey)_layout_\(pageKey)"
    }

    /// Clear layout cache to manage memory
    func clearCache() {
        layoutCache.removeAll()
    }
}
