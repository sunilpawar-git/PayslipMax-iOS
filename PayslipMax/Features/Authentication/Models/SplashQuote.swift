import Foundation

/// Model representing a financial quote for the splash screen
struct SplashQuote: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let author: String?
    
    init(_ text: String, author: String? = nil) {
        self.text = text
        self.author = author
    }
}

/// Service providing curated financial quotes for PayslipMax
struct SplashQuoteService {
    /// Collection of financial quotes relevant to payslip management and financial awareness
    private static let quotes: [SplashQuote] = [
        // User-provided quotes
        SplashQuote("What gets measured, gets managed", author: "Peter Drucker"),
        SplashQuote("Let your payslip be your financial guide, not just a document in storage."),
        SplashQuote("Your payslip speaks to you. You just need to learn how to listen."),
        
        // Financial wisdom quotes
        SplashQuote("A budget is telling your money where to go instead of wondering where it went", author: "Dave Ramsey"),
        SplashQuote("The real measure of your wealth is how much you'd be worth if you lost all your money", author: "Warren Buffett"),
        SplashQuote("It's not how much money you make, but how much money you keep", author: "Robert Kiyosaki"),
        SplashQuote("Financial peace isn't the acquisition of stuff. It's learning to live on less than you make", author: "Dave Ramsey"),
        SplashQuote("The habit of saving is itself an education; it fosters every virtue", author: "T.T. Munger"),
        
        // Payslip-specific insights
        SplashQuote("Every deduction tells a story of your financial obligations and benefits."),
        SplashQuote("Understanding your payslip is the first step to understanding your financial future."),
        SplashQuote("Your gross pay shows what you earn; your net pay shows what you keep."),
        SplashQuote("Track your earnings growth month by month, year by year."),
        SplashQuote("Benefits aren't just numbers—they're part of your total compensation package."),
        
        // Financial empowerment
        SplashQuote("Knowledge is power, but financial knowledge is financial power."),
        SplashQuote("The best investment you can make is in your financial education", author: "Warren Buffett"),
        SplashQuote("Small amounts saved consistently create large fortunes over time."),
        SplashQuote("Your financial future depends on the decisions you make today."),
        SplashQuote("Track every rupee, respect every deduction, plan every saving."),
        
        // Military/Service specific
        SplashQuote("Service to nation, stewardship of finances—both require discipline and honor."),
        SplashQuote("Your allowances and benefits are earned through dedication and service."),
        SplashQuote("Military precision in financial planning leads to civilian prosperity."),
        
        // Motivation and growth
        SplashQuote("Financial literacy is not a luxury, it's a necessity", author: "John Hope Bryant"),
        SplashQuote("The goal isn't more money. The goal is living life on your terms", author: "Chris Brogan"),
        SplashQuote("Investing in yourself is the best investment you will ever make", author: "Warren Buffett"),
        SplashQuote("Don't save what is left after spending; spend what is left after saving", author: "Warren Buffett"),
        SplashQuote("Financial freedom is freedom from fear", author: "Robert Kiyosaki")
    ]
    
    /// Returns a random quote from the collection
    static func getRandomQuote() -> SplashQuote {
        return quotes.randomElement() ?? SplashQuote("Managing your finances starts with understanding your payslip.")
    }
    
    /// Returns the total number of available quotes
    static var totalQuotes: Int {
        return quotes.count
    }
} 