//
//  CodableFeedStoreTests.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-26.
//

import XCTest
import FeedFeature

class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {

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
        assertThatRetrieveReturnsEmptyOnEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveDeliversFoundValuesOnEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        try! "Invalid Data".write(to: storeURL, atomically: false, encoding: .utf8)
        assertThatRetrievalDeliversFailureOnRetrievalError(on: sut)
    }

    func test_retrieve_hasNoSideEffectOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        try! "Invalid Data".write(to: storeURL, atomically: false, encoding: .utf8)
        assertThatRetrievalHasNoSideEffectsOnRetrievalError(on: sut)
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        asserThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        asserThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }

    func test_insert_overridesPreviouslyInsertedCachedValues() {
        let sut = makeSUT()
        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }

    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        assertThatInsertionDeliversErrorOnInsertionError(on: sut)
    }

    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        assertThatInsertionHasNoSideEffectsOnInsertionError(on: sut)
    }

    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }

    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        assertThatDeleteDeliversErrorOnDeletionError(on: sut)
    }

    func test_delete_hasNoSideEffectOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        assertThatDeleteHasNoSideEffectOnDeletionError(on: sut)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        assertThatSideEffectsRunSerially(on: sut)
    }

    // MARK: Helpers

    private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {

        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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

