//
//  FeedLoader.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-15.
//

import Foundation

enum FeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func loadFeed(completion: @escaping (FeedResult) -> Void)
}
