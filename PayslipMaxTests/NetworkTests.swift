import XCTest
@testable import Payslip_Max

/// Tests for the network service
final class NetworkTests: XCTestCase {
    /// The network service to test
    var networkService: MockNetworkService!
    
    /// Set up before each test
    override func setUp() {
        super.setUp()
        
        // Create a configuration with the mock URL protocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        // Initialize the network service with the mock session
        networkService = MockNetworkService()
    }
    
    /// Tear down after each test
    override func tearDown() {
        networkService = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    /// Test GET request with async/await
    func testGetRequest() async throws {
        // Prepare test data
        let testData = """
        {
            "status": "success",
            "data": {
                "id": 123,
                "name": "Test User"
            }
        }
        """.data(using: .utf8)!
        
        // Set up the URL for the test
        let urlString = "https://api.example.com/test"
        let url = URL(string: urlString)!
        
        // Configure the mock to return our test data
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, testData)
        }
        
        // Set the response data for the mock service
        networkService.responseData = testData
        
        // Perform the network request
        let result = try await networkService.get(url: url, headers: nil)
        
        // Verify the result matches our test data
        XCTAssertEqual(result, testData, "The returned data should match the test data")
        XCTAssertEqual(networkService.lastURL, url)
        XCTAssertEqual(networkService.lastMethod, "GET")
    }
}

/// Mock URL protocol for testing
class MockURLProtocol: URLProtocol {
    /// Handler for mock requests
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    /// Determines if this protocol can handle the given request
    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all requests
        return true
    }
    
    /// Returns a canonical version of the given request
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Return the original request
        return request
    }
    
    /// Starts loading the request
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }
        
        do {
            // Call the handler to get the mock response and data
            let (response, data) = try handler(request)
            
            // Send the response to the client
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            // Send the data to the client
            client?.urlProtocol(self, didLoad: data)
            
            // Notify the client that loading is complete
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            // If an error occurs, send it to the client
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    /// Stops loading the request
    override func stopLoading() {
        // This is called when the request is canceled or completed
        // No action needed for the mock
    }
} 