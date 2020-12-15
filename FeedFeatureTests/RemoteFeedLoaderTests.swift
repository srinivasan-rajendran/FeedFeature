//
//  RemoteFeedLoaderTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-15.
//

import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    let url: URL

    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestDataFromURL() {
        let url = URL(string: "https://example.com")!
        let (sut, client) = makeSUT()

        sut.load()

        XCTAssertEqual(client.requestedURL, url)
    }

    // MARK: Helpers

    private func makeSUT(url: URL = URL(string: "https://example.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        return (RemoteFeedLoader(url: url, client: client), client)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?

        func get(from url: URL) {
            requestedURL = url
        }
    }

}
