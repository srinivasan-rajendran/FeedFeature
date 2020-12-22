//
//  CacheFeedUseCaseTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-22.
//

import XCTest
import FeedFeature

class FeedStore {

    typealias DeletionCompletion = (Error?) -> Void

    enum ReceivedMessages: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }

    var receivedMessages = [ReceivedMessages]()
    private var deletionCompletions = [DeletionCompletion]()

    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }

    func completeDeletion(with error: Error, index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeDeletionSuccessfully(index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insertFeed(items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insert(items, timestamp))
    }
}

class LocalFeedLoader {
    let store: FeedStore
    let currentDate: () -> Date

    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    func save(items: [FeedItem], completion:@escaping (Error?) -> Void) {
        store.deleteCachedFeed { [unowned self] error in
            completion(error)
            if error == nil {
                self.store.insertFeed(items: items, timestamp: currentDate())
            }
        }
    }
}


class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCachedUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItems(), uniqueItems()]
        sut.save(items: items) { _ in }
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItems(), uniqueItems()]
        sut.save(items: items) { _ in }
        store.completeDeletion(with: anyNSError())
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [uniqueItems(), uniqueItems()]
        sut.save(items: items) { _ in }
        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [uniqueItems(), uniqueItems()]
        let deletionError = anyNSError()
        let exp = expectation(description: "wait for completion")
        sut.save(items: items) { error in
            XCTAssertEqual(error as NSError?, deletionError)
            exp.fulfill()
        }
        store.completeDeletion(with: deletionError)
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init ,file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
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

