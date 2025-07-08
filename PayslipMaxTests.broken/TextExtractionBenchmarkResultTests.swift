import XCTest
@testable import PayslipMax

final class TextExtractionBenchmarkResultTests: XCTestCase {
    
    // Test base properties and initialization
    func testInitialization() {
        // Create a base benchmark result
        let baseResult = PDFBenchmarkingTools.BenchmarkResult(
            strategyName: "TestStrategy",
            executionTime: 1.5,
            memoryUsage: 1024 * 1024, // 1MB
            outputSize: 5000,
            success: true
        )
        
        // Create text extraction benchmark result
        let textExtractionResult = PDFBenchmarkingTools.TextExtractionBenchmarkResult(
            baseResult: baseResult,
            textQualityScore: 85.5,
            structurePreservationScore: 92.0,
            textOrderAccuracy: 88.3,
            characterErrorRate: 0.02
        )
        
        // Test base properties
        XCTAssertEqual(textExtractionResult.strategyName, "TestStrategy")
        XCTAssertEqual(textExtractionResult.executionTime, 1.5)
        XCTAssertEqual(textExtractionResult.memoryUsage, 1024 * 1024)
        XCTAssertEqual(textExtractionResult.outputSize, 5000)
        XCTAssertTrue(textExtractionResult.success)
        
        // Test text extraction specific properties
        XCTAssertEqual(textExtractionResult.textQualityScore, 85.5)
        XCTAssertEqual(textExtractionResult.structurePreservationScore, 92.0)
        XCTAssertEqual(textExtractionResult.textOrderAccuracy, 88.3)
        XCTAssertEqual(textExtractionResult.characterErrorRate, 0.02)
    }
    
    // Test convenience initializer
    func testConvenienceInitializer() {
        let baseResult = PDFBenchmarkingTools.BenchmarkResult(
            strategyName: "StandardExtraction",
            executionTime: 0.8,
            memoryUsage: 512 * 1024,
            outputSize: 2500,
            success: true
        )
        
        let textExtractionResult = PDFBenchmarkingTools.TextExtractionBenchmarkResult(from: baseResult)
        
        // Verify base properties are correctly passed
        XCTAssertEqual(textExtractionResult.baseResult.strategyName, "StandardExtraction")
        XCTAssertEqual(textExtractionResult.baseResult.executionTime, 0.8)
        XCTAssertEqual(textExtractionResult.baseResult.memoryUsage, 512 * 1024)
        XCTAssertEqual(textExtractionResult.baseResult.outputSize, 2500)
        XCTAssertTrue(textExtractionResult.baseResult.success)
        
        // Default values for quality metrics should be 0
        XCTAssertEqual(textExtractionResult.textQualityScore, 0)
        XCTAssertEqual(textExtractionResult.structurePreservationScore, 0)
        XCTAssertEqual(textExtractionResult.textOrderAccuracy, 0)
        XCTAssertEqual(textExtractionResult.characterErrorRate, 0)
    }
    
    // Test getSummary method
    func testGetSummary() {
        let baseResult = PDFBenchmarkingTools.BenchmarkResult(
            strategyName: "VisionExtraction",
            executionTime: 2.123,
            memoryUsage: 3 * 1024 * 1024, // 3MB
            outputSize: 10000,
            success: true
        )
        
        let textExtractionResult = PDFBenchmarkingTools.TextExtractionBenchmarkResult(
            baseResult: baseResult,
            textQualityScore: 90.5,
            structurePreservationScore: 85.0,
            textOrderAccuracy: 95.7,
            characterErrorRate: 0.015
        )
        
        let summary = textExtractionResult.getSummary()
        
        // Verify that summary contains all the relevant information
        XCTAssertTrue(summary.contains("VisionExtraction"))
        XCTAssertTrue(summary.contains("2.123 sec"))
        XCTAssertTrue(summary.contains("3.00 MB"))
        XCTAssertTrue(summary.contains("10000 chars"))
        XCTAssertTrue(summary.contains("Quality: 90.5%"))
        XCTAssertTrue(summary.contains("Structure: 85.0%"))
        XCTAssertTrue(summary.contains("Order: 95.7%"))
        XCTAssertTrue(summary.contains("CER: 1.50%"))
    }
    
    // Test codable conformance
    func testCodableConformance() {
        // Create test data
        let baseResult = PDFBenchmarkingTools.BenchmarkResult(
            strategyName: "FastTextExtraction",
            executionTime: 0.5,
            memoryUsage: 256 * 1024,
            outputSize: 3000,
            success: true
        )
        
        let original = PDFBenchmarkingTools.TextExtractionBenchmarkResult(
            baseResult: baseResult,
            textQualityScore: 75.0,
            structurePreservationScore: 80.0,
            textOrderAccuracy: 90.0,
            characterErrorRate: 0.03
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        var jsonData: Data
        
        do {
            jsonData = try encoder.encode(original)
        } catch {
            XCTFail("Failed to encode TextExtractionBenchmarkResult: \(error)")
            return
        }
        
        // Decode from JSON
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(PDFBenchmarkingTools.TextExtractionBenchmarkResult.self, from: jsonData)
            
            // Verify properties match
            XCTAssertEqual(decoded.strategyName, original.strategyName)
            XCTAssertEqual(decoded.executionTime, original.executionTime)
            XCTAssertEqual(decoded.memoryUsage, original.memoryUsage)
            XCTAssertEqual(decoded.outputSize, original.outputSize)
            XCTAssertEqual(decoded.success, original.success)
            
            XCTAssertEqual(decoded.textQualityScore, original.textQualityScore)
            XCTAssertEqual(decoded.structurePreservationScore, original.structurePreservationScore)
            XCTAssertEqual(decoded.textOrderAccuracy, original.textOrderAccuracy)
            XCTAssertEqual(decoded.characterErrorRate, original.characterErrorRate)
            
        } catch {
            XCTFail("Failed to decode TextExtractionBenchmarkResult: \(error)")
        }
    }
} 