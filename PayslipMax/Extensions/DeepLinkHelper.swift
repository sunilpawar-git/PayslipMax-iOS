import Foundation
import SwiftUI

/// Utility class for working with deep links
struct DeepLinkHelper {
    
    private static let scheme = "payslipmax"
    
    /// Open a deep link
    static func open(path: String, queryItems: [URLQueryItem] = []) {
        var components = URLComponents()
        
        components.scheme = scheme
        components.host = ""
        components.path = path
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else { return }
        
        #if DEBUG
        print("Opening deep link: \(url.absoluteString)")
        #endif
        
        // Use environment value in calling view
        // Example usage:
        // @Environment(\.openURL) private var openURL
        // DeepLinkHelper.makeURL(...) { url in openURL(url) }
    }
    
    /// Generate a deep link URL and call the completion handler with it
    static func makeURL(path: String, queryItems: [URLQueryItem] = [], completion: (URL) -> Void) {
        var components = URLComponents()
        components.scheme = scheme
        components.host = ""
        components.path = path
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        if let url = components.url {
            completion(url)
        }
    }
    
    /// Generate a payslip deep link URL
    static func payslipURL(id: UUID) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = ""
        components.path = "/payslip"
        components.queryItems = [URLQueryItem(name: "id", value: id.uuidString)]
        return components.url
    }
    
    /// Generate a home tab deep link URL
    static func homeURL() -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = ""
        components.path = "/home"
        return components.url
    }
    
    /// Generate a payslips tab deep link URL
    static func payslipsURL() -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = ""
        components.path = "/payslips"
        return components.url
    }
    
    /// Generate an insights tab deep link URL
    static func insightsURL() -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = ""
        components.path = "/insights"
        return components.url
    }
    
    /// Generate a settings tab deep link URL
    static func settingsURL() -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = ""
        components.path = "/settings"
        return components.url
    }
    
    /// Generate a privacy policy deep link URL
    static func privacyURL() -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = ""
        components.path = "/privacy"
        return components.url
    }
    
    /// Generate a terms of service deep link URL
    static func termsURL() -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = ""
        components.path = "/terms"
        return components.url
    }
} 