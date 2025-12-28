import SwiftUI
import PhotosUI

/// A modern photo picker that opens gallery-first (WhatsApp-style)
/// with privacy-focused education for first-time users
struct ModernPhotoPickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ModernPhotoPickerView

        init(_ parent: ModernPhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                parent.onCancel()
                return
            }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                if let error = error {
                    ErrorLogger.log(error)
                    DispatchQueue.main.async {
                        self?.parent.onCancel()
                    }
                    return
                }

                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self?.parent.onImageSelected(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.parent.onCancel()
                    }
                }
            }
        }
    }
}
