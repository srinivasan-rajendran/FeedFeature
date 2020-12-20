//
//  URLSessionHTTPClientTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-20.
//

import XCTest
import FeedFeature

class URLSessionHTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    struct UnexpectedValuesRepresentation: Error {}

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterecptingRequests()
    }

    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterecptingRequests()
    }

    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        let anyData = Data("any data".utf8)
        let anynonHTTPURLResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyHTTPURLResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
        let anyError = NSError(domain: "any error", code: 0)

        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anynonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anynonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anynonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anynonHTTPURLResponse, error: nil))

    }

    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let sut = makeSUT()
        let exp = expectation(description: "wait for request completion")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        sut.get(from: url) { _ in }
        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_failsOnRequestError() { // Data - nil, response - nil, error - valid
        let requestError = NSError(domain: "test", code: 1)
        let returnedError = resultErrorFor(data: nil, response: nil, error: requestError)
        XCTAssertEqual(requestError, returnedError as NSError?)
    }

    // MARK: Helpers

    private func resultErrorFor(data: Data?,
                                response: URLResponse?,
                                error: Error?, file: StaticString = #filePath,
                                line: UInt = #line) -> Error? {
        let url = anyURL()
        let sut = makeSUT(file: file, line: line)
        URLProtocolStub.stub(data: data, response: response, error: error)
        let exp = expectation(description: "wait for request completion")
        var returnedError: Error?
        sut.get(from: url) { result in
            switch result {
            case let .failure(error):
                returnedError = error
            default:
                XCTFail("expected failure, got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return returnedError
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func anyURL() -> URL {
        return URL(string: "https://example.com")!
    }

    private class URLProtocolStub: URLProtocol {

        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}

        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func startInterecptingRequests() {
            URLProtocolStub.registerClass(URLProtocolStub.self)
        }

        static func stopInterecptingRequests() {
            URLProtocolStub.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
    }
}

