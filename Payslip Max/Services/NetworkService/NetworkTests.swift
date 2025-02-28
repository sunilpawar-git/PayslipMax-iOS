import XCTest
@testable import Payslip_Max

/// Tests for the network service
class NetworkTests: XCTestCase {
    /// The network service to test
    var networkService: NetworkServiceProtocol!
    
    /// Set up before each test
    override func setUp() {
        super.setUp()
        
        // Create a test URL session configuration
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        
        // Create a test URL session
        let session = URLSession(configuration: configuration)
        
        // Create the network service with the test session
        networkService = BasicNetworkService(session: session)
    }
    
    /// Tear down after each test
    override func tearDown() {
        networkService = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    /// Test GET request
    func testGetRequest() async {
        // Arrange
        let expectation = XCTestExpectation(description: "GET request")
        let testData = "Test data".data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, testData)
        }
        
        do {
            // Act
            let data = try await networkService.get(from: "https://example.com/test")
            
            // Assert
            XCTAssertEqual(data, testData)
            expectation.fulfill()
        } catch {
            XCTFail("Request failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}

/// Mock URL protocol for testing
class MockURLProtocol: URLProtocol {
    /// Handler for mock requests
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    /// Determines if this protocol can handle the given request
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    /// Returns a canonical version of the given request
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    /// Starts loading the request
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }
        
        do {
            let (response, data) = try handler(request)
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    /// Stops loading the request
    override func stopLoading() {
        // No-op
    }
} 