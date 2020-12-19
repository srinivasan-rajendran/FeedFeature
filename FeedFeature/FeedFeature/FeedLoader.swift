//
//  FeedLoader.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-15.
//

import Foundation

public enum FeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

extension FeedResult: Equatable where Error: Equatable {}

protocol FeedLoader {
    associatedtype Error: Swift.Error
    func loadFeed(completion: @escaping (FeedResult<Error>) -> Void)
}
