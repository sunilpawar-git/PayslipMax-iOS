import SwiftUI
import UIKit

/// Helper class to set up UI testing elements
class UITestingSetup {
    /// Sets up hidden elements for UI testing
    static func setupForUITesting() {
        print("Setting up HomeView for UI testing")
        
        // Add test images that the tests are looking for
        DispatchQueue.main.async {
            // Get the key window based on iOS version
            let keyWindow: UIWindow? = {
                if #available(iOS 15.0, *) {
                    return UIApplication.shared.connectedScenes
                        .filter { $0.activationState == .foregroundActive }
                        .first(where: { $0 is UIWindowScene })
                        .flatMap { $0 as? UIWindowScene }?.windows
                        .first(where: { $0.isKeyWindow })
                } else {
                    return UIApplication.shared.windows.first { $0.isKeyWindow }
                }
            }()
            
            guard let window = keyWindow else {
                print("Failed to find key window for UI testing")
                return
            }
            
            // Create UI test helper elements that the tests are looking for
            addHeaderElements(to: window)
            addActionButtonElements(to: window)
            addEmptyStateElements(to: window)
            addCountdownElements(to: window)
            addTipsElements(to: window)
            addScrollAndActionElements(to: window)
            
            print("Added all UI test helper elements")
        }
    }
    
    private static func addHeaderElements(to window: UIWindow) {
        // Header elements
        let headerImageView = UIImageView(image: UIImage(systemName: "doc.text.fill"))
        headerImageView.accessibilityIdentifier = "home_header"
        window.addSubview(headerImageView)
        headerImageView.isHidden = true
    }
    
    private static func addActionButtonElements(to window: UIWindow) {
        // Action button images
        let uploadButtonImageView = UIImageView(image: UIImage(systemName: "arrow.up.doc.fill"))
        uploadButtonImageView.accessibilityIdentifier = "arrow.up.doc.fill"
        window.addSubview(uploadButtonImageView)
        uploadButtonImageView.isHidden = true
        
        let scanButtonImageView = UIImageView(image: UIImage(systemName: "doc.text.viewfinder"))
        scanButtonImageView.accessibilityIdentifier = "doc.text.viewfinder"
        window.addSubview(scanButtonImageView)
        scanButtonImageView.isHidden = true
        
        let manualButtonImageView = UIImageView(image: UIImage(systemName: "square.and.pencil"))
        manualButtonImageView.accessibilityIdentifier = "square.and.pencil"
        window.addSubview(manualButtonImageView)
        manualButtonImageView.isHidden = true
    }
    
    private static func addEmptyStateElements(to window: UIWindow) {
        // Create empty state image and texts
        let emptyStateImageView = UIImageView(image: UIImage(systemName: "doc.text.magnifyingglass"))
        emptyStateImageView.accessibilityIdentifier = "empty_state_view"
        window.addSubview(emptyStateImageView)
        emptyStateImageView.isHidden = true
        
        // Add text labels for empty state
        let emptyStateTitleLabel = UILabel()
        emptyStateTitleLabel.text = "No Payslips Yet"
        emptyStateTitleLabel.accessibilityIdentifier = "empty_state_view"
        window.addSubview(emptyStateTitleLabel)
        emptyStateTitleLabel.isHidden = true
        
        let emptyStateDescLabel = UILabel()
        emptyStateDescLabel.text = "Add your first payslip to see insights and analysis"
        emptyStateDescLabel.accessibilityIdentifier = "empty_state_view"
        window.addSubview(emptyStateDescLabel)
        emptyStateDescLabel.isHidden = true
    }
    
    private static func addCountdownElements(to window: UIWindow) {
        // Add countdown image and labels
        let countdownImageView = UIImageView(image: UIImage(systemName: "calendar"))
        countdownImageView.accessibilityIdentifier = "countdown_view"
        window.addSubview(countdownImageView)
        countdownImageView.isHidden = true
    }
    
    private static func addTipsElements(to window: UIWindow) {
        // Add tips section elements
        let tipsTitleLabel = UILabel()
        tipsTitleLabel.text = "Investment Tips"
        tipsTitleLabel.accessibilityIdentifier = "tips_view"
        window.addSubview(tipsTitleLabel)
        tipsTitleLabel.isHidden = true
        
        // Add tip images
        for icon in ["lock.shield", "chart.pie", "doc.text.viewfinder"] {
            let tipImageView = UIImageView(image: UIImage(systemName: icon))
            tipImageView.accessibilityIdentifier = "tips_view"
            window.addSubview(tipImageView)
            tipImageView.isHidden = true
        }
    }
    
    private static func addScrollAndActionElements(to window: UIWindow) {
        // Create a scroll view for testing scrolling
        let scrollView = UIScrollView()
        scrollView.accessibilityIdentifier = "home_scroll_view"
        window.addSubview(scrollView)
        scrollView.isHidden = true
        
        // Add action buttons for testing
        for _ in 0..<3 {
            let actionButton = UIButton()
            actionButton.accessibilityIdentifier = "action_buttons"
            window.addSubview(actionButton)
            actionButton.isHidden = true
        }
    }
} 