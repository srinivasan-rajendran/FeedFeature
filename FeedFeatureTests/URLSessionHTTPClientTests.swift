//
//  URLSessionHTTPClientTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-20.
//

import XCTest

class URLSessionHTTPClient {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in }
    }
}

class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_createDataTaskWithURL() {
        let url = URL(string: "https://example.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        XCTAssertEqual([url], session.receivedURLs)
    }

    private class URLSessionSpy: URLSession {
        var receivedURLs = [URL]()
        override init() { }

        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            return FakeURLSessionDataTask()
        }
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {
        override init() { }
    }
}

