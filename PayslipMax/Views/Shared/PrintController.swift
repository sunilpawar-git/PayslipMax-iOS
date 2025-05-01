import SwiftUI
import UIKit

/// A UIViewControllerRepresentable that triggers the print dialog from SwiftUI
struct PrintController: UIViewControllerRepresentable {
    var viewModel: PayslipDetailViewModel
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Create a simple, empty view controller
        let viewController = UIViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Trigger print dialog when the controller is updated
        viewModel.printPDF(from: uiViewController)
    }
} 