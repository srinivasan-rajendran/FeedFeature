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
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feedItems: cache.local, timestamp: cache.date))
        } catch {
            completion(.failure(error))
        }
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
        expect(sut: sut, toRetrieve: .empty)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        expect(sut: sut, toRetrieveTwice: .empty)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let expectedItems = uniqueItems().local
        let expectedDate = Date()

        insert((expectedItems, expectedDate), to: sut)
        expect(sut: sut, toRetrieve: .found(feedItems: expectedItems, timestamp: expectedDate))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let expectedItems = uniqueItems().local
        let expectedDate = Date()

        insert((expectedItems, expectedDate), to: sut)
        expect(sut: sut, toRetrieveTwice: .found(feedItems: expectedItems, timestamp: expectedDate))
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        try! "Invalid Data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut: sut, toRetrieve: .failure(anyNSError()))
    }

    func test_retrieve_hasNoSideEffectOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        try! "Invalid Data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut: sut, toRetrieveTwice: .failure(anyNSError()))
    }

    // MARK: Helpers

    func insert(_ cache: (feed: [LocalFeedItem], timestamp: Date), to sut: CodableFeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for completion")
        sut.insertFeed(items: cache.feed, timestamp: cache.timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected Feed to be inserted Successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func expect(sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut: sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut: sut, toRetrieve: expectedResult, file: file, line: line)
    }

    func expect(sut: CodableFeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for completion")
        sut.retrieveFeed { foundResult in
            switch (foundResult, expectedResult) {
            case let (.found(foundItems, foundTimeStamp), .found(expectedItems, expectedTimestamp)):
                XCTAssertEqual(foundItems, expectedItems, file: file, line: line)
                XCTAssertEqual(foundTimeStamp, expectedTimestamp, file: file, line: line)
            case (.empty, .empty), (.failure, .failure):
                break
            default:
                XCTFail("expected to get \(expectedResult) got \(foundResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {

        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
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

