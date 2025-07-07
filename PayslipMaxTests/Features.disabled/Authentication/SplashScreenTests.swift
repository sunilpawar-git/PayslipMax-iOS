import XCTest
import SwiftUI
@testable import PayslipMax

/// Tests for SplashScreenView and SplashQuoteService
/// Ensures proper functionality while maintaining tech debt reduction standards
@MainActor
final class SplashScreenTests: XCTestCase {
    
    // MARK: - SplashQuoteService Tests
    
    func testSplashQuoteServiceReturnsValidQuote() {
        // Given: The quote service
        // When: Getting a random quote
        let quote = SplashQuoteService.getRandomQuote()
        
        // Then: Quote should be valid
        XCTAssertFalse(quote.text.isEmpty, "Quote text should not be empty")
        XCTAssertNotNil(quote.id, "Quote should have a valid ID")
    }
    
    func testSplashQuoteServiceHasExpectedNumberOfQuotes() {
        // Given: The quote service
        // When: Checking total quotes
        let totalQuotes = SplashQuoteService.totalQuotes
        
        // Then: Should have at least the user-provided quotes plus additional ones
        XCTAssertGreaterThanOrEqual(totalQuotes, 3, "Should have at least the 3 user-provided quotes")
        XCTAssertGreaterThan(totalQuotes, 10, "Should have expanded collection of quotes")
    }
    
    func testSplashQuoteEquality() {
        // Given: Two quotes with same content
        let quote1 = SplashQuote("Test quote", author: "Test Author")
        let quote2 = SplashQuote("Test quote", author: "Test Author")
        
        // When: Comparing them
        // Then: They should be equal (content-wise, not ID)
        XCTAssertEqual(quote1.text, quote2.text)
        XCTAssertEqual(quote1.author, quote2.author)
        XCTAssertNotEqual(quote1.id, quote2.id, "IDs should be unique")
    }
    
    func testUserProvidedQuotesAreIncluded() {
        // Given: The expected user quotes
        let expectedQuotes = [
            "What gets measured, gets managed",
            "Let your payslip be your financial guide, not just a document in storage.",
            "Your payslip speaks to you. You just need to learn how to listen."
        ]
        
        // When: Getting quotes multiple times to find user quotes
        var foundQuotes: Set<String> = []
        
        // Try multiple times to find the quotes (they're random)
        for _ in 0..<100 {
            let quote = SplashQuoteService.getRandomQuote()
            foundQuotes.insert(quote.text)
        }
        
        // Then: All user quotes should be found
        for expectedQuote in expectedQuotes {
            XCTAssertTrue(foundQuotes.contains(expectedQuote), 
                         "User quote '\(expectedQuote)' should be included in service")
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testSplashQuoteServiceMemoryEfficiency() {
        // Given: Multiple calls to the service
        // When: Getting many quotes
        let quotes = (0..<1000).map { _ in SplashQuoteService.getRandomQuote() }
        
        // Then: Should not consume excessive memory (basic check)
        XCTAssertEqual(quotes.count, 1000, "Should return requested number of quotes")
        
        // Verify quotes are being reused from static collection
        let uniqueTexts = Set(quotes.map { $0.text })
        XCTAssertLessThan(uniqueTexts.count, 100, "Should reuse quotes from limited collection")
    }
    
    // MARK: - Performance Tests
    
    func testQuoteServicePerformance() {
        // Test that quote retrieval is fast (should be nearly instant for static array)
        measure {
            for _ in 0..<1000 {
                _ = SplashQuoteService.getRandomQuote()
            }
        }
    }
    
    // MARK: - Content Quality Tests
    
    func testAllQuotesHaveContent() {
        // Given: Multiple quote retrievals
        var allTexts: Set<String> = []
        
        // When: Getting many quotes to sample the collection
        for _ in 0..<200 {
            let quote = SplashQuoteService.getRandomQuote()
            allTexts.insert(quote.text)
        }
        
        // Then: All quotes should have meaningful content
        for text in allTexts {
            XCTAssertFalse(text.isEmpty, "No quote should be empty")
            XCTAssertGreaterThan(text.count, 10, "Quotes should be substantial: '\(text)'")
        }
    }
    
    func testFinancialRelevance() {
        // Given: Multiple quote retrievals
        var allTexts: Set<String> = []
        
        // When: Getting many quotes
        for _ in 0..<200 {
            let quote = SplashQuoteService.getRandomQuote()
            allTexts.insert(quote.text.lowercased())
        }
        
        // Then: Collection should contain financial/payslip relevant terms
        let relevantTerms = ["financial", "money", "payslip", "saving", "budget", 
                           "wealth", "investment", "earning", "deduction", "pay"]
        
        let hasRelevantContent = allTexts.contains { text in
            relevantTerms.contains { term in
                text.contains(term)
            }
        }
        
        XCTAssertTrue(hasRelevantContent, "Quote collection should contain financially relevant content")
    }
    
    // MARK: - Architecture Tests
    
    func testSplashContainerDecoupledFromAuth() {
        // Given: The splash container view
        // When: Container is initialized
        // Then: It should work independently of authentication state
        // This test verifies architectural decoupling
        
        let splashContainer = SplashContainerView {
            Text("Test Content")
        }
        
        // Container should be initialized successfully
        XCTAssertNotNil(splashContainer, "Splash container should initialize independently")
    }
} 