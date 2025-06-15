import Foundation
import CoreImage
import UIKit
import AVFoundation

/// Service for generating and scanning QR codes for backup sharing
class QRCodeService: ObservableObject {
    
    /// Generate QR code image from backup info
    func generateQRCode(from backupInfo: BackupQRInfo, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        guard let qrData = backupInfo.qrCodeData else {
            print("Failed to encode backup info to data")
            return nil
        }
        
        return generateQRCodeImage(from: qrData, size: size)
    }
    
    /// Generate QR code image from raw data
    func generateQRCodeImage(from data: Data, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        // Create CIFilter for QR code generation
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            print("Failed to create QR code filter")
            return nil
        }
        
        // Set input data
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        // Get output image
        guard let ciImage = filter.outputImage else {
            print("Failed to generate QR code image")
            return nil
        }
        
        // Scale the image to desired size
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            print("Failed to create CGImage from CIImage")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Parse backup info from QR code data
    static func parseBackupInfo(from data: Data) -> BackupQRInfo? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let backupInfo = try decoder.decode(BackupQRInfo.self, from: data)
            
            // Validate expiration
            if backupInfo.expiresAt < Date() {
                print("QR code has expired")
                return nil
            }
            
            return backupInfo
        } catch {
            print("Failed to decode backup info from QR data: \(error)")
            return nil
        }
    }
    
    /// Generate a shareable QR code with backup metadata for display
    func generateShareableQRCode(
        from backupInfo: BackupQRInfo,
        size: CGSize = CGSize(width: 300, height: 300),
        includeText: Bool = true
    ) -> UIImage? {
        guard let qrImage = generateQRCode(from: backupInfo, size: size) else {
            return nil
        }
        
        if !includeText {
            return qrImage
        }
        
        // Create image with text
        return addMetadataText(to: qrImage, backupInfo: backupInfo)
    }
    
    /// Add metadata text below QR code
    private func addMetadataText(to qrImage: UIImage, backupInfo: BackupQRInfo) -> UIImage? {
        let textHeight: CGFloat = 100
        let padding: CGFloat = 20
        let totalHeight = qrImage.size.height + textHeight + (padding * 2)
        let totalSize = CGSize(width: qrImage.size.width + (padding * 2), height: totalHeight)
        
        UIGraphicsBeginImageContextWithOptions(totalSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Fill background
        context.setFillColor(UIColor.systemBackground.cgColor)
        context.fill(CGRect(origin: .zero, size: totalSize))
        
        // Draw QR code
        let qrRect = CGRect(
            x: padding,
            y: padding,
            width: qrImage.size.width,
            height: qrImage.size.height
        )
        qrImage.draw(in: qrRect)
        
        // Draw text
        let textRect = CGRect(
            x: padding,
            y: qrImage.size.height + padding + 10,
            width: qrImage.size.width,
            height: textHeight - 10
        )
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.label
        ]
        
        let text = """
        PayslipMax Backup
        \(backupInfo.metadata.totalPayslips) payslips
        \(backupInfo.metadata.dateRange.formattedRange)
        Size: \(backupInfo.metadata.estimatedSize / 1024)KB
        """
        
        text.draw(in: textRect, withAttributes: attributes)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - QR Code Scanner

/// Protocol for QR code scanning delegate
protocol QRCodeScannerDelegate: AnyObject {
    func qrCodeScanner(_ scanner: QRCodeScanner, didScanBackupInfo backupInfo: BackupQRInfo)
    func qrCodeScanner(_ scanner: QRCodeScanner, didFailWithError error: Error)
}

/// QR Code scanner for backup import
class QRCodeScanner: NSObject, ObservableObject {
    
    weak var delegate: QRCodeScannerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    /// Start scanning for QR codes
    func startScanning() throws {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            throw QRCodeError.cameraNotAvailable
        }
        
        let captureSession = AVCaptureSession()
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
        } catch {
            throw QRCodeError.failedToInitializeCamera(error)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        
        self.captureSession = captureSession
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    /// Stop scanning
    func stopScanning() {
        captureSession?.stopRunning()
        captureSession = nil
    }
    
    /// Get preview layer for camera display
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let captureSession = captureSession else { return nil }
        
        if videoPreviewLayer == nil {
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
        }
        
        return videoPreviewLayer
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let stringValue = metadataObject.stringValue,
              let data = stringValue.data(using: .utf8) else {
            return
        }
        
        // Parse backup info
        if let backupInfo = QRCodeService.parseBackupInfo(from: data) {
            delegate?.qrCodeScanner(self, didScanBackupInfo: backupInfo)
        } else {
            delegate?.qrCodeScanner(self, didFailWithError: QRCodeError.invalidQRCode)
        }
    }
}

// MARK: - Error Types

enum QRCodeError: Error, LocalizedError {
    case cameraNotAvailable
    case failedToInitializeCamera(Error)
    case invalidQRCode
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available on this device"
        case .failedToInitializeCamera(let error):
            return "Failed to initialize camera: \(error.localizedDescription)"
        case .invalidQRCode:
            return "Invalid or expired backup QR code"
        case .permissionDenied:
            return "Camera permission is required to scan QR codes"
        }
    }
} 