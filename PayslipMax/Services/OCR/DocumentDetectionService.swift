import Vision
import UIKit
import CoreGraphics

/// Document detection service using Vision framework APIs
class DocumentDetectionService {
    
    // MARK: - Document Boundary Detection
    func detectDocumentBounds(in image: UIImage) async -> VNRectangleObservation? {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: nil)
                return
            }
            
            let request = VNDetectRectanglesRequest { request, error in
                guard let observations = request.results as? [VNRectangleObservation],
                      let firstObservation = observations.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: firstObservation)
            }
            
            // Configure for document detection
            request.minimumAspectRatio = 0.3
            request.maximumAspectRatio = 1.7
            request.minimumSize = 0.2
            request.minimumConfidence = 0.6
            request.maximumObservations = 1
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    // MARK: - Rectangle Detection
    func detectRectangles(in image: UIImage) async -> [VNRectangleObservation] {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: [])
                return
            }
            
            let request = VNDetectRectanglesRequest { request, error in
                let observations = request.results as? [VNRectangleObservation] ?? []
                continuation.resume(returning: observations)
            }
            
            // Configure for document detection
            request.minimumAspectRatio = 0.3
            request.maximumAspectRatio = 1.7
            request.minimumSize = 0.2
            request.minimumConfidence = 0.6
            request.maximumObservations = 5
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    // MARK: - Table Detection
    func detectTables(in image: UIImage) async -> [TableRegion] {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: [])
                return
            }
            
            let request = VNDetectRectanglesRequest { request, error in
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let tableRegions = self.extractTableRegions(from: observations)
                continuation.resume(returning: tableRegions)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    // MARK: - Page Layout Analysis
    func analyzePageLayout(in image: UIImage) async -> PageLayoutAnalysis {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: PageLayoutAnalysis())
                return
            }
            
            let request = VNDetectRectanglesRequest { request, error in
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(returning: PageLayoutAnalysis())
                    return
                }
                
                let analysis = self.buildPageLayoutAnalysis(from: observations)
                continuation.resume(returning: analysis)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    // MARK: - Private Helper Methods
    private func extractTableRegions(from observations: [VNRectangleObservation]) -> [TableRegion] {
        var tableRegions: [TableRegion] = []
        
        for observation in observations {
            let regionType = classifyRegionType(observation)
            
            // Only process regions that are potential tables
            if regionType == .table {
                // Map from RegionType to TableRegionType
                let tableRegionType = mapToTableRegionType(regionType)
                
                let region = TableRegion(
                    boundingBox: observation.boundingBox,
                    regionType: tableRegionType,
                    confidence: 0.8, // VNRectangleObservation doesn't have confidence
                    cellCount: estimateCellCount(from: observation)
                )
                
                tableRegions.append(region)
            }
        }
        
        return tableRegions
    }
    
    private func classifyRegionType(_ observation: VNRectangleObservation) -> RegionType {
        let boundingBox = observation.boundingBox
        let aspectRatio = boundingBox.width / boundingBox.height
        
        // Heuristics for region classification
        if aspectRatio > 1.5 && boundingBox.height > 0.1 {
            return .table
        } else if aspectRatio < 0.5 && boundingBox.width < 0.3 {
            return .sidebar
        } else if boundingBox.height < 0.1 {
            return .header
        } else {
            return .text
        }
    }
    
    private func mapToTableRegionType(_ regionType: RegionType) -> TableRegionType {
        switch regionType {
        case .header:
            return .header
        case .table:
            return .dataRows
        case .footer:
            return .footer
        default:
            return .unknown
        }
    }
    
    private func estimateCellCount(from observation: VNRectangleObservation) -> Int {
        let boundingBox = observation.boundingBox
        let area = boundingBox.width * boundingBox.height
        
        // Rough estimation based on bounding box size
        // Larger regions likely contain more cells
        if area > 0.5 {
            return 20 // Large table region
        } else if area > 0.2 {
            return 10 // Medium table region
        } else {
            return 5  // Small table region
        }
    }
    
    private func buildPageLayoutAnalysis(from observations: [VNRectangleObservation]) -> PageLayoutAnalysis {
        var regions: [LayoutRegion] = []
        
        for observation in observations {
            let region = LayoutRegion(
                boundingBox: observation.boundingBox,
                confidence: 0.8, // VNRectangleObservation doesn't have confidence
                regionType: classifyRegionType(observation)
            )
            regions.append(region)
        }
        
        // Sort regions by position (top to bottom, left to right)
        regions.sort { region1, region2 in
            if abs(region1.boundingBox.minY - region2.boundingBox.minY) < 0.05 {
                return region1.boundingBox.minX < region2.boundingBox.minX
            }
            return region1.boundingBox.minY > region2.boundingBox.minY
        }
        
        return PageLayoutAnalysis(
            regions: regions,
            pageStructure: determinePageStructure(regions),
            documentType: inferDocumentType(regions)
        )
    }
    
    private func determinePageStructure(_ regions: [LayoutRegion]) -> PageStructure {
        let tableCount = regions.filter { $0.regionType == .table }.count
        let textRegionCount = regions.filter { $0.regionType == .text }.count
        
        if tableCount > 2 {
            return .multiTable
        } else if tableCount == 1 {
            return .singleTable
        } else if textRegionCount > 5 {
            return .textHeavy
        } else {
            return .mixed
        }
    }
    
    private func inferDocumentType(_ regions: [LayoutRegion]) -> DocumentType {
        let tableRegions = regions.filter { $0.regionType == .table }
        
        if tableRegions.count >= 2 {
            return .payslip
        } else if tableRegions.count == 1 && tableRegions.first!.boundingBox.height > 0.3 {
            return .financialStatement
        } else {
            return .general
        }
    }
}

// MARK: - Supporting Data Models
struct LayoutRegion {
    let boundingBox: CGRect
    let confidence: Float
    let regionType: RegionType
}

struct PageLayoutAnalysis {
    let regions: [LayoutRegion]
    let pageStructure: PageStructure
    let documentType: DocumentType
    
    init(regions: [LayoutRegion] = [], pageStructure: PageStructure = .mixed, documentType: DocumentType = .general) {
        self.regions = regions
        self.pageStructure = pageStructure
        self.documentType = documentType
    }
}

enum RegionType {
    case header
    case text
    case table
    case sidebar
    case footer
}

enum PageStructure {
    case singleTable
    case multiTable
    case textHeavy
    case mixed
}

enum DocumentType {
    case payslip
    case financialStatement
    case invoice
    case general
}