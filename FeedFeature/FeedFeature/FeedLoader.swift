//
//  FeedLoader.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-15.
//

import Foundation

public enum FeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func loadFeed(completion: @escaping (FeedResult) -> Void)
}
