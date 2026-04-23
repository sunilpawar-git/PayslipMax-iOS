import Foundation
import CoreGraphics

/// Assembles positioned OCR text blocks into column-separated text streams
/// for military payslips with two-column tabular layout.
///
/// Algorithm:
/// 1. Collect all block center-X values
/// 2. Detect bimodal distribution (two clusters of X positions = two columns)
/// 3. Find the gap between clusters (the column divider)
/// 4. Classify each block as left, right, or full-width
/// 5. Sort each column's blocks top-to-bottom and join into text lines
final class TabularTextAssembler: TabularTextAssemblerProtocol, Sendable {

    private let fullWidthThreshold: CGFloat
    private let minimumColumnBlocks: Int
    private let minimumGapRatio: CGFloat
    /// Dead-zone: dividers within this distance from left/right page edges are rejected
    private let columnEdgeDeadZone: CGFloat

    /// - Parameters:
    ///   - fullWidthThreshold: Blocks wider than this fraction of page width are full-width (default 0.6)
    ///   - minimumColumnBlocks: Minimum blocks per column to consider layout tabular (default 2)
    ///   - minimumGapRatio: Minimum gap between clusters relative to page width (default 0.08)
    ///   - columnEdgeDeadZone: Rejected divider zone near left/right edges (default 0.15)
    init(
        fullWidthThreshold: CGFloat = 0.6,
        minimumColumnBlocks: Int = 2,
        minimumGapRatio: CGFloat = 0.08,
        columnEdgeDeadZone: CGFloat = 0.15
    ) {
        self.fullWidthThreshold = fullWidthThreshold
        self.minimumColumnBlocks = minimumColumnBlocks
        self.minimumGapRatio = minimumGapRatio
        self.columnEdgeDeadZone = columnEdgeDeadZone
    }

    func assemble(from ocrResult: StructuredOCRResult) -> TabularAssemblyResult {
        guard ocrResult.hasMinimumContent else {
            return buildNonTabularResult(blocks: [], wideBlocks: [])
        }

        let (narrowBlocks, wideBlocks) = separateByWidth(ocrResult.blocks)
        guard let (divider, gapStrength) = detectColumnDivider(from: narrowBlocks) else {
            return buildNonTabularResult(blocks: ocrResult.blocks, wideBlocks: wideBlocks)
        }

        let (leftBlocks, rightBlocks) = classifyByColumn(narrowBlocks, divider: divider)

        guard leftBlocks.count >= minimumColumnBlocks,
              rightBlocks.count >= minimumColumnBlocks else {
            return buildNonTabularResult(blocks: ocrResult.blocks, wideBlocks: wideBlocks)
        }

        let minSide = min(leftBlocks.count, rightBlocks.count)
        let maxSide = max(leftBlocks.count, rightBlocks.count)
        let massBalance = maxSide > 0 ? Double(minSide) / Double(maxSide) : 0.0
        let confidence = min(1.0, gapStrength * massBalance)

        return TabularAssemblyResult(
            leftColumn: buildColumn(from: leftBlocks),
            rightColumn: buildColumn(from: rightBlocks),
            fullWidthText: buildText(from: wideBlocks.sortedTopToBottom()),
            columnDivider: divider,
            isTabularLayoutDetected: true,
            columnSplitConfidence: confidence
        )
    }

    // MARK: - Width Separation

    private func separateByWidth(
        _ blocks: [OCRTextBlock]
    ) -> (narrow: [OCRTextBlock], wide: [OCRTextBlock]) {
        var narrow: [OCRTextBlock] = []
        var wide: [OCRTextBlock] = []

        for block in blocks {
            if block.boundingBox.width >= fullWidthThreshold {
                wide.append(block)
            } else {
                narrow.append(block)
            }
        }

        return (narrow, wide)
    }

    // MARK: - Column Divider Detection

    /// Detects the gap between two column clusters using sorted X-positions.
    /// Returns `(midpoint, normalised gap strength)` or nil if no valid gap exists.
    private func detectColumnDivider(from blocks: [OCRTextBlock]) -> (CGFloat, Double)? {
        guard blocks.count >= 4 else { return nil }

        let centerXValues = blocks.map { $0.centerX }.sorted()

        var maxGap: CGFloat = 0
        var gapMidpoint: CGFloat = 0.5

        for i in 0..<(centerXValues.count - 1) {
            let gap = centerXValues[i + 1] - centerXValues[i]
            if gap > maxGap {
                maxGap = gap
                gapMidpoint = (centerXValues[i] + centerXValues[i + 1]) / 2.0
            }
        }

        guard maxGap >= minimumGapRatio else { return nil }
        // Reject dividers that fall inside dead-zones (too close to edges)
        guard gapMidpoint > columnEdgeDeadZone,
              gapMidpoint < (1.0 - columnEdgeDeadZone) else { return nil }

        let normalisedStrength = Double(maxGap / 1.0)
        return (gapMidpoint, normalisedStrength)
    }

    // MARK: - Column Classification

    private func classifyByColumn(
        _ blocks: [OCRTextBlock],
        divider: CGFloat
    ) -> (left: [OCRTextBlock], right: [OCRTextBlock]) {
        var left: [OCRTextBlock] = []
        var right: [OCRTextBlock] = []

        for block in blocks {
            if block.centerX < divider {
                left.append(block)
            } else {
                right.append(block)
            }
        }

        return (left, right)
    }

    // MARK: - Text Assembly

    private func buildColumn(from blocks: [OCRTextBlock]) -> AssembledColumn {
        let sorted = blocks.sortedTopToBottom()
        let grouped = groupByRow(sorted)
        let lines = grouped.map { rowBlocks in
            rowBlocks.sorted { $0.boundingBox.origin.x < $1.boundingBox.origin.x }
                .map { $0.text }
                .joined(separator: " ")
        }
        let text = lines.joined(separator: "\n")

        let xValues = blocks.map { $0.boundingBox.origin.x }
        let xMaxValues = blocks.map { $0.boundingBox.maxX }
        let xMin = xValues.min() ?? 0
        let xMax = xMaxValues.max() ?? 1

        return AssembledColumn(
            text: text,
            xRange: xMin...xMax,
            blockCount: blocks.count
        )
    }

    private func buildText(from blocks: [OCRTextBlock]) -> String {
        blocks.map { $0.text }.joined(separator: "\n")
    }

    /// Groups blocks that are on the same visual row (similar Y position)
    private func groupByRow(_ blocks: [OCRTextBlock]) -> [[OCRTextBlock]] {
        guard !blocks.isEmpty else { return [] }

        let rowTolerance: CGFloat = 0.015
        var rows: [[OCRTextBlock]] = []
        var currentRow: [OCRTextBlock] = [blocks[0]]

        for i in 1..<blocks.count {
            let yDiff = abs(blocks[i].centerY - currentRow[0].centerY)
            if yDiff <= rowTolerance {
                currentRow.append(blocks[i])
            } else {
                rows.append(currentRow)
                currentRow = [blocks[i]]
            }
        }
        rows.append(currentRow)
        return rows
    }


    // MARK: - Non-Tabular Fallback

    private func buildNonTabularResult(
        blocks: [OCRTextBlock],
        wideBlocks: [OCRTextBlock]
    ) -> TabularAssemblyResult {
        let allText = blocks.sortedTopToBottom().map { $0.text }.joined(separator: "\n")
        let emptyColumn = AssembledColumn(text: "", xRange: 0...0, blockCount: 0)

        return TabularAssemblyResult(
            leftColumn: AssembledColumn(text: allText, xRange: 0...1, blockCount: blocks.count),
            rightColumn: emptyColumn,
            fullWidthText: buildText(from: wideBlocks.sortedTopToBottom()),
            columnDivider: 0.5,
            isTabularLayoutDetected: false,
            columnSplitConfidence: 0.0
        )
    }
}
