//
//  XCTestCase+FeedStoreSpecs.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-27.
//

import XCTest
import FeedFeature

extension FeedStoreSpecs where Self: XCTestCase {

    func assertThatRetrieveReturnsEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut: sut, toRetrieve: .success(.none))
    }

    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut: sut, toRetrieveTwice: .success(.none))
    }

    func assertThatRetrieveDeliversFoundValuesOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let expectedItems = uniqueItems().local
        let expectedDate = Date()

        insert((expectedItems, expectedDate), to: sut)
        expect(sut: sut, toRetrieve: .success(.some(CachedFeed(feed: expectedItems, timestamp: expectedDate))))
    }

    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let expectedItems = uniqueItems().local
        let expectedDate = Date()

        insert((expectedItems, expectedDate), to: sut)
        expect(sut: sut, toRetrieveTwice: .success(.some(CachedFeed(feed: expectedItems, timestamp: expectedDate))))
    }

    func assertThatRetrievalDeliversFailureOnRetrievalError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut: sut, toRetrieve: .failure(anyNSError()))
    }

    func assertThatRetrievalHasNoSideEffectsOnRetrievalError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut: sut, toRetrieveTwice: .failure(anyNSError()))
    }

    func asserThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let insertionError = insert((uniqueItems().local, Date()), to: sut)
        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }

    func asserThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueItems().local, Date()), to: sut)
        let insertionError = insert((uniqueItems().local, Date()), to: sut)
        XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
    }

    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueItems().local, Date()), to: sut)
        let newItems = uniqueItems().local
        let newTimeStamp = Date()
        insert((newItems, newTimeStamp), to: sut)
        expect(sut: sut, toRetrieve: .success(.some(CachedFeed(feed: newItems, timestamp: newTimeStamp))), file: file, line: line)
    }

    func assertThatInsertionDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let insertionError = insert((uniqueItems().local, Date()), to: sut)
        XCTAssertNotNil(insertionError, "Expected Cache insertion to fail with an error")
    }

    func assertThatInsertionHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueItems().local, Date()), to: sut)
        expect(sut: sut, toRetrieve: .success(.none))
    }

    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let deletionError = delete(sut)
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
    }

    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        delete(sut)
        expect(sut: sut, toRetrieve: .success(.none), file: file, line: line)
    }

    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueItems().local, Date()), to: sut)
        let deletionError = delete(sut)
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
    }

    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueItems().local, Date()), to: sut)
        delete(sut)
        expect(sut: sut, toRetrieve: .success(.none), file: file, line: line)
    }

    func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let deletionError = delete(sut)
        XCTAssertNotNil(deletionError, "Expected Cache Deletion to fail", file: file, line: line)
    }

    func assertThatDeleteHasNoSideEffectOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        delete(sut)
        expect(sut: sut, toRetrieve: .success(.none), file: file, line: line)
    }

    func assertThatSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        var completedOperationsInOrder = [XCTestExpectation]()

        let op1 = expectation(description: "Operation 1")
        sut.insertFeed(items: uniqueItems().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "Operation 3")
        sut.insertFeed(items: uniqueItems().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }

        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side effects to run serially, but operations finished in wrong order", file: file, line: line)
    }



    func expect(sut: FeedStore, toRetrieveTwice expectedResult: FeedStore.RetrievalResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut: sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut: sut, toRetrieve: expectedResult, file: file, line: line)
    }

    func expect(sut: FeedStore, toRetrieve expectedResult: FeedStore.RetrievalResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "wait for completion")
        sut.retrieveFeed { foundResult in
            switch (foundResult, expectedResult) {
            case let (.success(.some(foundCache)), .success(.some(expectedCache))):
                XCTAssertEqual(foundCache.feed, expectedCache.feed, file: file, line: line)
                XCTAssertEqual(foundCache.timestamp, expectedCache.timestamp, file: file, line: line)
            case (.success(.none), .success(.none)), (.failure, .failure):
                break
            default:
                XCTFail("expected to get \(expectedResult) got \(foundResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }


    @discardableResult
    func delete(_ sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        var deletionError: Error?
        let exp = expectation(description: "wait for completion")
        sut.deleteCachedFeed { result in
            switch result {
            case let .failure(error):
                deletionError = error
            default:
                break
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }

    @discardableResult
    func insert(_ cache: (feed: [LocalFeedItem], timestamp: Date), to sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        var insertionError: Error?
        let exp = expectation(description: "wait for completion")
        sut.insertFeed(items: cache.feed, timestamp: cache.timestamp) { result in
            switch result {
            case let .failure(error):
                insertionError = error
            default:
                break
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
}
