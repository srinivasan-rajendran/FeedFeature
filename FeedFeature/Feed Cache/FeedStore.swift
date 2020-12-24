//
//  FeedStore.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-22.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insertFeed(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

public struct LocalFeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL

    public init(id: UUID,
         description: String?,
         location: String?,
         imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}
