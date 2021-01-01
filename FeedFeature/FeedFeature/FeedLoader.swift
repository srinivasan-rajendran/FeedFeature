//
//  FeedLoader.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-15.
//

import Foundation

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedItem], Error>

    func load(completion: @escaping (Result) -> Void)
}
