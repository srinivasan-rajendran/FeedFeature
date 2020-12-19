//
//  FeedAPI.swift
//  FeedFeature
//
//  Created by Srinivasan Rajendran on 2020-12-16.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {

    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = FeedResult
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func loadFeed(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let data, let response):
                completion(FeedItemsMapper.map(data, response))
            case .failure:
                completion(.failure(Error.connectivity))
            }

        }
    }
}
