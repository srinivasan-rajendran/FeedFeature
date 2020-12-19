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

        sut.loadFeed { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestDataFromURLTwice() {
        let url = URL(string: "https://example.com")!
        let (sut, client) = makeSUT()

        sut.loadFeed { _ in }
        sut.loadFeed { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversConnectivityError() {
        let (sut, client) = makeSUT()
        expect(sut: sut, toCompleteWithResult: failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_deliversError_whenResponseStatusNot200() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut: sut, toCompleteWithResult: failure(.invalidData)) {
                let data = makeDataFromJSONItems(jsonItems: [])
                client.compete(withStatusCode: code, data: data, at: index)
            }
        }
    }

    func test_load_deliversError_on200Status_invalidJSON() {
        let (sut, client) = makeSUT()
        expect(sut: sut, toCompleteWithResult:  failure(.invalidData)) {
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
        let item1 = makeItem(id: UUID(), imageURL: URL(string: "https://test1.com")!)
        let item2 = makeItem(id: UUID(), description: "description sample", location: "stockholm", imageURL: URL(string: "https://test2.com")!)
        let itemsModel = [item1.model, item2.model]
        expect(sut: sut, toCompleteWithResult: .success(itemsModel)) {
            let jsonData = makeDataFromJSONItems(jsonItems: [item1.json, item2.json])
            client.compete(withStatusCode: 200, data: jsonData)
        }
    }

    func test_load_doesNotDeliverResultAfterSUTINstanceHasBeenDeallocated() {
        let url = URL(string: "https://example.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.loadFeed { capturedResults.append($0) }

        sut = nil
        client.compete(withStatusCode: 200, data: makeDataFromJSONItems(jsonItems: []))

        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: Helpers

    private func makeDataFromJSONItems(jsonItems: [[String: Any]]) -> Data {
        let jsonItems = [
            "items": jsonItems
        ]
        return try! JSONSerialization.data(withJSONObject: jsonItems, options: .prettyPrinted)
    }

    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let model = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { acc, e in
            if let value = e.value {
                acc[e.key] = value
            }
        }
        return (model, json)
    }

    private func makeSUT(url: URL = URL(string: "https://example.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(sut,file: file, line: line)
        trackForMemoryLeaks(client,file: file, line: line)
        return (sut, client)
    }

    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak", file: file, line: line)
        }
    }

    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }

    private func expect(sut: RemoteFeedLoader, toCompleteWithResult expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for load completion")
        sut.loadFeed { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) but received \(receivedResult)", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
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

        func compete(withStatusCode code: Int, data: Data,  at index: Int = 0) {
            let urlResponse = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, urlResponse))
        }
    }

}
