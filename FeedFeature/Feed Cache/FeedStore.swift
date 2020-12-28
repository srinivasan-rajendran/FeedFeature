//
//  FeedStore.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-22.
//

import Foundation

public enum CachedFeed {
    case empty
    case found(feedItems: [LocalFeedItem], timestamp: Date)
}

public protocol FeedStore {

    typealias RetrievalResult = Result<CachedFeed, Error>

    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrievalResult) -> Void

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func deleteCachedFeed(completion: @escaping DeletionCompletion)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func insertFeed(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func retrieveFeed(completion: @escaping RetrievalCompletion)
}
