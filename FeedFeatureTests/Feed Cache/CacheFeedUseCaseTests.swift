//
//  CacheFeedUseCaseTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-22.
//

import XCTest
import FeedFeature

class FeedStore {
    var deleteCachedFeedCallCount = 0
    var insertCachedFeedCallCount = 0

    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }

    func completeDeletion(with error: Error, index: Int = 0) {

    }
}

class LocalFeedLoader {
    let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }

    func save(items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}


class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCachedUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        sut.save(items: [uniqueItems(), uniqueItems()])
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        sut.save(items: [uniqueItems(), uniqueItems()])
        store.completeDeletion(with: anyNSError())
        XCTAssertEqual(store.insertCachedFeedCallCount, 0)
    }


    // MARK: Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeaks(sut,file: file, line: line)
        trackForMemoryLeaks(store,file: file, line: line)
        return (sut, store)
    }

    private func uniqueItems() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://example.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

}

