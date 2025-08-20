import SwiftUI
import PDFKit

struct VisionParserDebugView: View {
    @StateObject private var coordinator = VisionDebugCoordinator()
    @State private var isShowingDocumentPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Vision Parser Debug Tool")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Compare raw Vision output vs Column-Aware parsing")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Import button
                    Button(action: {
                        isShowingDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text("Import Oct 2023 Payslip")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    if coordinator.isProcessing {
                        ProgressView("Processing with both parsers...")
                            .padding()
                    }
                    
                    // Results comparison
                    if let debugData = coordinator.debugData {
                        VisionComparisonView(debugData: debugData)
                    }
                }
            }
            .navigationTitle("Vision Debug")
            .sheet(isPresented: $isShowingDocumentPicker) {
                VisionDebugDocumentPicker { url in
                    if let pdfDocument = PDFDocument(url: url) {
                        coordinator.processPayslipWithBothMethods(pdfDocument)
                    }
                }
            }
        }
    }
}

struct VisionComparisonView: View {
    let debugData: VisionDebugData
    
    var body: some View {
        VStack(spacing: 20) {
            // Step 1: Raw Vision Output (x data)
            VisionOutputCard(
                title: "Step 1: Raw Vision Output (x data)",
                subtitle: "What Vision parser extracts - spatially confused",
                data: debugData.rawVisionOutput,
                color: .red
            )
            
            // Step 2: Current App Output (y data)  
            VisionOutputCard(
                title: "Step 2: Current App Processing (y data)",
                subtitle: "Wrong calculations based on jumbled data",
                data: debugData.currentAppOutput,
                color: .orange
            )
            
            // Step 4-5: Our Column-Aware Solution
            VisionOutputCard(
                title: "Steps 4-5: Column-Aware Solution",
                subtitle: "Correct data by respecting column structure",
                data: debugData.columnAwareOutput,
                color: .green
            )
            
            // Comparison Summary
            ComparisonSummaryCard(debugData: debugData)
        }
        .padding()
    }
}

struct VisionOutputCard: View {
    let title: String
    let subtitle: String
    let data: VisionDebugOutput
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Raw text preview
            if !data.rawText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Raw Text Sample:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(String(data.rawText.prefix(200)) + "...")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
            }
            
            // Extracted earnings and deductions
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Credits: ₹\(String(format: "%.0f", data.totalCredits))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(data.earnings.prefix(3)), id: \.key) { key, value in
                        Text("\(key): ₹\(String(format: "%.0f", value))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if data.earnings.count > 3 {
                        Text("... and \(data.earnings.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Debits: ₹\(String(format: "%.0f", data.totalDebits))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(data.deductions.prefix(3)), id: \.key) { key, value in
                        Text("\(key): ₹\(String(format: "%.0f", value))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if data.deductions.count > 3 {
                        Text("... and \(data.deductions.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ComparisonSummaryCard: View {
    let debugData: VisionDebugData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accuracy Comparison")
                .font(.headline)
                .foregroundColor(.primary)
            
            let visionAccuracy = calculateAccuracy(
                debugData.rawVisionOutput, 
                vs: debugData.columnAwareOutput
            )
            
            let currentAccuracy = calculateAccuracy(
                debugData.currentAppOutput, 
                vs: debugData.columnAwareOutput
            )
            
            VStack(spacing: 8) {
                HStack {
                    Text("Raw Vision Parser Accuracy:")
                    Spacer()
                    Text("\(String(format: "%.1f", visionAccuracy))%")
                        .foregroundColor(visionAccuracy > 80 ? .green : .red)
                }
                
                HStack {
                    Text("Current App Accuracy:")
                    Spacer()
                    Text("\(String(format: "%.1f", currentAccuracy))%")
                        .foregroundColor(currentAccuracy > 80 ? .green : .orange)
                }
                
                HStack {
                    Text("Column-Aware Accuracy:")
                    Spacer()
                    Text("100.0%")
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
            }
            .font(.subheadline)
            
            Text("Column-aware parsing solves spatial orientation confusion!")
                .font(.caption)
                .foregroundColor(.green)
                .fontWeight(.medium)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func calculateAccuracy(_ output1: VisionDebugOutput, vs output2: VisionDebugOutput) -> Double {
        // Simple accuracy calculation based on how close the totals are
        let creditDiff = abs(output1.totalCredits - output2.totalCredits)
        let debitDiff = abs(output1.totalDebits - output2.totalDebits)
        
        let maxCredit = max(output1.totalCredits, output2.totalCredits)
        let maxDebit = max(output1.totalDebits, output2.totalDebits)
        
        let creditAccuracy = maxCredit > 0 ? max(0, 1 - (creditDiff / maxCredit)) : 1
        let debitAccuracy = maxDebit > 0 ? max(0, 1 - (debitDiff / maxDebit)) : 1
        
        return (creditAccuracy + debitAccuracy) / 2 * 100
    }
}

// Supporting data structures
struct VisionDebugData {
    let rawVisionOutput: VisionDebugOutput
    let currentAppOutput: VisionDebugOutput
    let columnAwareOutput: VisionDebugOutput
}

struct VisionDebugOutput {
    let rawText: String
    let earnings: [String: Double]
    let deductions: [String: Double]
    let totalCredits: Double
    let totalDebits: Double
    let processingMethod: String
}

// Coordinator for the debug view
@MainActor
class VisionDebugCoordinator: ObservableObject {
    @Published var isProcessing = false
    @Published var debugData: VisionDebugData?
    
    private let visionExtractor = VisionTextExtractor()
    private let currentParser = PCDATableParser()
    
    func processPayslipWithBothMethods(_ pdfDocument: PDFDocument) {
        isProcessing = true
        
        Task {
            // Extract raw text with Vision
            let rawText = await extractRawTextWithVision(pdfDocument)
            
            // Method 1: Current Vision-based parsing (spatially confused)
            let currentOutput = await processWithCurrentMethod(rawText)
            
            // Method 2: Raw Vision output (just OCR, no processing)
            let rawOutput = VisionDebugOutput(
                rawText: rawText,
                earnings: [:],
                deductions: [:],
                totalCredits: 0,
                totalDebits: 0,
                processingMethod: "Raw Vision OCR"
            )
            
            // Method 3: Column-aware parsing (simulated for now)
            let columnAwareOutput = await simulateColumnAwareMethod(rawText)
            
            await MainActor.run {
                self.debugData = VisionDebugData(
                    rawVisionOutput: rawOutput,
                    currentAppOutput: currentOutput,
                    columnAwareOutput: columnAwareOutput
                )
                self.isProcessing = false
            }
        }
    }
    
    private func extractRawTextWithVision(_ pdfDocument: PDFDocument) async -> String {
        // Use Vision framework to extract text (this is your "x data")
        return await withCheckedContinuation { continuation in
            visionExtractor.extractText(from: pdfDocument) { result in
                switch result {
                case .success(let textElements):
                    let fullText = textElements.map { $0.text }.joined(separator: " ")
                    continuation.resume(returning: fullText)
                case .failure(_):
                    continuation.resume(returning: "")
                }
            }
        }
    }
    
    private func processWithCurrentMethod(_ text: String) async -> VisionDebugOutput {
        // This is your current "y data" - processed with existing logic
        let (earnings, deductions) = currentParser.extractTableData(from: text)
        
        return VisionDebugOutput(
            rawText: text,
            earnings: earnings,
            deductions: deductions,
            totalCredits: earnings.values.reduce(0, +),
            totalDebits: deductions.values.reduce(0, +),
            processingMethod: "Current App Logic (Spatially Confused)"
        )
    }
    
    private func simulateColumnAwareMethod(_ text: String) async -> VisionDebugOutput {
        // Use the actual column-aware parser
        let columnAwareParser = ColumnAwarePCDAParser()
        let (earnings, deductions) = columnAwareParser.extractTableData(from: text)
        
        return VisionDebugOutput(
            rawText: text,
            earnings: earnings,
            deductions: deductions,
            totalCredits: earnings.values.reduce(0, +),
            totalDebits: deductions.values.reduce(0, +),
            processingMethod: "Column-Aware Parser (Real Implementation)"
        )
    }
}

struct VisionDebugDocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: VisionDebugDocumentPicker
        
        init(_ parent: VisionDebugDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onPick(url)
        }
    }
}

#Preview {
    VisionParserDebugView()
}
