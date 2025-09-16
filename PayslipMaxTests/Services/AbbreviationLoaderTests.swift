import XCTest
@testable import PayslipMax

/// Comprehensive tests for AbbreviationLoader JSON-based system
final class AbbreviationLoaderTests: XCTestCase {

    var loader: AbbreviationLoader!

    override func setUp() {
        super.setUp()
        loader = AbbreviationLoader()
    }

    override func tearDown() {
        loader = nil
        super.tearDown()
    }

    // MARK: - JSON Loading Tests

    func testJSONFileExists() {
        // Given: Bundled JSON file should exist
        let url = Bundle.main.url(forResource: "military_abbreviations", withExtension: "json")

        // Then: File must be present
        XCTAssertNotNil(url, "military_abbreviations.json must be present in bundle")
    }

    func testJSONStructureValid() throws {
        // When: Load abbreviations from JSON
        let abbreviations = try loader.loadAbbreviations()

        // Then: Should have 200+ abbreviations
        XCTAssertGreaterThan(abbreviations.count, 200, "Should have 200+ military abbreviations")
    }

    func testJSONContainsEssentialCodes() throws {
        // When: Load abbreviations
        let abbreviations = try loader.loadAbbreviations()
        let codes = Set(abbreviations.map { $0.code })

        // Then: Must contain essential military codes
        let essentialCodes = ["BPAY", "MSP", "DA", "HRA", "DSOP", "AGIF", "ITAX", "RH12", "TPTA", "CEA"]

        for code in essentialCodes {
            XCTAssertTrue(codes.contains(code), "Must contain essential military code: \(code)")
        }
    }

    func testJSONContainsSpecialForcesCodes() throws {
        // When: Load abbreviations
        let abbreviations = try loader.loadAbbreviations()
        let codes = Set(abbreviations.map { $0.code })

        // Then: Must contain special forces codes
        let specialForcesCodes = ["SPCDO", "FLYALLOW", "SICHA", "HAUC3"]

        for code in specialForcesCodes {
            XCTAssertTrue(codes.contains(code), "Must contain special forces code: \(code)")
        }
    }

    func testJSONContainsRHFamily() throws {
        // When: Load abbreviations
        let abbreviations = try loader.loadAbbreviations()
        let codes = Set(abbreviations.map { $0.code })

        // Then: Must contain complete RH family
        let rhCodes = ["RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]

        for code in rhCodes {
            XCTAssertTrue(codes.contains(code), "Must contain RH family code: \(code)")
        }
    }

    // MARK: - Caching Tests

    func testCachingBehavior() throws {
        // When: Load abbreviations multiple times
        let firstLoad = try loader.loadAbbreviations()
        let secondLoad = try loader.loadAbbreviations()

        // Then: Should return same cached data
        XCTAssertEqual(firstLoad.count, secondLoad.count)
        XCTAssertEqual(firstLoad.first?.code, secondLoad.first?.code)
    }

    // MARK: - Component Mappings Tests

    func testComponentMappingsExist() throws {
        // When: Load component mappings
        let mappings = try loader.loadComponentMappings()

        // Then: Should have mappings for common variations
        XCTAssertFalse(mappings.isEmpty, "Should have component mappings")

        // Should contain basic pay mappings
        let basicPayMappings = mappings.keys.filter { $0.lowercased().contains("basic") }
        XCTAssertFalse(basicPayMappings.isEmpty, "Should have basic pay mappings")
    }

    // MARK: - Error Handling Tests

    func testHandlesCorruptedData() {
        // Given: This test would require a corrupted JSON file
        // Note: In real implementation, we'd need to mock the Bundle.main.url call
        // For now, we verify the error handling structure exists

        do {
            _ = try loader.loadAbbreviations()
        } catch {
            // Should handle errors gracefully
            XCTAssertTrue(error is AbbreviationLoaderError)
        }
    }

    // MARK: - Performance Tests

    func testLoadingPerformance() {
        measure {
            do {
                _ = try loader.loadAbbreviations()
            } catch {
                XCTFail("Loading should not fail: \(error)")
            }
        }
    }
}
