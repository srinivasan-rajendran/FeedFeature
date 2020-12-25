//
//  FeedStore.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-22.
//

import Foundation

public enum RetrieveCachedFeedResult {
    case empty
    case found(feedItems: [LocalFeedItem], timestamp: Date)
    case failure(Error)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrieveCachedFeedResult) -> Void

    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insertFeed(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieveFeed(completion: @escaping RetrievalCompletion)
}
