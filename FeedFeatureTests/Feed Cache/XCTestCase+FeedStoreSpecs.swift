//
//  XCTestCase+FeedStoreSpecs.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-27.
//

import XCTest
import FeedFeature

extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
    func delete(_ sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        var deletionError: Error?
        let exp = expectation(description: "wait for completion")
        sut.deleteCachedFeed { receivedDeletionerror in
            deletionError = receivedDeletionerror
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }

    @discardableResult
    func insert(_ cache: (feed: [LocalFeedItem], timestamp: Date), to sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        var insertionError: Error?
        let exp = expectation(description: "wait for completion")
        sut.insertFeed(items: cache.feed, timestamp: cache.timestamp) { receviedInsertionError in
            insertionError = receviedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
}
