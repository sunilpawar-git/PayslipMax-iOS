import XCTest
@testable import Payslip_Max

/// Tests for the network service
class NetworkTests: XCTestCase {
    /// The network service to test
    var networkService: NetworkServiceProtocol!
    
    /// Set up before each test
    override func setUp() {
        super.setUp()
        // Use a mock URL session for testing
        networkService = BasicNetworkService(session: URLSession.shared)
    }
    
    /// Tear down after each test
    override func tearDown() {
        networkService = nil
        super.tearDown()
    }
    
    /// Test GET request
    func testGetRequest() {
        // Create an expectation for the async network call
        let expectation = self.expectation(description: "GET request")
        
        // Setup mock data
        let testData = "Test response".data(using: .utf8)!
        let mockURL = URL(string: "https://api.example.com/test")!
        
        // Configure mock URL protocol
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url, mockURL)
            XCTAssertEqual(request.httpMethod, "GET")
            
            let response = HTTPURLResponse(url: mockURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, testData)
        }
        
        // Perform the GET request
        networkService.get(from: mockURL) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, testData)
            case .failure(let error):
                XCTFail("GET request failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        waitForExpectations(timeout: 5.0, handler: nil)
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
        // This is called when the request is canceled or completed
    }
} 