//
//  ValidateFeedCacheUseCaseTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-25.
//

import XCTest
import FeedFeature

class ValidateFeedCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreOnCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        store.completeRetrieval(with: anyNSError())
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    // MARK: Helpers

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private func makeSUT(currentDate: @escaping () -> Date = Date.init ,file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut,file: file, line: line)
        trackForMemoryLeaks(store,file: file, line: line)
        return (sut, store)
    }

}
