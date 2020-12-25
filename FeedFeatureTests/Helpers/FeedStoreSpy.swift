//
//  FeedStoreSpy.swift
//  FeedFeatureTests
//
//  Created by Srinivasan Rajendran on 2020-12-25.
//

import Foundation
import FeedFeature

class FeedStoreSpy: FeedStore {

    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (Error?) -> Void

    enum ReceivedMessages: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedItem], Date)
        case retrieve
    }

    var receivedMessages = [ReceivedMessages]()
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private var retrievalCompletions = [RetrievalCompletion]()

    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }

    func completeDeletion(with error: Error, index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeInsertion(with error: Error, index: Int = 0) {
        insertionCompletions[index](error)
    }

    func completeDeletionSuccessfully(index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func completeInsertionSuccessfully(index: Int = 0) {
        insertionCompletions[index](nil)
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
        retrievalCompletions[index](error)
    }
}
