//
//  CodableFeedStoreTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-26.
//

import XCTest
import FeedFeature

class CodableFeedStore {

    private let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    private struct Cache: Codable {
        let items: [CodableFeedItem]
        let date: Date
        var local: [LocalFeedItem] {
            return items.map { $0.localFeedItem }
        }
    }

    private struct CodableFeedItem: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let imageURL: URL

        init(item: LocalFeedItem) {
            id = item.id
            description = item.description
            location = item.location
            imageURL = item.imageURL
        }

        var localFeedItem: LocalFeedItem {
            return LocalFeedItem(id: id, description: description, location: location, imageURL: imageURL)
        }
    }
    
    func retrieveFeed(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feedItems: cache.local, timestamp: cache.date))
    }

    func insertFeed(items: [LocalFeedItem], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encodedCache = try! encoder.encode(Cache(items: items.map { CodableFeedItem.init(item: $0) }, date: timestamp))
        try! encodedCache.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        setUpEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
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
        let sut = makeSUT()
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
        let sut = makeSUT()
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

    // MARK: Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {

        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }

    private func setUpEmptyStoreState() {
        deleteStoreArtificats()
    }

    private func undoStoreSideEffects() {
       deleteStoreArtificats()
    }

    private func deleteStoreArtificats() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }

}

