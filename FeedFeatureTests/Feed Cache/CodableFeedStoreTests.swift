//
//  CodableFeedStoreTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-26.
//

import XCTest
import FeedFeature

class CodableFeedStore {

    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")

    private struct Cache: Codable {
        let items: [LocalFeedItem]
        let date: Date
    }
    
    func retrieveFeed(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feedItems: cache.items, timestamp: cache.date))
    }

    func insertFeed(items: [LocalFeedItem], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encodedCache = try! encoder.encode(Cache(items: items, date: timestamp))
        try! encodedCache.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "wait for completion")
        sut.retrieveFeed { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "wait for completion")
        sut.retrieveFeed { firstResult in
            sut.retrieveFeed { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected retrieving twice from empty cache to deliver empty result, got \(firstResult) and \(secondResult) instead")
                }
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = CodableFeedStore()
        let expectedItems = uniqueItems().local
        let expectedDate = Date()
        let exp = expectation(description: "wait for completion")
        sut.insertFeed(items: expectedItems, timestamp: expectedDate) { insertionError in
            XCTAssertNil(insertionError, "Expected Feed to be inserted Successfully")
            sut.retrieveFeed { result in
                switch result {
                case let .found(retrievedItems, timestamp):
                    XCTAssertEqual(expectedItems, retrievedItems)
                    XCTAssertEqual(expectedDate, timestamp)
                default:
                    XCTFail("Expected \(expectedItems), received \(result) instead")
                }
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }

}

