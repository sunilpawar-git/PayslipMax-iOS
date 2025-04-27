import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Platform-independent typealias for UI-related types
public enum PlatformTypes {
    /// Represents an image across platforms
    #if canImport(UIKit)
    public typealias Image = UIImage
    #elseif canImport(AppKit)
    public typealias Image = NSImage
    #endif
    
    /// Represents a color across platforms
    #if canImport(UIKit)
    public typealias Color = UIColor
    #elseif canImport(AppKit)
    public typealias Color = NSColor
    #endif
    
    /// Represents a font across platforms
    #if canImport(UIKit)
    public typealias Font = UIFont
    #elseif canImport(AppKit)
    public typealias Font = NSFont
    #endif
    
    /// Represents a bezier path across platforms
    #if canImport(UIKit)
    public typealias BezierPath = UIBezierPath
    #elseif canImport(AppKit)
    public typealias BezierPath = NSBezierPath
    #endif
    
    /// Represents a view across platforms
    #if canImport(UIKit)
    public typealias View = UIView
    #elseif canImport(AppKit)
    public typealias View = NSView
    #endif
}

/// Platform-independent utility methods related to UI types
public extension PlatformTypes {
    /// Static method to get CGImage from a platform-specific image
    /// This avoids the recursion issues with instance extensions
    static func getCGImage(from image: Image) -> CGImage? {
        #if canImport(UIKit)
        return (image as UIImage).cgImage
        #elseif canImport(AppKit)
        var imageRect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        #endif
    }
}

/// Provides platform-independent functionality for rendering PDF data.
public enum PDFRenderer {
    /// Creates PDF data from the given closure
    /// - Parameters:
    ///   - bounds: The bounds for the PDF
    ///   - drawingHandler: Closure that performs the drawing
    /// - Returns: The generated PDF data
    public static func createPDFData(bounds: CGRect, drawingHandler: (CGContext) -> Void) -> Data {
        #if canImport(UIKit)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        return renderer.pdfData { context in
            drawingHandler(context.cgContext)
        }
        #elseif canImport(AppKit)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            return Data()
        }
        
        var mediaBox = bounds
        guard let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }
        
        pdfContext.beginPage(mediaBox: &mediaBox)
        drawingHandler(pdfContext)
        pdfContext.endPage()
        pdfContext.closePDF()
        
        return data as Data
        #endif
    }
} 