import Foundation
import UIKit

/// Vision-capable LLM service.
protocol LLMVisionServiceProtocol {
    var provider: LLMProvider { get }
    func validateConfiguration() -> Bool
    func send(imageData: Data, mimeType: String, request: LLMRequest) async throws -> LLMResponse
}
