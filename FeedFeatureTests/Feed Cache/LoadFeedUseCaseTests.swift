//
//  LoadFeedUseCaseTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-25.
//

import XCTest
import FeedFeature

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreOnCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_shouldRequestCacheRetrieval() {
        let (sut, store) = makeSUT()
        sut.load() { _ in }
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let expectedError = anyNSError()
        expect(sut: sut, toCompleteWith: .failure(expectedError)) {
            store.completeRetrieval(with: expectedError)
        }
    }

    func test_load_deliversNoItemsOnEmptyCache() {
        let (sut, store) = makeSUT()
        expect(sut: sut, toCompleteWith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }

    func test_load_deliversItemsOnCacheLessThanSevenDaysOld() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT( currentDate: { fixedCurrentDate } )
        let items = uniqueItems()
        expect(sut: sut, toCompleteWith: .success(items.models)) {
            store.completeRetrieval(localItems: items.local, timestamp: lessThanSevenDaysOldTimestamp)
        }
    }

    func test_load_deliversNoImagesOnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT( currentDate: { fixedCurrentDate } )
        let items = uniqueItems()
        expect(sut: sut, toCompleteWith: .success([])) {
            store.completeRetrieval(localItems: items.local, timestamp: sevenDaysOldTimestamp)
        }
    }

    func test_load_deliversNoImagesOnMoreThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT( currentDate: { fixedCurrentDate } )
        let items = uniqueItems()
        expect(sut: sut, toCompleteWith: .success([])) {
            store.completeRetrieval(localItems: items.local, timestamp: moreThanSevenDaysOldTimestamp)
        }
    }

    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnLessThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT( currentDate: { fixedCurrentDate } )
        sut.load { _ in }
        let items = uniqueItems()
        store.completeRetrieval(localItems: items.local, timestamp: lessThanSevenDaysOldTimestamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_shouldDeleteCacheOnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT( currentDate: { fixedCurrentDate } )
        sut.load { _ in }
        let items = uniqueItems()
        store.completeRetrieval(localItems: items.local, timestamp: sevenDaysOldTimestamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_load_shouldDeleteCacheOnMoreThanSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT( currentDate: { fixedCurrentDate } )
        sut.load { _ in }
        let items = uniqueItems()
        store.completeRetrieval(localItems: items.local, timestamp: sevenDaysOldTimestamp)
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_load_doesNotDeliverCompletionWhenSUTIsDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }
        sut = nil
        store.completeRetrieval(with: anyNSError())
        XCTAssertTrue(receivedResults.isEmpty)
    }

    // MARK: Helpers

    private func expect(sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, actions: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as NSError?, expectedError as NSError?, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        actions()
        wait(for: [exp], timeout: 1.0)
    }

    private func uniqueItems() -> (models: [FeedItem], local: [LocalFeedItem]) {
        let items = [uniqueItem(), uniqueItem()]
        let local = items.map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL) }
        return (items, local)
    }

    private func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }

    private func anyURL() -> URL {
        return URL(string: "https://example.com")!
    }

    private func makeSUT(currentDate: @escaping () -> Date = Date.init ,file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut,file: file, line: line)
        trackForMemoryLeaks(store,file: file, line: line)
        return (sut, store)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
