//
//  FeedStoreSpy.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-25.
//

import Foundation
import FeedFeature

class FeedStoreSpy: FeedStore {

    enum ReceivedMessages: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedItem], Date)
        case retrieve
    }

    private(set) var receivedMessages = [ReceivedMessages]()
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private var retrievalCompletions = [RetrievalCompletion]()

    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }

    func completeDeletion(with error: Error, index: Int = 0) {
        deletionCompletions[index](.failure(error))
    }

    func completeInsertion(with error: Error, index: Int = 0) {
        insertionCompletions[index](.failure(error))
    }

    func completeDeletionSuccessfully(index: Int = 0) {
        deletionCompletions[index](.success(()))
    }

    func completeInsertionSuccessfully(index: Int = 0) {
        insertionCompletions[index](.success(()))
    }

    func insertFeed(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(items, timestamp))
    }

    // MARK: Retrieve

    func retrieveFeed(completion: @escaping RetrievalCompletion) {
        retrievalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }

    func completeRetrieval(with error: Error, index: Int = 0) {
        retrievalCompletions[index](.failure(error))
    }

    func completeRetrievalWithEmptyCache(index: Int = 0) {
        retrievalCompletions[index](.success(.none))
    }

    func completeRetrieval(localItems: [LocalFeedItem], timestamp: Date, index: Int = 0) {
        retrievalCompletions[index](.success(.some(CachedFeed(feed: localItems, timestamp: timestamp))))
    }
}
