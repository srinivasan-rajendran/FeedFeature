//
//  RemoteFeedLoaderTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-15.
//

import XCTest
import FeedFeature

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestDataFromURL() {
        let url = URL(string: "https://example.com")!
        let (sut, client) = makeSUT()

        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestDataFromURLTwice() {
        let url = URL(string: "https://example.com")!
        let (sut, client) = makeSUT()

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversConnectivityError() {
        let (sut, client) = makeSUT()
        expect(sut: sut, toCompleteWithResult: .failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_deliversError_whenResponseStatusNot200() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut: sut, toCompleteWithResult: .failure(.invalidData)) {
                client.compete(withStatusCode: code, at: index)
            }
        }
    }

    func test_load_deliversError_on200Status_invalidJSON() {
        let (sut, client) = makeSUT()
        expect(sut: sut, toCompleteWithResult: .failure(.invalidData)) {
            let invalidJSON = Data("invalid".utf8)
            client.compete(withStatusCode: 200, data: invalidJSON)
        }
    }

    func test_load_deliversNoItemsOn200StatusWithEmptyJsonList() {
        let (sut, client) = makeSUT()
        expect(sut: sut, toCompleteWithResult: RemoteFeedLoader.Result.success([])) {
            let validJsonEmptyItems = Data("{\"items\": []}".utf8)
            client.compete(withStatusCode: 200, data: validJsonEmptyItems)
        }
    }

    func test_load_on200StatusWithValidItems() {
        let (sut, client) = makeSUT()
        let item1 = FeedItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://test.com")!)
        let item2 = FeedItem(id: UUID(), description: "description sample", location: "stockholm", imageURL: URL(string: "https://test1.com")!)
        expect(sut: sut, toCompleteWithResult: .success([item1, item2])) {
            let jsonItem1 = [
                "id": item1.id.uuidString,
                "image": item1.imageURL.absoluteString
            ]
            let jsonItem2 = [
                "id": item2.id.uuidString,
                "description": item2.description,
                "location": item2.location,
                "image": item2.imageURL.absoluteString
            ]
            let jsonItems = [
                "items": [jsonItem1, jsonItem2]
            ]
            let jsonData = try! JSONSerialization.data(withJSONObject: jsonItems, options: .prettyPrinted)
            client.compete(withStatusCode: 200, data: jsonData)
        }
    }

    // MARK: Helpers

    private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        return (RemoteFeedLoader(url: url, client: client), client)
    }

    private func expect(sut: RemoteFeedLoader, toCompleteWithResult result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { result in
            capturedResults.append(result)
        }
        action()
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }

    private class HTTPClientSpy: HTTPClient {

        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func compete(withStatusCode code: Int, data: Data = Data(),  at index: Int = 0) {
            let urlResponse = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, urlResponse))
        }
    }

}
