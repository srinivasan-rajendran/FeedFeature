//
//  URLSessionHTTPClientTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-20.
//

import XCTest
import FeedFeature

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    let session: HTTPSession

    init(session: HTTPSession) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "https://example.com")!
        let session = HTTPSessionSpy()
        let task = HTTPSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url) { _ in }
        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://example.com")!
        let session = HTTPSessionSpy()
        let error = NSError(domain: "test", code: 1)
        session.stub(url: url, error: error)
        let sut = URLSessionHTTPClient(session: session)

        let exp = expectation(description: "wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(error, receivedError)
            default:
                XCTFail("assert failed received \(result) but expected \(error)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private class HTTPSessionSpy: HTTPSession {

        private struct Stub {
            let task: HTTPSessionTask
            let error: Error?
        }

        private var stubs = [URL: Stub]()

        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            guard let stub = stubs[url] else {
                fatalError("Couldnt find a stub for given url \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }

        func stub(url: URL, task: HTTPSessionTask = FakeHTTPSessionDataTask(), error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
    }

    private class FakeHTTPSessionDataTask: HTTPSessionTask {
        func resume() {}
    }

    private class HTTPSessionDataTaskSpy: HTTPSessionTask {
        var resumeCallCount = 0
        func resume() {
            resumeCallCount += 1
        }
    }
}

